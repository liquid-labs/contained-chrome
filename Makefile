all: docker-build

.PHONY: all docker-build

SRC_FILES:=$(shell find src/docker/ -type f)
CONTAINER_NAME:=theliquidlabs/contained-chrome

.ver-cache: package.json
	cat $< | jq -r .version > $@

.docker-distro-img-marker: $(SRC_FILES) .ver-cache
	@# TODO: Do a version marker with the image pull so we can tell whether we need to go through a whole rebuild or not.
	docker pull ubuntu:latest
	@# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker build src/docker --file src/docker/Dockerfile -t $(CONTAINER_NAME)
	touch $@

docker-build: .docker-distro-img-marker

docker-run: .docker-distro-img-marker
	src/cli/contained-chrome.sh $(CONTAINER_NAME)

docker-publish:
	@cat "$${HOME}/.docker/config.json" | jq '.auths["https://index.docker.io/v1/"]' | grep -q '{}' || { echo -e "It does not appear that you're logged into docker.io. Try:\ndocker login --username=<your user name>"; exit 1; }
	@echo "Login confirmed..."
	./src/tools/docker-publish.sh
