# The purpose of this image is to define a golang environment where
# users can run `make vendor` while installing this project.
#
# That requires building protobufs.
#
# Files created on volumes mounted from the host can easily be removed by `make clean` because
# they are owned by the user, not by root. Hence the use of mipnw/golang:1.15-alpine3.12 instead
# of golang:1.15-alpine3.12

FROM mipnw/golang:1.15-alpine3.12

# Install protoc
RUN apk update && apk add git protoc bash

# Install protoc-gen-go
ENV GO111MODULE=on
RUN go get github.com/golang/protobuf/protoc-gen-go
