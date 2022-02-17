#!/bin/bash


echo '
=================================
설치버전 및 환경변수 설정
---------------------------------
KUBE_VERSION=1.21/stable
'

# snap 설치
sudo apt update
sudo apt install snapd -y 


# microk8s 설치
# snap 으로 Kubernetes 1.21 버전의 microk8s 를 설치합니다.
# sudo snap install microk8s --classic --channel=${KUBE_VERSION}


# admin group 에 사용자 계정 추가 및 alias 설정
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube
echo alias kubectl=microk8s.kubectl >> ~/.bashrc
echo alias k=microk8s.kubectl >> ~/.bashrc


echo 설정 적용을 위해 ssh console 을 재접속합니다.
echo switch user 명령 사용시 google-sudoers group 에서 제외되니, 반드시 gcp console 에서 ssh 접속하시기 바랍니다.
