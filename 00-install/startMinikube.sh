#!/bin/bash

# https://www.kubeflow.org/docs/started/k8s/overview/

# https://github.com/kubernetes/kubernetes/releases
#K8S_VER=v1.15.2
K8S_VER=v1.16.15
#K8S_VER=v1.17.17
#K8S_VER=v1.18.16
#K8S_VER=v1.19.7
#K8S_VER=v1.20.4

minikube start \
  --driver=none \
  --extra-config=apiserver.service-account-issuer=api \
  --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key \
  --extra-config=apiserver.service-account-api-audiences=api \
  --kubernetes-version $K8S_VER
