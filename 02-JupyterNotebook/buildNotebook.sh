#!/bin/bash
docker build -t reddiana/jupyterlab-kale:${1:-latest} . && \
docker push reddiana/jupyterlab-kale:${1:-latest} && \
[ -n ${1} ] && {
	docker tag reddiana/jupyterlab-kale:${1} reddiana/jupyterlab-kale:latest
	docker push reddiana/jupyterlab-kale:latest
}
