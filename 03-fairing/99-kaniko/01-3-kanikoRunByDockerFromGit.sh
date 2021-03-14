#!/bin/bash
WD=`pwd`
#export GIT_USERNAME=
#export GIT_PASSWORD=
#export GIT_TOKEN=226192790b943dd1e0aa9e4dd558c18653a979dd
IMG=sds.redii.net/mlopsdev/tmp:kaniko-by-docker-from-git
docker run \
    -v ${WD}/dockerConfig.json:/kaniko/.docker/config.json:ro \
    --storage-opt size=20G \
    --rm \
    --name kaniko \
    sds.redii.net/mlopsdev/kaniko-executor:debug \
    --dockerfile=Dockerfile \
    --context=git://226192790b943dd1e0aa9e4dd558c18653a979dd@code.sdsdev.co.kr/reddiana/MLOpsSample.git \
    --context-sub-path=/02-JupyterNotebook \
    --destination=${IMG}

#    -v /tmp/MLOpsSample/03-fairing/99-kaniko/tmp:/usr \
