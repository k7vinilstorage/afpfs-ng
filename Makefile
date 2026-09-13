IMAGE_DEB = afpfs-ng-deb
IMAGE_RPM = afpfs-ng-rpm
DOCKER_DIR = $(PWD)/docker
PATCHES_DIR= $(PWD)/patches
DIST = $(PWD)/dist

.PHONY: all package deb rpm build-image build-image-deb build-image-rpm clean

all: deb

# Kept for backwards compatibility (previously the only format).
package: deb
build-image: build-image-deb

build-image-deb:
	docker build -f $(DOCKER_DIR)/Dockerfile -t $(IMAGE_DEB) $(DOCKER_DIR)

build-image-rpm:
	docker build -f $(DOCKER_DIR)/Dockerfile.fedora -t $(IMAGE_RPM) $(DOCKER_DIR)

deb: build-image-deb
	mkdir -p $(DIST)
	docker run \
		-e PKG_REVISION=$(PKG_REVISION) \
		-v $(DIST):/app/dist \
		-v $(PATCHES_DIR):/app/patches \
		$(IMAGE_DEB)

rpm: build-image-rpm
	mkdir -p $(DIST)
	docker run \
		-e PKG_REVISION=$(PKG_REVISION) \
		-v $(DIST):/app/dist \
		-v $(PATCHES_DIR):/app/patches \
		$(IMAGE_RPM)

clean:
	sudo rm -rf $(DIST)/*
