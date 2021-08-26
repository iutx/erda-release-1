#!/bin/bash
set -eo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf package
mkdir package

if [[ -z $ERDA_VERSION ]]; then
    echo "ERDA_VERSION is empty"
    exit
fi

echo "${ERDA_VERSION}" > erda-helm/VERSION

# ERDA_OS_SYSTEM: Currently only supports linux.
if [[ -z $ERDA_OS_SYSTEM ]]; then
    echo "ERDA_OS_SYSTEM is empty"
    exit
fi

# install third_party_packages
rm -fr erda-helm/third_party_package
mkdir -p erda-helm/third_party_package

if [[ $ERDA_OS_SYSTEM == "linux" ]]; then
    wget https://github.com/reconquest/orgalorg/releases/download/1.0.1/orgalorg_1.0.1_linux_amd64.tar.gz -O erda-helm/third_party_package/orgalorg_1.0.1_linux_amd64.tar.gz
    mkdir -p erda-release
    mv erda-helm erda-release/
    tar -cvzf package/erda-${ERDA_OS_SYSTEM}.tar.gz erda-release/
fi
