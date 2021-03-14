#!/bin/bash

function helpMsg() {
  ME=$(basename $0)
  cat << EOU

Usage:
  $ME [flags] [build-context]

Flags:
  -f,     --dockerfile      Path to the dockerfile to be built. (optional, default: "Dockerfile")
  -c,     --build-context   path to be the dockerfile build context. (optional, default: ".")
  -d, -t, --destination     Registry the final image should be pushed to.
          --redii-id        sds.redii.net id
          --redii-pw        sds.redii.net passpord of id

Example:
  $ME \\
    -f=Dockerfile \\
    -t=sds.redii.net/mlopsdev/tmp:test \\
    --redii-id=myid \\
    --redii-pw=mypassword \\
    ./dockerBuildSample

EOU
}


# default value
DOCKERFILE="Dockerfile"
CONTEXT=.

for i in "$@"
do
  case $i in
    -f=*|--dockerfile=* )
        DOCKERFILE="${i#*=}"
        shift 
        ;;
    [^-]*) 
        CONTEXT=${1}
        shift
        ;;
    -c=*|--build-context=*)
        CONTEXT="${i#*=}"
        shift
        ;;
    -t=*|-d=*|--destination=*)
        DESTINATION_IMG="${i#*=}"
        shift
        ;;
    --redii-id=*)
        REDII_ID="${i#*=}"
        shift
        ;;
    --redii-pw=*)
        REDII_PW="${i#*=}"
        shift
        ;;
    --help)
        helpMsg
        exit
        ;;
    *)
        shift
        ;;
  esac
done

# TODO argument validation

which uuidgen > /dev/null || sudo apt-get install uuid-runtime || exit

UUID=$(date +'%H%M-%S')-$(uuidgen | cut -b -8)
KANIKO_POD=kaniko-${UUID}
DOCKER_SECRET=redii-${UUID}

echo "

DST_IMG    : ${DESTINATION_IMG}
DOCKERFILE : ${CONTEXT}/${DOCKERFILE}
CONTEXT    : ${CONTEXT}

"

kubectl create secret docker-registry ${DOCKER_SECRET} \
            --docker-server=sds.redii.net \
            --docker-username=${REDII_ID} \
            --docker-password=${REDII_PW} 

KANIKO_EXECUTOR=sds.redii.net/mlopsdev/kaniko-executor:debug
read -r -d '' MANIFEST << EOF
{
  "apiVersion":"v1",
  "kind":"Pod",
  "metadata":{
    "name":"${KANIKO_POD}",
    "annotations": {
        "sidecar.istio.io/inject": "false"  
    }
  },
  "spec":{
    "containers":[
      {
        "name":"kaniko",
        "image":"${KANIKO_EXECUTOR}",
        "stdin":true,
        "stdinOnce":true,
        "args":[
          "--dockerfile=${DOCKERFILE}",
          "--context=tar://stdin",
          "--destination=${DESTINATION_IMG}"
        ],
        "volumeMounts":[
          {
            "name":"docker-config",
            "mountPath":"/kaniko/.docker"
          }
        ]
      }
    ],
    "volumes":[
      {
        "name":"docker-config",
        "projected":{
          "sources":[
            {
              "secret":{
                "name":"${DOCKER_SECRET}",
                "items":[
                  {
                    "key":".dockerconfigjson",
                    "path":"config.json"
                  }
                ]
              }
            }
          ]
        }
      }
    ]
  }
}
EOF

tar -czf - -C ${CONTEXT} . | kubectl run ${KANIKO_POD} \
    --generator=run-pod/v1 \
    --rm \
    --stdin=true \
    --image=${KANIKO_EXECUTOR} \
    --restart=Never \
    --overrides="${MANIFEST}"

kubectl delete secret/${DOCKER_SECRET}

