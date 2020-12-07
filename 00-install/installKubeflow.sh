#!/bin/bash

echo '
=================================
도커 설치
---------------------------------
'
apt-get update
apt-get install -y docker.io

cat << EO_DOCKER_DAEMON > /etc/docker/daemon.json
{
        "insecure-registries": ["kubeflow-registry.default.svc.cluster.local:30000"]
}
EO_DOCKER_DAEMON

systemctl start docker
systemctl enable docker

echo '
=================================
kubectl 설치
---------------------------------
'
mkdir -p ~/kubeflow
cd ~/kubeflow

curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

echo '
=================================
minikube 설치
---------------------------------
'
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

echo '
=================================
minikube 기동
---------------------------------
'
sysctl fs.protected_regular=0

minikube start \
  --driver=none \
  --extra-config=apiserver.service-account-issuer=api \
  --extra-config=apiserver.service-account-signing-key-file=/var/lib/minikube/certs/apiserver.key \
  --extra-config=apiserver.service-account-api-audiences=api \
  --kubernetes-version v1.15.2   
  
echo '
=================================
방화벽 해제
---------------------------------
'
ufw disable  
  
echo '
=================================
K8s 대쉬보드 설치
---------------------------------
'
minikube addons enable dashboard 
minikube addons enable metrics-server

echo '
=================================
Kubeflow 설치
---------------------------------
'
export KF_HOME=~/kubeflow
export KF_NAME=sds-kubeflow

rm -rf ${KF_HOME}

mkdir -p $KF_HOME
cd $KF_HOME

rm -f ./kfctl*
wget https://github.com/kubeflow/kfctl/releases/download/v1.0.2/kfctl_v1.0.2-0-ga476281_linux.tar.gz
tar -xvf kfctl_*.tar.gz	

export PATH=$PATH:$KF_HOME
export KF_DIR=${KF_HOME}/${KF_NAME}
export CONFIG_URI=https://github.com/kubeflow/manifests/raw/master/kfdef/kfctl_k8s_istio.v1.0.2.yaml

mkdir -p ${KF_DIR}
cd ${KF_DIR}
kfctl apply -V -f ${CONFIG_URI}

echo '
=================================
Private Registry 설치
---------------------------------
'
cat << EO_REGISTRY_DEPLOY | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  generation: 1
  labels:
    run: kubeflow-registry
  name: kubeflow-registry
  namespace: default
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      run: kubeflow-registry
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: kubeflow-registry
    spec:
      containers:
      - image: registry:2
        imagePullPolicy: IfNotPresent
        name: kubeflow-registry
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
EO_REGISTRY_DEPLOY

cat << EO_REGISTRY_SVC | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    run: kubeflow-registry
  name: kubeflow-registry
  namespace: default
spec:
  ports:
  - name: registry
    port: 30000
    protocol: TCP
    targetPort: 5000
    nodePort: 30000
  selector:
    run: kubeflow-registry
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
EO_REGISTRY_SVC

cat << EO_HOSTS >> /etc/hosts
127.0.0.1	 kubeflow-registry.default.svc.cluster.local
EO_HOSTS
cat /etc/hosts

echo '
=================================
완료
---------------------------------
'

sleep 10
watch "kubectl get pod -A | grep -v Running"  