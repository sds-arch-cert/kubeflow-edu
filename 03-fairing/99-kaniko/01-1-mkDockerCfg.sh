#!/bin/bash
DOCKER_USERNAME=$1
DOCKER_PASSWORD=$2
AUTH=$(echo -n "${DOCKER_USERNAME}:${DOCKER_PASSWORD}" | base64)
cat << EOF > dockerConfig.json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "${AUTH}"
        }
    }
}
EOF
