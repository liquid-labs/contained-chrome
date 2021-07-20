IMAGE_NAME:=theliquidlabs/contained-chrome
NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/bash-rollup

SRC_FILES:=$(shell find src/docker/ -type f)

BASH_BINS:=dist/contained-chrome.sh
DIST_FILES:=$(BASH_BINS)

all: docker-build $(DIST_FILES)

.PHONY: all docker-build

.DELETE_ON_ERROR:

$(BASH_BINS): dist/%: src/cli/%
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

.ver-cache: package.json
	cat $< | jq -r .version > $@

.docker-distro-img-marker: $(SRC_FILES) .ver-cache
	@# TODO: Do a version marker with the image pull so we can tell whether we need to go through a whole rebuild or not.
	docker pull ubuntu:latest
	@# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker image build src/docker --file src/docker/Dockerfile -t $(IMAGE_NAME):dev
	touch $@

docker-build: .docker-distro-img-marker

docker-run: .docker-distro-img-marker
	src/cli/contained-chrome.sh $(IMAGE_NAME)

docker-publish:
	@cat "$${HOME}/.docker/config.json" | jq '.auths["https://index.docker.io/v1/"]' | grep -q '{}' || { echo -e "It does not appear that you're logged into docker.io. Try:\ndocker login --username=<your user name>"; exit 1; }
	@echo "Login confirmed..."
	./src/tools/docker-publish.sh
