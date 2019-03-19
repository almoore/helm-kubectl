#!/usr/bin/env bash
VCS_REF=$(git rev-parse HEAD)

curl -sSL --user ${CIRCLE_TOKEN}: \
    --request POST \
    --form revision=${VCS_REF}\
    --form config=@config.yml \
    --form notify=false \
    https://circleci.com/api/v1.1/project/github/almoore/helm-kubectl/tree/master
