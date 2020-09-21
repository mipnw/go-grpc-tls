package grpc

import (
	"crypto/tls"
	"crypto/x509"
	"errors"
	"io/ioutil"
	"log"

	"google.golang.org/grpc/credentials"
)

// This configures server-authenticated TLS version 1.2 or later, or mutually authenticated TLS if
// the parameter is true.
func LoadTLSCredentials(useMutualAuthentication bool) (credentials.TransportCredentials, error) {
	// Load the server certificate
	serverCert, err := tls.LoadX509KeyPair(
		"/secrets/server/public/service.pem",
		"/secrets/server/private/service.key")
	if err != nil {
		log.Print("Unable to open X509 certificates. Check /secrets/server exists and contains the right files")
		return nil, err
	}

	tlsConfig := &tls.Config{
		// Minimum TLS version 1.2
		MinVersion: tls.VersionTLS12,

		// Server authentication
		Certificates: []tls.Certificate{serverCert},
	}

	// mTLS for the server means:
	// - require clients send certificates
	// - validate certificates with a root CA
	if useMutualAuthentication {
		rootCACertificate, err := ioutil.ReadFile("/secrets/root/public/ca.cert")
		if err != nil {
			return nil, err
		}

		certificatePool := x509.NewCertPool()
		if !certificatePool.AppendCertsFromPEM(rootCACertificate) {
			return nil, errors.New("Failed to append root CA certificate. Check the file is a valid x509 certificate")
		}

		tlsConfig.ClientCAs = certificatePool
		tlsConfig.ClientAuth = tls.RequireAndVerifyClientCert
		log.Print("Using mTLS")
	} else {
		log.Print("Using server-authenticated TLS")
	}

	return credentials.NewTLS(tlsConfig), nil
}
