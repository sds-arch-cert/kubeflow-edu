#!/bin/bash

function helpMsg() {
  ME=$(basename $0)
  cat << EOU

Usage:
  $ME [flags]

Flags:
  --dockerfile    Path to the dockerfile to be built. (default "Dockerfile")
  --git-url       Gti url to download and to be the dockerfile build context.
  --git-sub-path  Sub path within the given context.
  --destination   Registry the final image should be pushed to.

Example:
  $ME \\
    --dockerfile=Dockerfile \\
    --git-url=git://github.com/sds-arch-cert/kubeflow-edu.git \\
    --git-sub-path=/03-fairing/99-kaniko \\
    --destination=reddiana/jupyterlab-kale:0.0.1

EOU
}

DOCKERFILE="Dockerfile"

for i in "$@"
do
  case $i in
    --dockerfile=*)
        DOCKERFILE="${i#*=}"
        shift 
        ;;
    --git-url=*)
        CONTEXT="${i#*=}"
        shift
        ;;
    --git-sub-path=*)
        CONTEXT_SUB_PATH="${i#*=}"
        shift
        ;;
    --destination=*)
        DESTINATION_IMG="${i#*=}"
        shift
        ;;
    --help)
        echo $USAGE
	helpMsg
        exit
        ;;
    *)
        shift
        ;;
  esac
done

KANIKO_POD=kaniko-$(date +'%H%M-%S')-$(uuidgen | cut -b -8)

[[ $CONTEXT =~ ^git ]] || {
  echo '
ERROR: git-url scheme should be "git://"
' 
  helpMsg
  exit
}

# TODO argument validation

echo "

DOCKERFILE: ${DOCKERFILE}
CONTEXT: ${CONTEXT}
CONTEXT_SUB_PATH: ${CONTEXT_SUB_PATH}
DESTINATION_IMG: ${DESTINATION_IMG}
KANIKO_POD: $KANIKO_POD

"

SCRT="regcred"
kubectl get secrets ${SCRT}

kubectl apply -f - << EOK
apiVersion: v1
kind: Pod
metadata:
  name: ${KANIKO_POD}
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--dockerfile=${DOCKERFILE}",
           "--context=${CONTEXT}",
           "--context-sub-path=${CONTEXT_SUB_PATH}",
           "--destination=${DESTINATION_IMG}"]
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
  restartPolicy: OnFailure # Never로 하면 initialize pods with istio-proxy 하는 경우 에러. https://github.com/GoogleContainerTools/kaniko/issues/753#issuecomment-592580847
  volumes:
    - name: docker-config
      projected:
        sources:
        - secret:
            name: ${SCRT}
            items:
              - key: .dockerconfigjson
                path: config.json
EOK

kubectl wait --for=condition=ContainersReady pod/${KANIKO_POD} --timeout=180s
kubectl logs -f ${KANIKO_POD} kaniko

kubectl wait --for=condition=ContainersReady=false pod/${KANIKO_POD} --timeout=1800s
kubectl delete pod/${KANIKO_POD}
