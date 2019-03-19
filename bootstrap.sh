#!/bin/sh

set -o nounset  # Treat unset variables as an error
set -e          # Exit on error

# Note: Latest version of helm may be found at:
# https://github.com/kubernetes/helm/releases
HELM_VERSION=${HELM_VERSION:-v2.13.0}
KUBE_VERSION=${KUBE_VERSION:-v1.13.4}
INSTALL_PREFIX=${INSTALL_PREFIX:-/usr/local}
TEMP_DIR=$(mktemp -d)

__exit_cleanup() {
    EXIT_CODE=$?
    rm -rf "${TEMP_DIR}"
}
trap "__exit_cleanup" EXIT INT


#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __detect_color_support
#   DESCRIPTION:  Try to detect color support.
#----------------------------------------------------------------------------------------------------------------------
_COLORS=${BS_COLORS:-$(tput colors 2>/dev/null || echo 0)}
__detect_color_support() {
    # shellcheck disable=SC2181
    if [ $? -eq 0 ] && [ "$_COLORS" -gt 2 ]; then
        RC='\033[1;31m'
        GC='\033[1;32m'
        BC='\033[1;34m'
        YC='\033[1;33m'
        EC='\033[0m'
    else
        RC=""
        GC=""
        BC=""
        YC=""
        EC=""
    fi
}
__detect_color_support

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __install_kubectl
#   DESCRIPTION:  Check if a command exists.
#----------------------------------------------------------------------------------------------------------------------
__install_kubectl() {
    VERSION="${1}"
    BASE_URL="https://storage.googleapis.com/kubernetes-release"
    BIN_FILE="${VERSION}/bin/linux/amd64/kubectl"
    curl -sL ${BASE_URL}/${BIN_FILE} -o kubectl && \
    mv kubectl ${INSTALL_PREFIX}/bin/kubectl
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __check_command_exists
#   DESCRIPTION:  Check if a command exists.
#----------------------------------------------------------------------------------------------------------------------
# Install helm
__install_helm() {
    VERSION="${1}"
    BASE_URL="https://storage.googleapis.com/kubernetes-helm"
    TAR_FILE="helm-${VERSION}-linux-amd64.tar.gz"
    curl -sL ${BASE_URL}/${TAR_FILE} | tar xz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    mv linux-amd64/tiller /usr/bin/tiller && \
    chmod +x /usr/bin/tiller
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __check_command_exists
#   DESCRIPTION:  Check if a command exists.
#----------------------------------------------------------------------------------------------------------------------
__check_command_exists() {
    command -v "$1" > /dev/null 2>&1
}

error() {
    printf "${RC} * ERROR${EC}: %s\\n" "$@" 1>&2;
}

log() {
    printf "${GC} *  INFO${EC}: %s\\n" "$@";
}

warn() {
    printf "${YC} *  WARN${EC}: %s\\n" "$@" 1>&2;
}

TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

if __check_command_exists kubectl; then
    warn "kubectl is installed skipping..."
else
    log "Installing kubectl"
    __install_kubectl "${KUBE_VERSION}"
fi

if __check_command_exists helm; then
    warn "helm is install skipping..."
else
    log "Installing helm"
    __install_helm "${HELM_VERSION}"
fi
