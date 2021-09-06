PROJ_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_REPO := registry.erda.cloud/erda
IMAGE_TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)
BUILD_IMAGE := ${IMAGE_REPO}/etcd_ssl_gen:${IMAGE_TAG}

build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o "${PROJ_PATH}/bin/etcd_ssl"

image: build-linux
	docker build .  -t ${BUILD_IMAGE}
