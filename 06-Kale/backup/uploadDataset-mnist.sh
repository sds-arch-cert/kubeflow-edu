#!/bin/bash

echo '
========================================
Minio Cli 설치
----------------------------------------
'
which mc || {
    wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    sudo mv mc /usr/bin 
}    

mc config host add myminio http://minio-service.kubeflow:9000 minio minio123
mc config host list myminio

: '
========================================
Minio 레파지토리에 bucet 생성 함수
----------------------------------------
'
function mkBucket() {
    # mc rm -r --force $1
    # mc rb $1
    mc ls $1 || mc mb $1
}

echo '
========================================
Minio 레파지토리에 dataset bucet 생성
----------------------------------------
'
mkBucket myminio/dataset

echo '
========================================
Minio 레파지토리에 model bucet 생성
----------------------------------------
'
mkBucket myminio/model

echo '
========================================
mnist 데이터셋 다운로드
----------------------------------------
'
rm -f mnist.npz
wget https://storage.googleapis.com/tensorflow/tf-keras-datasets/mnist.npz

echo '
========================================
mnist 데이터셋을 Minio에 업로드
----------------------------------------
'
mc mv mnist.npz myminio/dataset/mnist/
echo

echo '
========================================
완료
----------------------------------------
'
# mc tree myminio/dataset
# mc tree myminio/model
