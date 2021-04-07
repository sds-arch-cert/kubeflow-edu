#!/bin/bash
DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
DOCKER_SERVER=https://sds.redii.net
#NAMESPACE=myspace
NAMESPACE=default

kubectl create secret docker-registry regcred \
    --docker-username=${DOCKER_USERNAME} \
    --docker-password=${DOCKER_PASSWORD} \
    --namespace=${NAMESPACE}

    #--docker-server=${DOCKER_SERVER} \
