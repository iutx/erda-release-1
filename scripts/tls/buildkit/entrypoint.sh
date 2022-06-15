#!/bin/bash
# Author: iutx
# Email: root@viper.run

set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# prepare required variables
# shellcheck disable=SC2155
export ssl_dir="$(pwd)/ssl"
# shellcheck disable=SC2155
export log_file="$(pwd)/log.log"
. fn-ssl

export ERDA_NAMESPACE=${ERDA_NAMESPACE:-"default"}
export KUBE_SERVICE_DNS_DOMAIN=${KUBE_SERVICE_DNS_DOMAIN:-"cluster.local"}
export RENEW_BUILDKIT_CERTS=${RENEW_CERTS:-"false"}

sans=(
		buildkitd."${ERDA_NAMESPACE}".svc."${KUBE_SERVICE_DNS_DOMAIN}"
		buildkitd."${ERDA_NAMESPACE}".svc
		127.0.0.1
		localhost
)

gen_ca buildkit-ca buildkit-ca
gen_server buildkit-ca buildkit-daemon buildkit-daemon c "${sans[@]}"
gen_client buildkit-ca buildkit-client buildkit-client

export BUILDKIT_CA=`cat ${ssl_dir}/buildkit-ca.pem | base64 | tr -d "\n"`
export BUILDKIT_DAEMON=`cat ${ssl_dir}/buildkit-daemon.pem | base64 | tr -d "\n"`
export BUILDKIT_DAEMON_KEY=`cat ${ssl_dir}/buildkit-daemon-key.pem | base64 | tr -d "\n"`
export BUILDKIT_CLIENT=`cat ${ssl_dir}/buildkit-client.pem | base64 | tr -d "\n"`
export BUILDKIT_CLIENT_KEY=`cat ${ssl_dir}/buildkit-client-key.pem | base64 | tr -d "\n"`


mkdir ./dist

# compose secrets and helm values files from template files
envsubst < ./templates/buildkit-client-secret.yaml > ./dist/buildkit-client-secret.yaml
envsubst < ./templates/buildkit-daemon-secret.yaml > ./dist/buildkit-daemon-secret.yaml

# renew buildkit certs
renew_buildkit_certs() {
  secret_name=$1
  if kubectl get secret "${secret_name}" -n "${ERDA_NAMESPACE}" > /dev/null 2>&1; then
    echo "secret ${secret_name} already exists"
    if [ "${RENEW_BUILDKIT_CERTS}" == "true" ]; then
      echo "renewing buildkit certs"
      apply_new_certs
    fi
  else
    echo "secret ${secret_name} not found"
    apply_new_certs
  fi
}

# apply new certs
apply_new_certs() {
  echo "apply new erda buildkit certs"
  kubectl apply -f ./dist
  exit 0
}

renew_buildkit_certs "buildkit-daemon-certs"
renew_buildkit_certs "buildkit-client-certs"
