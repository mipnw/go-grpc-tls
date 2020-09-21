FROM golang:1.15-alpine

# Install protoc
RUN apk update && apk add git protoc bash

# Install protoc-gen-go
ENV GO111MODULE=on
RUN go get github.com/golang/protobuf/protoc-gen-go
