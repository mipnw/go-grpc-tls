FROM go-tls-dev as build
WORKDIR /go/src/github.com/mipnw/go-tls

# Copy source code
COPY go.mod .
COPY go.sum .
COPY api/proto/v1 api/proto/v1
COPY cmd/greeter-server cmd/greeter-server
COPY internal/server internal/server
COPY vendor vendor

# Compile protobuf
RUN protoc \
    --proto_path=api/proto/v1 \
    --go_out=plugins=grpc:internal/ \
    service.proto

# Compile image
RUN go build \
    -mod=vendor \
    -o /usr/local/bin/greeter-server \
    cmd/greeter-server/main.go

FROM alpine as deploy

# Install CA certificates, openssl
RUN apk update && \
    apk add --no-cache \
    ca-certificates \
    tzdata \
    openssl \
    && \
    update-ca-certificates

# Copy image
COPY --from=build /usr/local/bin/greeter-server /usr/local/bin/greeter-server

# Copy secrets:
# - For server-authenticated TLS, we only need the server server certificate
# - For mTLS, we need both the root CA and the server certificate
COPY secrets/root/public /secrets/root/public
COPY secrets/server /secrets/server

EXPOSE 8080
ENTRYPOINT [ "/usr/local/bin/greeter-server" ]
