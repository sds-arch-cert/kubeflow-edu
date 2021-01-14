#!/bin/bash
WD=/root/kubeflow-edu/03-fairing/99-kaniko
IMG=reddiana/jupyterlab-kale:by-docker-from-git
docker run \
	-v ${WD}/dockerConfig.json:/kaniko/.docker/config.json:ro \
    gcr.io/kaniko-project/executor:latest \
    --dockerfile=Dockerfile \
    --context=git://github.com/sds-arch-cert/kubeflow-edu.git \
    --context-sub-path=/03-fairing/99-kaniko \
    --destination=${IMG}
