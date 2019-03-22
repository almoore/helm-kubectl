#!/bin/bash

# set -o nounset  # Treat unset variables as an error
set -e          # Exit on error


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
    curl -sSLk ${BASE_URL}/${BIN_FILE} -o kubectl && \
    mv kubectl ${INSTALL_PREFIX}/bin/kubectl
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  __check_command_exists
#   DESCRIPTION:  Check if a command exists.
#----------------------------------------------------------------------------------------------------------------------
# Install helm
__install_helm() {
    VERSION="${1}"
    # Note: Latest version of helm may be found at:
    # https://github.com/kubernetes/helm/releases
    BASE_URL="https://storage.googleapis.com/kubernetes-helm"
    TAR_FILE="helm-${VERSION}-linux-amd64.tar.gz"
    curl -sSLk ${BASE_URL}/${TAR_FILE} | tar xz && \
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

set_versions() {
    echo $1
    case "$1" in
        v2.13.0) HELM_VERSION=v2.13.0; KUBE_VERSION=v1.13.4; ALPINE_VERSION=3.9;;
        v2.12.3) HELM_VERSION=v2.12.3; KUBE_VERSION=v1.13.2; ALPINE_VERSION=3.8;;
        v2.12.2) HELM_VERSION=v2.12.2; KUBE_VERSION=v1.13.2; ALPINE_VERSION=3.8;;
        v2.12.1) HELM_VERSION=v2.12.1; KUBE_VERSION=v1.13.1; ALPINE_VERSION=3.8;;
        v2.12.0) HELM_VERSION=v2.12.0; KUBE_VERSION=v1.13.0; ALPINE_VERSION=3.8;;
        v2.11.0) HELM_VERSION=v2.11.0; KUBE_VERSION=v1.11.3; ALPINE_VERSION=3.8;;
        v2.10.0) HELM_VERSION=v2.10.0; KUBE_VERSION=v1.11.2; ALPINE_VERSION=3.8;;
        v2.9.1)  HELM_VERSION=v2.9.1;  KUBE_VERSION=v1.10.2; ALPINE_VERSION=3.7;;
        v2.9.0)  HELM_VERSION=v2.9.0;  KUBE_VERSION=v1.10.2; ALPINE_VERSION=3.7;;
        v2.8.2)  HELM_VERSION=v2.8.2;  KUBE_VERSION=v1.9.4;  ALPINE_VERSION=3.7;;
        v2.8.1)  HELM_VERSION=v2.8.1;  KUBE_VERSION=v1.9.2;  ALPINE_VERSION=3.7;;
        v2.8.0)  HELM_VERSION=v2.8.0;  KUBE_VERSION=v1.9.2;  ALPINE_VERSION=3.7;;
        v2.7.2)  HELM_VERSION=v2.7.2;  KUBE_VERSION=v1.8.3;  ALPINE_VERSION=3.6;;
        v2.7.0)  HELM_VERSION=v2.7.0;  KUBE_VERSION=v1.8.1;  ALPINE_VERSION=3.6;;
        v2.6.2)  HELM_VERSION=v2.6.2;  KUBE_VERSION=v1.7.9;  ALPINE_VERSION=3.6;;
        v2.6.1)  HELM_VERSION=v2.6.1;  KUBE_VERSION=v1.7.6;  ALPINE_VERSION=3.6;;
        v2.6.0)  HELM_VERSION=v2.6.0;  KUBE_VERSION=v1.7.4;  ALPINE_VERSION=3.6;;
        v2.5.1)  HELM_VERSION=v2.5.1;  KUBE_VERSION=v1.7.2;  ALPINE_VERSION=3.6;;
        v2.5.0)  HELM_VERSION=v2.5.0;  KUBE_VERSION=v1.6.6;  ALPINE_VERSION=3.6;;
        v2.4.2)  HELM_VERSION=v2.4.2;  KUBE_VERSION=v1.6.4;  ALPINE_VERSION=3.6;;
        v2.4.1)  HELM_VERSION=v2.4.1;  KUBE_VERSION=v1.6.2;  ALPINE_VERSION=3.5;;
        v2.3.1)  HELM_VERSION=v2.3.1;  KUBE_VERSION=v1.6.2;  ALPINE_VERSION=3.5;;
        *)
            error "Got version $1 which is not supported."
            exit
            ;;
    esac
}

