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

mc config host list myminio 2&> /dev/null || \
mc config host add myminio http://minio-service.kubeflow:9000 minio minio123

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
Covid19 데이터셋 다운로드
----------------------------------------
'
rm -rf ./kale-example
git clone https://github.com/kubeflow-kale/examples.git ./kale-example

echo '
========================================
Covid19 데이터셋을 Minio에 업로드
----------------------------------------
'
mkBucket myminio/dataset/titanic
mc cp ./kale-example/titanic-ml-dataset/data/* myminio/dataset/titanic/
rm -rf ./kale-example

echo
echo '
========================================
완료
----------------------------------------
'
# mc tree myminio/dataset
# mc tree myminio/model
