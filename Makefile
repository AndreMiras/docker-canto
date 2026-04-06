REGISTRY_USERNAME=andremiras
REGISTRY_HOSTNAME=docker.io
IMAGE_NAME=canto
DOCKER_IMAGE=$(REGISTRY_HOSTNAME)/$(REGISTRY_USERNAME)/$(IMAGE_NAME)
VERSION=8.1.3
VERSIONS=1.0.0 2.0.0 3.0.0 4.0.0 5.0.0 5.0.2 6.0.0 7.0.0 7.0.1 7.1.0 8.0.0 8.1.0 8.1.1 8.1.3
IMAGE_TAG=$(VERSION)

# Determine the Go version based on the Canto version
define get_go_version
major_version=$$(echo $1 | cut -d'.' -f1); \
if [ "$$major_version" -ge 8 ]; then \
    echo "1.23"; \
else \
    echo "1.20"; \
fi
endef

docker/pull:
	docker pull $(DOCKER_IMAGE):$(IMAGE_TAG)

docker/build/version/%:
	$(eval GO_VERSION := $(shell $(call get_go_version,$*)))
	docker build --tag=$(DOCKER_IMAGE):$* --build-arg VERSION=$* --build-arg GO_VERSION=$(GO_VERSION) $(if $(BRANCH),--build-arg BRANCH=$(BRANCH)) .

docker/build/versions:
	for version in $(VERSIONS) ; do \
	    make docker/build/version/$$version ; \
	done

docker/build: docker/build/versions

docker/buildx/version/%:
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(DOCKER_IMAGE):$* \
		--build-arg VERSION=$* \
		--build-arg GO_VERSION=$(shell $(call get_go_version,$*)) \
		$(if $(BRANCH),--build-arg BRANCH=$(BRANCH)) \
		--push .

docker/buildx/versions:
	for version in $(VERSIONS) ; do \
	    make docker/buildx/version/$$version ; \
	done

docker/buildx: docker/buildx/versions

docker/login:
	docker login --username $(REGISTRY_USERNAME)

docker/push/version/%:
	docker push $(DOCKER_IMAGE):$*

docker/push/versions:
	for version in $(VERSIONS) ; do \
	    make docker/push/version/$$version ; \
	done

docker/push: docker/push/versions

docker/run:
	docker run -it --rm $(DOCKER_IMAGE):$(IMAGE_TAG)

docker/run/sh:
	docker run -it --entrypoint /bin/sh --rm $(DOCKER_IMAGE):$(IMAGE_TAG)

lint/node:
	npx prettier --check .github *.md

lint: lint/node

format/node:
	npx prettier --write .github *.md

format: format/node
