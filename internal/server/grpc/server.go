package grpc

import (
	"fmt"
	"log"
	"net"
	"sync"

	pb "github.com/mipnw/go-tls/internal/api/proto/v1"
	"github.com/mipnw/go-tls/internal/server/greeter"
	"google.golang.org/grpc"
)

type Server struct {
	Listener   net.Listener
	GrpcServer *grpc.Server
	Name       string
}

func (s *Server) Start(wg *sync.WaitGroup) {
	if err := s.GrpcServer.Serve(s.Listener); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
	wg.Done()
}

func NewServer(
	port uint,
	useMutualAuthentication bool,
	servername string,
) Server {
	address := fmt.Sprintf(":%v", port)
	lis, err := net.Listen("tcp", address)
	if err != nil {
		log.Fatalf("Failed to listen for TCP on %v: %v", address, err)
	}
	log.Printf("Listening for TCP on %v", address)

	tlsCredentials, err := LoadTLSCredentials(useMutualAuthentication)
	if err != nil {
		log.Fatal("cannot load TLS credentials: ", err)
	}
	grpcServer := grpc.NewServer(grpc.Creds(tlsCredentials))

	pb.RegisterGreeterServer(grpcServer, &greeter.Service{})

	server := Server{
		Listener:   lis,
		GrpcServer: grpcServer,
		Name:       servername,
	}
	return server
}
