package main

import (
	"os"
	"strconv"
	"sync"

	gotlsgrpc "github.com/mipnw/go-tls/internal/server/grpc"
)

const (
	GREETER_GPRC_ENDPOINT_PORT = 8080
)

func main() {
	StartAllServers()
}

func StartAllServers() {
	// We are going to wait on parallel threads where the servers run
	// (there could be more than one endpoint, one server per endpoint)
	wg := new(sync.WaitGroup)

	// Start thread serving the service endpoint
	useMutualAuthentication, _ := strconv.ParseBool(os.Getenv("USE_MTLS"))
	greeterServer := gotlsgrpc.NewServer(GREETER_GPRC_ENDPOINT_PORT, useMutualAuthentication, "Greeter Service")
	wg.Add(1)
	go greeterServer.Start(wg)

	// Wait until all threads are done
	wg.Wait()
}
