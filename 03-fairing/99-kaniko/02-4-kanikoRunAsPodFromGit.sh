#!/bin/bash
IMG=reddiana/kanikotest
KANIKO_POD=kaniko-$(date +'%H%M-%S')-$(uuidgen | cut -b -8)
echo $KANIKO_POD

kubectl apply --namespace=myspace -f - << EOK
apiVersion: v1
kind: Pod
metadata:
  name: ${KANIKO_POD}
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    args: ["--dockerfile=Dockerfile",
           "--context=git://github.com/sds-arch-cert/kubeflow-edu.git",
           "--context-sub-path=/02-JupyterNotebook",
           "--destination=${IMG}"]
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
    env:
      - name: GIT_USERNAME
        value: "$1"
      - name: GIT_PASSWORD 
        value: "$2"
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

kubectl wait --for=condition=ContainersReady -n myspace pod/${KANIKO_POD} --timeout=60s
kubectl logs -f -n myspace ${KANIKO_POD} kaniko

kubectl wait --for=condition=ContainersReady=false -n myspace pod/${KANIKO_POD} --timeout=1800s
kubectl delete -n myspace pod/${KANIKO_POD}
