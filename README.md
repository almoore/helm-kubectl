# helm-kubernetes Docker hub image

[![](https://images.microbadger.com/badges/image/almoore/helm-kubectl.svg)](https://microbadger.com/images/almoore/helm-kubectl "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/almoore/helm-kubectl.svg)](https://microbadger.com/images/almoore/helm-kubectl "Get your own version badge on microbadger.com")
[![Build Status](https://travis-ci.org/almoore/helm-kubectl.svg?branch=master)](https://travis-ci.org/almoore/helm-kubectl)
[![Docker Stars](https://img.shields.io/docker/stars/alexgmoore/helm-kubectl.svg?style=flat)](https://hub.docker.com/r/alexgmoore/helm-kubectl/)
[![Docker Automated build](https://img.shields.io/docker/automated/alexgmoore/helm-kubectl.svg?style=flat)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/alexgmoore/helm-kubectl.svg)]()

Supported tags and release links

* [2.13.0](https://github.com/almoore/helm-kubectl/releases/tag/2.12.3) - helm v2.13.0, kubectl v1.13.4, alpine 3.9

## Overview

This lightweight alpine docker image provides kubectl and helm binaries for working with a Kubernetes cluster.  A local configured kubectl is a prerequisite to use helm per [helm documentation](https://github.com/kubernetes/helm/blob/master/docs/quickstart.md).  This image is useful for general helm administration such as deploying helm charts and managing releases. It is also perfect for any automated deployment pipeline needing to use helm which supports docker images such as [Concourse CI](https://concourse.ci), [Jenkins on Kubernetes](https://kubeapps.com/charts/stable/jenkins), [Travis CI](https://docs.travis-ci.com/user/docker/), and [Circle CI](https://circleci.com/integrations/docker/).  Having bash installed allows for better support for troubleshooting by being able to exec / terminal in and run desired shell scripts.  Git installed allows installation of [helm plugins](https://github.com/kubernetes/helm/blob/master/docs/plugins.md).

If it is desired to only use kubectl and have kubectl as the entry command (versus this image as bash entry command), I recommend checking out this image instead:
[lachlanevenson/kubectl](https://hub.docker.com/r/lachlanevenson/k8s-kubectl/)

## Run

Example to just run helm on entry:
`docker run --rm alexgmoore/helm-kubectl helm`
By default kubectl will try to use /root/.kube/config file for connection to the kubernetes cluster, but does not exist by default in the image.

Example for use with personal administration or troubleshooting with volume mount for kubeconfig files:
`docker run -it -v ~/.kube:/root/.kube alexgmoore/helm-kubectl`
The -v maps your host docker machine Kubernetes configuration directory (~/.kube) to the container's Kubernetes configuration directory (root/.kube).

## Build

For doing a manual local build of the image:
`make docker_build`

This image is now fully automated via travisci.org.
For reference this .travis.yml file can be validated via:
`docker run --rm -it -v yourclonedreporoot:/project caktux/travis-cli lint ./travis.yml`
