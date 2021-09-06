FROM alpine:3.13
WORKDIR /opt/etcd_ssl

COPY ./scripts .
COPY ./templates ./templates
COPY ./bin/etcd_ssl .

RUN apk --no-cache add openssl bash gettext \
  && chmod +x /opt/etcd_ssl/generate_ssl.sh

ENTRYPOINT /opt/etcd_ssl/etcd_ssl
