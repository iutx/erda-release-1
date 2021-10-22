#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

function flag_value() {
    echo "$1" | sed -e 's/^[^=]*=//g'
}

function show_help {
    echo ""
    echo "Example: ./upgrade.sh --cluster_access_key=demo_access_key"
    echo ""
    echo "     --cluster_access_key          cluster name"
    echo "     --release_name                erda release name"
    echo ""
}

namespace=""
dice_cluster_info=""
cluster_name=""
cluster_access_key=""
release_name=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        --cluster_access_key*)
            export cluster_access_key=$(flag_value "$1")
            shift
            ;;
        --release_name*)
            export release_name=$(flag_value "$1")
            shift
            ;;
    esac
done

function run() {
  if [ "$(kubectl get erda --all-namespaces --no-headers | wc -l)" -ne "1" ];then
    echo "Get empty or multi erda custom resources in cluster, please check it."
    exit 1
  fi

  namespace=$(kubectl get erda --all-namespaces --no-headers | awk '{print $1}')
  dice_cluster_info=`kubectl get cm dice-cluster-info -n $namespace -o json`

  check_version

  if echo $dice_cluster_info | jq .data.DICE_IS_EDGE|grep -i true 2>/dev/null 1>/dev/null; then
    do_upgrade_worker
  else
    echo  echo "script shoud run on worker cluster"
  fi
}

function check_version() {
  current_version=$(echo $dice_cluster_info | jq -r .data.DICE_VERSION)
  tagert_version="1.4.0"
  if [ "$(echo "$current_version $tagert_version" | tr " " "\n" | sort -rV | head -n 1)" == "$current_version" ];then
    echo "current erda version is equal or grater than $tagert_version, not suitable for this script."
    exit 1
  fi
}


function do_upgrade_worker() {

  if [ -z $cluster_access_key ];then
    echo "Please provide access key for worker cluster from erda cmp platform, use '--cluster_access_key=' specified it."
    exit 1
  fi

  cluster_name=$(echo $dice_cluster_info | jq -r .data.DICE_CLUSTER_NAME)
  root_domain=$(echo $dice_cluster_info | jq -r .data.DICE_ROOT_DOMAIN)
  cluster_type=$(echo $dice_cluster_info | jq -r .data.DICE_CLUSTER_TYPE)
  master_dialer=$(kubectl get erda erda -n $namespace -o yaml | grep -i "cluster-dialer: http" | awk '{print $2}')
  master_cluster_domain=$(echo $master_dialer | awk -F '://' '{print $2}' | awk -F "cluster-dialer." {'print $2'})
  master_cluster_portal=$(echo $master_dialer | awk -F '://' '{print $1}')
  erda_local_repo=$(helm repo list  | grep "charts.erda.cloud/erda" | awk '{print $1}')

  if [ -z $release_name ];then
     release_count=$(helm list -n $namespace | grep erda | wc -l)
     if [ "$release_count" -ne "1" ];then
       echo "Get empty or multi release name contains erda, please use --release_name specifed it."
       exit 1
     else
       release_name=$(helm list -n $namespace | grep erda | awk '{print $1}')
     fi
  fi

  command_create_secret=$(echo kubectl create secret generic erda-cluster-credential --from-literal=CLUSTER_ACCESS_KEY=$cluster_access_key -n $namespace)
  command_upgrade=$(echo helm upgrade $release_name $erda_local_repo/erda -n $namespace --set tags.worker=true,tags.master=false,global.domain=$root_domain,erda.clusterName=$cluster_name,erda.clusterConfig.clusterType=$cluster_type,erda.masterCluster.domain=$master_cluster_domain,erda.masterCluster.protocol=$master_cluster_portal --version=1.4.0)

  echo "Metadata:"
  echo "  namespace: $namespace"
  echo "  cluster_name: $cluster_name"
  echo "  root_domain: $root_domain"
  echo "  cluster_type: $cluster_type"
  echo "  master_cluster_domain: $master_cluster_domain"
  echo "  master_cluster_portal: $master_cluster_portal"
  echo "  erda_local_repo: $erda_local_repo"
  echo "  cluster_access_key: $cluster_access_key"
  echo "  release_name: $release_name"
  echo ""
  echo "Will execute command:"
  echo "  1. $command_create_secret"
  echo "  2. $command_upgrade"

  while true
  do
    read -r -p "Are you sure upgrade? [Y/n]" input

    case $input in
    [yY])
      break
      ;;
    [nN])
      echo "Exit"
      exit 1
      ;;
    *)
      echo "Invalid input value"
      ;;
    esac
  done

  echo "Create or patch secret erda-cluster-credential in namespace: $namespace"
  if [ "$(kubectl get secret -n $namespace erda-cluster-credential --no-headers | wc -l)" -eq "0" ];then
    $command_create_secret
  else
    sh -c "kubectl patch secret -n $namespace erda-cluster-credential --type='json' -p='[{"op" : "replace" ,"path" : "/data/CLUSTER_ACCESS_KEY" ,"value" : $(base64 <<< $cluster_access_key)}]'"
  fi

  echo "Upgrade erda, release: $release_name, namespace: $namespace"
  helm repo update
  $command_upgrade
}

run