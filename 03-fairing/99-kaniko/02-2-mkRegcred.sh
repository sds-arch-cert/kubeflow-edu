#!/bin/bash
DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
DOCKER_SERVER=https://index.docker.io/v1/
kubectl create secret docker-registry regcred \
    --docker-server=${DOCKER_SERVER} \
    --docker-username=${DOCKER_USERNAME} \
    --docker-password=${DOCKER_PASSWORD}
