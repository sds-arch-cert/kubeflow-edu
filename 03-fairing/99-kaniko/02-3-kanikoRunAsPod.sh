#!/bin/bash
IMG=sds.redii.net/mlopsdev/tmp:as-pod
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
    image: sds.redii.net/mlopsdev/kaniko-executor:latest
    args: ["--dockerfile=/workspace/Dockerfile",
           "--context=dir://workspace",
           "--destination=${IMG}"]
    volumeMounts:
      - name: dockerfile-storage
        mountPath: /workspace
      - name: docker-config
        mountPath: /kaniko/.docker
  restartPolicy: Never
  volumes:
    - name: dockerfile-storage
      persistentVolumeClaim:
        claimName: dockerfile-claim
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
