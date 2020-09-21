SHELL:=/bin/bash
.DEFAULT_GOAL := help

ifdef USE_MTLS
EXTRA_ARGS:=--mTLS
endif

.PHONY: docker-build
docker-build: ## build the docker image
	docker build \
		-t greeter-client-py \
		-f Dockerfile \
		../..

.PHONY: shell
docker-shell: ## shell into the docker image
	docker run \
		--rm \
		-it \
		--hostname greeter-client \
		--name greeter-client-py \
		greeter-client-py \
		sh

.PHONY: docker-run
docker-run: ## runs the grpc client in docker
	docker run \
		--rm \
		-it \
		--network go-tls_greeter-network \
		--hostname greeter-client \
		--name greeter-client-py \
		greeter-client-py \
		./main.py --url greeter:8080 --secretsPath /secrets $(EXTRA_ARGS)

.PHONY: clean
clean: ## remove the virual environment
	-docker image rm --force greeter-client-py

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