build() {
    VCS_REF=$(git rev-parse --short HEAD)
    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # build the application image
    docker build . \
           --build-arg VCS_REF=${VCS_REF} \
           --build-arg BUILD_DATE=${BUILD_DATE} \
           -t alexgmoore/helm-kubectl:${HELM_VERSION}
}

deploy() {
    docker push alexgmoore/helm-kubectl:${HELM_VERSION}
}

make_dockerfile() {
    sed -e "s#_AV#${ALPINE_VERSION}#g" \
        -e "s#_HV#${HELM_VERSION}#g" \
        -e "s#_KV#${KUBE_VERSION}#g" \
        -e "s#_PRE#${INSTALL_PREFIX}#g" \
        $BASEDIR/docker/Dockerfile.tpl > $BASEDIR/Dockerfile
}


setup() {
    # Setup values
    # The supported versions
    VERSIONS="
      v2.3.1
      v2.4.1
      v2.4.2
      v2.5.0
      v2.5.1
      v2.6.0
      v2.6.1
      v2.6.2
      v2.7.0
      v2.7.2
      v2.8.0
      v2.8.1
      v2.8.2
      v2.9.0
      v2.9.1
      v2.10.0
      v2.11.0
      v2.12.0
      v2.12.1
      v2.12.2
      v2.12.3
      v2.13.0
    "
    BASEDIR=$(git rev-parse --show-toplevel)
    SCRIPTDIR=$(dirname $(realpath $BASH_SOURCE))
    DEBUG=0
    PUSH=0
    NOBUILD=0
    _VERSION=""
    HELM_VERSION=v2.13.0
    KUBE_VERSION=v1.13.4
    ALPINE_VERSION=3.9
    INSTALL_PREFIX=${INSTALL_PREFIX:-/usr/local}
    TEMP_DIR=$(mktemp -d)
}

usage() {
cat << EOF
USAGE: ${0##*/} [options]
  options:

  --nobuild             if specified skip building the Dockerfile

  --push                if specified the resulting docker image will be pushed

  --debug               debug logging

  Note: using any of these options will make a new Dockerfile
        from docker/Dockerfile.tpl

  --version VERSION     the version of helm to use

  --kube    VERSION     the version of kubectl to use 
                            (defaults to a mapped version)
  --alpine  VERISON     the version of alpine image to use
                            (defaults to a mapped version)
  --prefix PREFIX       where to put executables 
                            (default: /usr/local)

EOF
}

parse_args() {
    ARGS=( "$@" )
    while [ -n "${1}" ]; do
        case "${1}" in
            --debug)
                DEBUG=1
                ;;
            --nobuild)
                NOBUILD=1
                ;;
            --push)
                PUSH=1
                ;;
            --prefix)
                shift
                INSTALL_PREFIX="${1}"
                ;;
            --version)
                shift
                _VERSION="${1}"
                ;;
            --kube)
                shift
                KUBE_VERSION="${1}"
                ;;
            --alpine)
                shift
                ALPINE_VERSION="${1}"
                ;;
            *)
                usage
                exit
                ;;
        esac
        shift
    done
    if [ "${DEBUG}" -ne 0 ];then
        set -x
    fi
}

main() {
    setup
    parse_args "$@"
    if [ ! -z "$_VERSION" ]; then
       #if echo $VERSIONS | grep -q $_VERSION; then
           set_versions $_VERSION
       #else
       #    HELM_VERSION=$_VERSION
       #fi
       log "Using ALPINE_VERSION=${ALPINE_VERSION} - HELM_VERSION=${HELM_VERSION} - KUBE_VERSION=${KUBE_VERSION}"
       log "Creating Dockerfile for version $v"
       make_dockerfile
    fi
    if [ $NOBUILD -eq 0 ]; then
        build
    fi
    if [ ${PUSH} -eq 1 ]; then
        push
    fi
}

main "$@"
