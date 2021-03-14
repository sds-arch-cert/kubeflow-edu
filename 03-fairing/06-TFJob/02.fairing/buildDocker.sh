#!/bin/bash

# 본 스크립트는 Docker build 가능한 환경에서만 실행됩니다.
# Jupyter Notebook Termial에서는 실행되지 않습니다.
# VM에서 실행해주세요.

#REGISTRY=registry.kube-system.svc.cluster.local:30000
IMG=mymnistbase
#TAG=${REGISTRY}/${IMG}
TAG=${IMG}

docker build -t ${TAG} .
# docker push ${TAG}

# 레지스트리 확인
# curl http://${REGISTRY}/v2/_catalog
# curl http://${REGISTRY}/v2/${IMG}/tags/list
