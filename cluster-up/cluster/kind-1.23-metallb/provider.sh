#!/usr/bin/env bash

set -e

DEFAULT_CLUSTER_NAME="kind-metallb"
DEFAULT_HOST_PORT=5000
ALTERNATE_HOST_PORT=5001
export CLUSTER_NAME=${CLUSTER_NAME:-$DEFAULT_CLUSTER_NAME}

if [ $CLUSTER_NAME == $DEFAULT_CLUSTER_NAME ]; then
    export HOST_PORT=$DEFAULT_HOST_PORT
else
    export HOST_PORT=$ALTERNATE_HOST_PORT
fi

export KIND_VERSION="${KIND_VERSION:-0.11.1}"
export KIND_NODE_IMAGE="${KIND_NODE_IMAGE:-quay.io/kubevirtci/kindest_node:v1.23.3@sha256:0df8215895129c0d3221cda19847d1296c4f29ec93487339149333bd9d899e5a}"
export KUBECTL_PATH="${KUBECTL_PATH:-/bin/kubectl}"

function configure_registry_proxy() {
    [ "$CI" != "true" ] && return

    echo "Configuring cluster nodes to work with CI mirror-proxy..."

    local -r ci_proxy_hostname="docker-mirror-proxy.kubevirt-prow.svc"
    local -r kind_binary_path="${KUBEVIRTCI_CONFIG_PATH}/$KUBEVIRT_PROVIDER/.kind"
    local -r configure_registry_proxy_script="${KUBEVIRTCI_PATH}/cluster/kind/configure-registry-proxy.sh"

    KIND_BIN="$kind_binary_path" PROXY_HOSTNAME="$ci_proxy_hostname" $configure_registry_proxy_script
}

function up() {
    cp $KIND_MANIFESTS_DIR/kind.yaml ${KUBEVIRTCI_CONFIG_PATH}/$KUBEVIRT_PROVIDER/kind.yaml
    _add_worker_kubeadm_config_patch
    _add_worker_extra_mounts
    kind_up

    configure_registry_proxy

    echo "$KUBEVIRT_PROVIDER cluster '$CLUSTER_NAME' is ready"
}

source ${KUBEVIRTCI_PATH}/cluster/kind/common.sh
