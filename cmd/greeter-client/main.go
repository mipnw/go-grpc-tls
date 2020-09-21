package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strconv"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"

	pb "github.com/mipnw/go-tls/api/proto/v1"
)

func main() {
	// Parse the command line
	address := flag.String("url", "localhost:8080", "URI for the greeter service")
	flag.Parse()

	// Configure the dial options (plaintext v TLS), block the dial until connection is
	// successful or 3 sec timeout
	dialOptions := []grpc.DialOption{
		grpc.WithBlock(),
		grpc.WithTimeout(6 * time.Second),
	}

	// Load secrets for TLS
	useMutualAuthentication, _ := strconv.ParseBool(os.Getenv("USE_MTLS"))
	tlsCredentials, err := LoadTLSCredentials(useMutualAuthentication)
	if err != nil {
		log.Fatalf("Failed to load TLS credentials: %v", err)
	}

	dialOptions = append(dialOptions, grpc.WithTransportCredentials(tlsCredentials))

	// Dial the gRPC server
	log.Printf("Dialing %v", *address)
	conn, err := grpc.Dial(*address, dialOptions...)
	if err != nil {
		log.Fatalf("Failed to connect to greeter service: %v", err)
	}
	defer conn.Close()

	log.Print("Succeeded in connecting to greeter service")

	// Send a gRPC request
	client := pb.NewGreeterClient(conn)
	response, err := client.SayHello(
		context.Background(),
		&pb.HelloRequest{Name: "Go client"})
	if err != nil {
		log.Fatalf("Greeter errored with: %v", err)
	}
	log.Printf("Greeter responded with: %v", response.Message)
}

func LoadTLSCredentials(useMutualAuthentication bool) (credentials.TransportCredentials, error) {
	rootCA, err := ioutil.ReadFile("/secrets/root/public/ca.cert")
	if err != nil {
		return nil, err
	}

	certPool := x509.NewCertPool()
	if !certPool.AppendCertsFromPEM(rootCA) {
		return nil, fmt.Errorf("Failed to add rootCA to x509 certificate pool")
	}

	config := &tls.Config{
		// Minimum TLS version 1.2
		MinVersion: tls.VersionTLS12,

		// a RootCA to validate the server certificate
		RootCAs: certPool,
	}

	if useMutualAuthentication {
		// Load the client certificate
		clientCert, err := tls.LoadX509KeyPair(
			"/secrets/client/public/service.pem",
			"/secrets/client/private/service.key")
		if err != nil {
			log.Print("Unable to open X509 certificates. Check /secrets/client exists and contains the right files")
			return nil, err
		}

		config.Certificates = []tls.Certificate{clientCert}
		log.Print("Using mTLS")
	} else {
		log.Print("Using server-authenticated TLS")
	}

	return credentials.NewTLS(config), nil
}
