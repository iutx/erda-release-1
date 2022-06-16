#!/bin/bash
# Author: iutx
# Email: root@viper.run

set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC2044
for i in $(find . -mindepth 2 -name "entrypoint.sh"); do
  echo "find entrypoint.sh: $i"
  echo "execute entrypoint.sh: $i"
  chmod +x "$i" && bash "$i"
done

echo "cergen end"