#!/bin/bash

echo '
=================================
microk8s 추가 addon 설치
---------------------------------'

microk8s enable dns dashboard storage 

while [ $(kubectl get po -n kube-system | grep -v Running | wc -l) -gt 1 ]; do echo "Retrying to apply kube-system."; sleep 5; done


echo '
=================================
kube-apiserver 설정 추가
---------------------------------'

if [ -z $(grep service-account-signing-key-file /var/snap/microk8s/current/args/kube-apiserver) ];
then
  echo '--service-account-signing-key-file=${SNAP_DATA}/certs/serviceaccount.key' >> /var/snap/microk8s/current/args/kube-apiserver
  echo '--service-account-issuer=kubernetes.default.svc' >> /var/snap/microk8s/current/args/kube-apiserver
fi


echo '
=================================
private image registry insecure url 로 등록
refer to https://microk8s.io/docs/registry-private
---------------------------------'
# for microk8s v1.3
IMAGE_REGISTRY_DNS_NAME=myhost.local
IMAGE_REGISTRY_PORT=32000
IMAGE_REGISTRY_CONFIG=/var/snap/microk8s/current/args/containerd-template.toml

if [ -z $(grep ${IMAGE_REGISTRY_DNS_NAME} ${IMAGE_REGISTRY_CONFIG}) ];
then
  echo '      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${IMAGE_REGISTRY_DNS_NAME}:${IMAGE_REGISTRY_PORT}"]' >> ${IMAGE_REGISTRY_CONFIG}
  echo '        endpoint = ["http://'${IMAGE_REGISTRY_DNS_NAME}':'${IMAGE_REGISTRY_PORT}'"]' >> ${IMAGE_REGISTRY_CONFIG}
fi

echo '
=================================
microk8s 재기동
---------------------------------'

microk8s stop
microk8s start


echo '
=================================
microk8s 상태 확인
---------------------------------'

microk8s status



echo '
=================================
kubeflow manifests 설치
---------------------------------'
cd ~
git clone https://github.com/kubeflow/manifests.git
wget -O kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64
chmod +x ~/kustomize

cd manifests
while ! ../kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# pipeline for multiuser
../kustomize build apps/pipeline/upstream/env/platform-agnostic-multi-user-pns | kubectl apply -f -


echo '
=================================
kubeflow용 tls 인증서 구성
---------------------------------'

read -p "외부 접속 IP 또는 Domain name을 입력하세요 : " DNS_NAME

kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kubeflow-tls
  namespace: istio-system
spec:
  commonName: ${DNS_NAME}
  dnsNames:
  - ${DNS_NAME}
  issuerRef:
    kind: ClusterIssuer
    name: kubeflow-self-signing-issuer
  secretName: kubeflow-tls
EOF

# kubeflow gateway 에 https host 추가
kubectl patch gateway -n kubeflow kubeflow-gateway --type='json' -p '[
	{"op":"add", "path":"/spec/servers/1", "value":{"hosts":["*"], "port":{"name":"https", "number":443, "protocol":"HTTPS"}, "tls":{"credentialName":"kubeflow-tls","mode":"SIMPLE"}}}
]'


# istio-gateway nodeport 추가
KUBEFLOW_DASHBOARD_PORT=32001
kubectl apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: istio-gateway-extra-service
  namespace: istio-system
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: https
    nodePort: ${KUBEFLOW_DASHBOARD_PORT}
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    app: istio-ingressgateway
    istio: ingressgateway
  sessionAffinity: None
  type: NodePort
EOF

# Minio 접속용 virtual service 추가
kubectl apply -f - << EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: minio-web
  namespace: kubeflow
spec:
  gateways:
  - kubeflow-gateway
  hosts:
  - '*'
  http:
  - match:
    - uri:
        prefix: /minio
    rewrite:
      uri: /minio
    route:
    - destination:
        host: minio-service.kubeflow.svc.cluster.local
        port:
          number: 9000
EOF

echo '
=================================
image registry 추가
---------------------------------'

# dex service nodeport 제거
kubectl patch service -n auth dex --type='json' -p '[
        {"op":"remove", "path":"/spec/ports/0/nodePort"},
	{"op":"replace", "path":"/spec/type", "value":"ClusterIP"}
]'

microk8s enable registry:size=40Gi


echo '
=================================
대쉬보드 서비스 nodePort로 노출
---------------------------------'

kubectl patch svc -n kube-system kubernetes-dashboard --type='json' -p '[
	{"op":"replace","path":"/spec/type",            "value":"NodePort"},
	{"op":"replace","path":"/spec/ports/0/nodePort","value":30003}
]'


echo '
=================================
접속 port 및 계정
---------------------------------'
echo kubeflow dashboard: https://${DNS_NAME}:${KUBEFLOW_DASHBOARD_PORT} \( username: user@example.com password: 12341234 \)
echo minio console: https://${DNS_NAME}:${KUBEFLOW_DASHBOARD_PORT}/minio \( username: minio password: minio123 \)
echo image registry : http://${IMAGE_REGISTRY_DNS_NAME}:${IMAGE_REGISTRY_PORT}
echo kubernetes dashboard : https://${DNS_NAME}:30003

