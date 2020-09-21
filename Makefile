SHELL:=/bin/bash
ROOT:=$(shell git rev-parse --show-toplevel)
.DEFAULT_GOAL := help

# Run inside docker as the same user on the host.
DOCKER_ARGS_FOR_SAME_USER := --env LOCAL_USER_ID=$(shell id -u) --env LOCAL_GROUP_ID=$(shell id -g)

ifdef DOCKER_USER_PATH
DOCKER_ARGS_FOR_BASHRC := --volume $(DOCKER_USER_PATH):/mnt/appuser:ro --hostname godevbox
endif

.PHONY:certs
certs: ## generalte self-signed root CA certificate and CA signed server certificate
	@./scripts/gen_selfsigned.sh

.PHONY: view-root-cert
view-root-cert: ## view the root CA certificate
	openssl x509 -in secrets/root/public/ca.cert -text -noout

.PHONY: view-server-cert
view-server-cert: ## view the server certificate
	openssl x509 -in secrets/server/public/service.pem -text -noout

.PHONY: view-client-cert
view-client-cert: ## view the client certificate
	openssl x509 -in secrets/client/public/service.pem -text -noout


.PHONY: verify-certs
verify-certs: ## verify the server and client certificates are valid
	@openssl verify -CAfile secrets/root/public/ca.cert secrets/server/public/service.pem
	@[[ -e secrets/client/public/service.pem ]] && openssl verify -CAfile secrets/root/public/ca.cert secrets/client/public/service.pem

.PHONY: dev
dev: ## build the build environment, aka the dev environment
	docker build \
		-t go-tls-dev \
		.

.PHONY: shell-dev
shell-dev: ## shell into the dev environment, mounting source code from host
	docker run \
		--rm \
		-it \
		-v $(ROOT):/go/src/github.com/mipnw/go-tls \
		--workdir /go/src/github.com/mipnw/go-tls \
		$(DOCKER_ARGS_FOR_SAME_USER) \
		$(DOCKER_ARGS_FOR_BASHRC) \
		go-tls-dev \
		/bin/bash

.PHONY: shell-client
shell-client: ## shell into the client container
	docker exec -it greeter-client bash

.PHONY: shell-client
shell-server: ## shell into the server container
	docker exec -it greeter sh

# We change the default GOMODCACHE because not running as root, we have no permission to 
# /go/mod/pkg/cache, and go mod vendor fails to download modules. We can throw away the cache
# so we use tmpfs. All that we care about is getting the vendor/ folder on the host.
#
.PHONY: vendor
vendor: ## regenerate the vendor folder, follow up with `chown -R $(id -nu):$(id -ng) .`
	docker run \
		--rm \
		-it \
		$(DOCKER_ARGS_FOR_SAME_USER) \
		-v $(ROOT):/go/src/github.com/mipnw/go-tls \
		--workdir /go/src/github.com/mipnw/go-tls \
		--tmpfs /gomodcache \
		--env GOMODCACHE=/gomodcache \
		go-tls-dev \
		go mod vendor

.PHONY: install
install: certs vendor ## installs everything needed to `make build`

.PHONY: build-server
build-server: ## build the server docker image
	docker-compose build greeter-server

.PHONY: build-client
build-client: ## build the client docker image
	docker-compose build greeter-client

build: build-server build-client ## build both, the client and the server docker images

.PHONY: run-server
run-server: ## run the server in a docker container
	docker-compose up

.PHONY: openssl-connect
openssl-connect: ## test the server with `openssl s_client` from the docker host
	openssl s_client \
		-CAfile secrets/root/public/ca.cert \
		-cert secrets/client/public/service.pem \
		-key secrets/client/private/service.key \
		-msg \
		-tls1_2 \
	 	-verify_return_error \
		-connect localhost:8080

.PHONY: openssl-connect-from-client
openssl-connect-from-client: ## test the server with `openssl s_client` from the greeter-client
	docker run -it --network greeter --entrypoint sh greeter-client -c \
		"openssl s_client \
		-CAfile secrets/root/public/ca.cert \
		-cert secrets/client/public/service.pem \
		-key secrets/client/private/service.key \
		-msg \
		-tls1_2 \
	 	-verify_return_error \
		-connect greeter:8080"

.PHONY: testssl
testssl: ## test the server with drewetter/testssl.sh
	docker run --network greeter drwetter/testssl.sh:3.0 greeter:8080

.PHONY: client-call
client-call: ## connect our gRPC client running in a docker container attached to the same network as the the greeter server container
	docker run -it --network greeter --entrypoint sh -e USE_MTLS=$(USE_MTLS) greeter-client -c \
		"getent hosts greeter && greeter-client -url greeter:8080"

.PHONY: clean
clean: ## clean all build/run artifacts
	-docker-compose down --remove-orphans
	-docker image rm go-tls-dev
	-docker image rm greeter-client
	-docker image rm greeter-server
	-docker image rm drwetter/testssl.sh:3.0
	-rm -rf secrets
	-rm -rf vendor

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
