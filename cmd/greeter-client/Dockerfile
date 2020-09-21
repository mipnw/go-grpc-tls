FROM go-tls-dev as build
WORKDIR /go/src/github.com/mipnw/go-tls

# Copy source code
COPY go.mod .
COPY go.sum .
COPY api/proto/v1 api/proto/v1
COPY cmd/greeter-client cmd/greeter-client
COPY vendor vendor

# Compile protobuf
RUN protoc \
    --proto_path=api/proto/v1 \
    --go_out=plugins=grpc:./ \
    service.proto

# Compile image
RUN go build \
    -mod=vendor \
    -o /usr/local/bin/greeter-client \
    cmd/greeter-client/main.go

FROM alpine as deploy

# Install openssl
RUN apk update && \
    apk add --no-cache \
    openssl \
    bash

# Copy image
COPY --from=build /usr/local/bin/greeter-client /usr/local/bin/greeter-client

# Copy secrets:
# - For server-authenticated TLS, we only need the root CA to validate the server certificate
# - For mTLS, we need both the root CA and the client certificate
COPY secrets/root/public /secrets/root/public
COPY secrets/client /secrets/client

ENTRYPOINT [ "bash" ]
