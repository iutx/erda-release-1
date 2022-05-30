PROJ_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_REPO := registry.erda.cloud/erda
IMAGE_TAG := $(shell date '+%Y%m%d%H%M%S')-$(shell git rev-parse --short HEAD)
BUILD_IMAGE := ${IMAGE_REPO}/etcd_ssl_gen:${IMAGE_TAG}
KUBERNETES_RELEASE := v1.24.1

build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o "${PROJ_PATH}/bin/etcd_ssl"

build-image:
	docker build . -t ${BUILD_IMAGE}

build-push-image: build-image
	docker push ${BUILD_IMAGE}