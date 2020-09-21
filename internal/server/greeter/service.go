package greeter

import (
	"context"
	"fmt"
	"log"

	pb "github.com/mipnw/go-tls/internal/api/proto/v1"
)

type Service struct {
}

func (s *Service) SayHello(
	ctx context.Context,
	request *pb.HelloRequest,
) (*pb.HelloReply, error) {
	log.Printf("Greeter.SayHello")
	return &pb.HelloReply{Message: fmt.Sprintf("Hello %v", request.Name)}, nil
}
