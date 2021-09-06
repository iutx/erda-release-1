#!/usr/bin/env bash

echo "$(dirname "${BASH_SOURCE[0]}")"
cd "$(dirname "${BASH_SOURCE[0]}")"

export ssl_dir="$(pwd)/ssl"

. fn-ssl

rm -rf 


export ERDA_ETCD_NAME=${ERDA_ETCD_NAME:-"erda-etcd"}

export ERDA_NAMESPACE=${ERDA_NAMESPACE:-"default"}
export ERDA_SIZE=${ERDA_SIZE:-"demo"}
export KUBE_SERVICE_DNS_DOMAIN=${KUBE_SERVICE_DNS_DOMAIN:-"cluster.local"}


echo "ERDA_NAMESPACE=$ERDA_NAMESPACE"
echo "ERDA_SIZE=${ERDA_SIZE}"


if [[ "${ERDA_SIZE}" == "demo"  ]]; then
	etcd_sans=(
		${ERDA_ETCD_NAME}.${ERDA_NAMESPACE}.svc.${KUBE_SERVICE_DNS_DOMAIN}
		127.0.0.1
		localhost
	)
else
	etcd_sans=(
		${ERDA_ETCD_NAME}-0.${ERDA_NAMESPACE}.svc.${KUBE_SERVICE_DNS_DOMAIN}
		${ERDA_ETCD_NAME}-1.${ERDA_NAMESPACE}.svc.${KUBE_SERVICE_DNS_DOMAIN}
		${ERDA_ETCD_NAME}-2.${ERDA_NAMESPACE}.svc.${KUBE_SERVICE_DNS_DOMAIN}
		127.0.0.1
		localhost
	)
fi 

echo "etcd_sans=${etcd_sans[@]}"

rm -rf $ssl_dir
mkdir $ssl_dir

# generate the etcd certificate authority, peer server crt and client crt files
gen_ca etcd-ca etcd-ca
gen_server etcd-ca etcd-peer etcd-peer c "${etcd_sans[@]}"
gen_server etcd-ca etcd-server etcd-server c "${etcd_sans[@]}"
gen_client etcd-ca etcd-client etcd-client

export ETCD_CA=`cat ${ssl_dir}/etcd-ca.pem | base64 | tr -d "\n"`
export ETCD_PEER=`cat ${ssl_dir}/etcd-peer.pem | base64 | tr -d "\n"`
export ETCD_PEER_KEY=`cat ${ssl_dir}/etcd-peer-key.pem | base64 | tr -d "\n"`
export ETCD_SERVER=`cat ${ssl_dir}/etcd-server.pem | base64 | tr -d "\n"`
export ETCD_SERVER_KEY=`cat ${ssl_dir}/etcd-server-key.pem | base64 | tr -d "\n"`
export ETCD_CLIENT=`cat ${ssl_dir}/etcd-client.pem | base64 | tr -d "\n"`
export ETCD_CLIENT_KEY=`cat ${ssl_dir}/etcd-client-key.pem | base64 | tr -d "\n"`


# compose secrets and helm values files from telmpate files
envsubst < ./templates/etcd-server-secret.yaml > ./etcd-server-secret.yaml
envsubst < ./templates/etcd-client-secret.yaml > ./etcd-client-secret.yaml



