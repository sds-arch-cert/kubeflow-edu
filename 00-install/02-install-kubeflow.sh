#!/bin/bash

# microk8s 추가 addon 설치
# kubeflow 설치를 위해 microk8s 에 dns 와 storage, private image registry 를 구성합니다.
microk8s enable dns storage registry


# echo microk8s 설치 확인
microk8s status --wait-ready


# juju Client 설치
sudo snap install juju --classic

# juju 를 Kubernetes cluster 에 연결
while [ $(microk8s status --wait-ready | grep disabled -B 10 | grep storage | wc -l) == 0 ]
do
  echo "microk8s 에 storage 가 아직 구성되지 않았습니다. 5초 더 기다립니다."
  sleep 5
done


# install kubeflow
microk8s config > ~/.kube/config
juju add-k8s myk8s
juju bootstrap myk8s my-controller
juju add-model kubeflow
juju deploy kubeflow --trust

echo kubeflow deploy 가 완료되었습니다. 하지만 Kubernetes 에 완전히 구성되기까지 30~60분 정도 소요됩니다. 배포 상태는 다음 명령으로 확인합니다.
echo watch -c juju status --color


# 사용자 계정 환경변수 설정
DEX_USERNAME=admin
DEX_PASSWORD=P@sswd12
MINIO_ACCESS_KEY=minio
MINIO_SECRET_KEY=P@sswd12

# kubeflow 사용자 계정 설정
juju config dex-auth static-username=${DEX_USERNAME}
juju config dex-auth static-password=${DEX_PASSWORD}

# minio 사용자 계정 설정
juju config minio access-key=${MINIO_ACCESS_KEY}
juju config minio secret-key=${MINIO_SECRET_KEY}

# istio 권한 추가
kubectl patch role -n kubeflow istio-ingressgateway-operator -p '{"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"name":"istio-ingressgateway-operator"},"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]}]}'

juju config dex-auth public-url=http://dex-auth:5556/dex
juju config oidc-gatekeeper public-url=http://dex-auth:5556/dex

kubectl patch deployment -n kubeflow oidc-gatekeeper --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env/0", "value": {"name":"OIDC_AUTH_URL","value":"/dex/auth"} }]'

# minio node port 구성
MINIO_CONSOLE_PORT=$(kubectl logs -n kubeflow minio-0 | grep -i 'console:' | rev | cut -d':' -f1 | rev | xargs)
MINIO_CONSOLE_NODEPORT=30123

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio-console
  namespace: kubeflow
spec:
  ports:
  - name: http
    port: ${MINIO_CONSOLE_PORT}
    protocol: TCP
    targetPort: ${MINIO_CONSOLE_PORT}
    nodePort: ${MINIO_CONSOLE_NODEPORT}
  selector:
    app.kubernetes.io/name: minio
  sessionAffinity: None
  type: NodePort
EOF

KUBEFLOW_DASHBOARD_PORT=$(kubectl get svc -n kubeflow  istio-ingressgateway -o yaml | grep 'port: 80$' -A 2 -B 2 | grep nodePort | cut -d':' -f2 | xargs)

echo '
=================================
접속 port 및 계정
---------------------------------'
echo kubeflow dashboard: ${KUBEFLOW_DASHBOARD_PORT} \( ${DEX_USERNAME}/${DEX_PASSWORD} \)
echo minio console: ${MINIO_CONSOLE_PORT} \( ${MINIO_ACCESS_KEY}/${MINIO_SECRET_KEY} \)

