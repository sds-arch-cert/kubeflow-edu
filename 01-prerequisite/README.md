# Kubeflow 설치 후 아래 내용을 추가로 진행합니다.

notebook server 의 terminal에서 아래를 진행합니다.

1. 실습용 데이터를 minio 에 구성
```
./00-uploadDataset-covid19.sh
./01-uploadDataset-titanic.sh
```

2. notebook 에서 pipeline 사용을 위한 PodDefault 생성
```
kubectl -f 02-pipeline-poddefault.yaml
```
