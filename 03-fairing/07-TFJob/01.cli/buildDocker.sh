#!/bin/bash

# 본 스크립트는 Docker build 가능한 환경에서만 실행됩니다.
# Jupyter Notebook Termial에서는 실행되지 않습니다.
# VM에서 실행해주세요.

REGISTRY=registry.kube-system.svc.cluster.local:30000
IMG=mytfjob

docker build -t ${REGISTRY}/${IMG} .
docker push ${REGISTRY}/${IMG}

# 레지스트리 확인
curl http://${REGISTRY}/v2/_catalog
curl http://${REGISTRY}/v2/${IMG}/tags/list