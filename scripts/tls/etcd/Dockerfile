ARG BUILD_BASE_IMAGE=alpine

FROM ${BUILD_BASE_IMAGE} as builder
MAINTAINER iutx "root@viper.run"
ARG ARCH=amd64
ARG KUBERNETS_VERSION=v1.24.1

WORKDIR /work

COPY ../common .
COPY ./etcd .

RUN wget https://dl.k8s.io/release/${KUBERNETS_VERSION}/bin/linux/${ARCH}/kubectl -O /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    apk add --no-cache gettext openssl bash && \
    chmod +x *.sh

ENTRYPOINT ["./entrypoint.sh"]