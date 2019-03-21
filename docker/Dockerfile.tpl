FROM alpine:_AV

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.name="helm-kubectl" \
      org.label-schema.url="https://hub.docker.com/r/alexgmoore/helm-kubectl/" \
      org.label-schema.vcs-url="https://github.com/almoore/helm-kubectl" \
      org.label-schema.build-date=$BUILD_DATE

# Note: Latest version of kubectl may be found at:
# https://aur.archlinux.org/packages/kubectl-bin/

ARG KUBE_VERSION="_KV"

# Note: Latest version of helm may be found at:
# https://github.com/kubernetes/helm/releases

ARG HELM_VERSION="_HV"

RUN apk add --no-cache ca-certificates bash git openssh curl \
    && curl -sSkL https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o _PRE/bin/kubectl \
    && chmod +x _PRE/bin/kubectl \
    && curl -sSkL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xzO linux-amd64/helm > _PRE/bin/helm \
    && chmod +x _PRE/bin/helm

WORKDIR /config

CMD bash
