PROJ_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
IMAGE_REPO := registry.erda.cloud/erda
IMAGE_TAG := $(shell date '+%Y%m%d%H%M%S')-$(shell git rev-parse --short HEAD)
COMPONENT := buildkit
DIST_NAME := ${COMPONENT}_certgen
BUILD_IMAGE := ${IMAGE_REPO}/${DIST_NAME}:${IMAGE_TAG}
BUILD_ALL_IN_ONE := ${IMAGE_REPO}/certgen:${IMAGE_TAG}
KUBERNETES_RELEASE := v1.24.1

build-image:
	docker build . -f ${COMPONENT}/Dockerfile -t ${BUILD_IMAGE}

build-push-image: build-image
	docker push ${BUILD_IMAGE}

build-all-in-one-image:
	docker build . -f all-in-one/Dockerfile -t ${BUILD_ALL_IN_ONE}

build-push-all-in-one-image:
	docker push ${BUILD_ALL_IN_ONE}