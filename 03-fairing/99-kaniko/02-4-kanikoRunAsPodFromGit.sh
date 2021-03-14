#!/bin/bash
IMG=sds.redii.net/mlopsdev/tmp:as-pod-from-git
KANIKO_POD=kaniko-$(date +'%H%M-%S')-$(uuidgen | cut -b -8)
echo $KANIKO_POD

kubectl apply --namespace=red-suh -f - << EOK
apiVersion: v1
kind: Pod
metadata:
  name: ${KANIKO_POD}
spec:
  containers:
  - name: kaniko
    image: sds.redii.net/mlopsdev/kaniko-executor:latest
    args: ["--dockerfile=Dockerfile",
           "--context=git://code.sdsdev.co.kr/reddiana/MLOpsSample.git",
           "--context-sub-path=/03-fairing/99-kaniko",
           "--destination=${IMG}"]
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
    env:
      - name: GIT_USERNAME
        value: "$1"
      - name: GIT_PASSWORD 
        value: "$2"
  # restartPolicy: Never로 하면 initialize pods with istio-proxy 하는 경우 에러. 
  # - https://github.com/GoogleContainerTools/kaniko/issues/753#issuecomment-592580847
  restartPolicy: OnFailure 
  volumes:
    - name: docker-config
      projected:
        sources:
        - secret:
            name: regcred
            items:
              - key: .dockerconfigjson
                path: config.json
EOK

kubectl wait --for=condition=ContainersReady -n red-suh pod/${KANIKO_POD} --timeout=60s
kubectl logs -f -n red-suh ${KANIKO_POD} kaniko

kubectl wait --for=condition=ContainersReady=false -n red-suh pod/${KANIKO_POD} --timeout=1800s
kubectl delete -n red-suh pod/${KANIKO_POD}
