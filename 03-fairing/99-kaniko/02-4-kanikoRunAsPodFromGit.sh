#!/bin/bash
IMG=reddiana/jupyterlab-kale:as-pod-from-git
KANIKO_POD=kaniko-$(date +'%H%M-%S')-$(uuidgen | cut -b -8)
echo $KANIKO_POD

kubectl apply -f - << EOK
apiVersion: v1
kind: Pod
metadata:
  name: ${KANIKO_POD}
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--dockerfile=Dockerfile",
           "--context=git://github.com/sds-arch-cert/kubeflow-edu.git",
           "--context-sub-path=/03-fairing/99-kaniko",
           "--destination=${IMG}"]
    volumeMounts:
      - name: docker-config
        mountPath: /kaniko/.docker
  restartPolicy: Never
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

kubectl wait --for=condition=ContainersReady pod/${KANIKO_POD} --timeout=60s
kubectl logs -f ${KANIKO_POD} kaniko

kubectl wait --for=condition=ContainersReady=false pod/${KANIKO_POD} --timeout=1800s
kubectl delete pod/${KANIKO_POD}
