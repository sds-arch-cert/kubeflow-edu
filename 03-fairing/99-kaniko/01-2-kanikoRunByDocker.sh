#!/bin/bash
WD=`pwd`
IMG=sds.redii.net/mlopsdev/tmp:kaniko-by-docker
docker run \
	-v ${WD}/:/workspace/ \
	-v ${WD}/dockerConfig.json:/kaniko/.docker/config.json:ro \
    sds.redii.net/mlopsdev/kaniko-executor:latest \
    --dockerfile=/workspace/Dockerfile \
    --context=dir://workspace \
    --destination=${IMG}
