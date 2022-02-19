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
wget kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64
chmod +x ~/kustomize

cd manifests
while ! ../kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done


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


KUBEFLOW_DASHBOARD_PORT=$(kubectl get svc -n istio-system istio-ingressgateway -o yaml | grep 'port: 443$' -A 2 -B 2 | grep nodePort | cut -d':' -f2 | xargs)

echo '
=================================
접속 port 및 계정
---------------------------------'
echo kubeflow dashboard: ${KUBEFLOW_DASHBOARD_PORT} \( username: user@example.com password: 12341234 \)
echo minio console: 32001 \( username: minio password: minio123 \)
