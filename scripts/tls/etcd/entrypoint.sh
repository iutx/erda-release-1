#!/bin/bash
# Author: iutx
# Email: root@viper.run

set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

export ERDA_NAMESPACE=${ERDA_NAMESPACE:-"default"}
export RENEW_ETCD_CERTS=${RENEW_CERTS:-"false"}
export ERDA_IS_WORKER=${ERDA_IS_WORKER:-"false"}

echo "erda namespace: ${ERDA_NAMESPACE}"
echo "renew etcd certs: ${RENEW_ETCD_CERTS}"
echo "erda is worker: ${ERDA_IS_WORKER}"

# renew etcd certs
renew_etcd_certs() {
  secret_name=$1
  if kubectl get secret "$secret_name" -n "$ERDA_NAMESPACE" > /dev/null 2>&1; then
    echo "secret $secret_name already exists"
    if [ "$RENEW_ETCD_CERTS" == "true" ]; then
      echo "renewing etcd certs"
      apply_new_certs
    fi
  else
    echo "secret $secret_name not found"
    apply_new_certs
  fi
}

# apply new certs
apply_new_certs() {
  echo "generate new erda etcd certs"
  ./generate_ssl.sh

  echo "apply new erda etcd certs"
  kubectl apply -f ./secrets
  exit 0
}

if [ "$ERDA_IS_WORKER" == "true" ]; then
  echo "erda worker node, etcd certgen skip"
  exit 0
fi

renew_etcd_certs "erda-etcd-server-secret"
renew_etcd_certs "erda-etcd-client-secret"
