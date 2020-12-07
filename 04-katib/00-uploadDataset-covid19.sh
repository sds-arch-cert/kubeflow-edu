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

mc config host list myminio || \
mc config host add myminio http://minio-service.kubeflow:9000 minio minio123

: '
========================================
Minio 레파지토리에 bucet 생성 함수
----------------------------------------
'
function mkBucket() {
    mc rm -r --force $1
    # mc rb $1
    mc ls $1 || mc mb $1
}

echo '
========================================
Minio 레파지토리에 model bucet 생성
----------------------------------------
'
mkBucket myminio/dataset/covid19

echo '
========================================
mnist 데이터셋 다운로드
----------------------------------------
'
rm -rf ./Covid19-X-Rays
git clone https://github.com/zhongli1990/Covid19-X-Rays.git

echo '
========================================
mnist 데이터셋을 Minio에 업로드
----------------------------------------
'
mc cp -r Covid19-X-Rays/all/ myminio/dataset/covid19/
rm -rf ./Covid19-X-Rays

echo
echo '
========================================
완료
----------------------------------------
'
# mc tree myminio/dataset
# mc tree myminio/model
