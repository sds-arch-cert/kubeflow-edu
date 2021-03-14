# 실습환경 구성

## GCP VM인스턴스 생성

- 머신구성
  - 머신계열 > 일반용도
    - 시리즈: N1
    - 머신유형: 커스텀
      - 코어: 8 vCPU
      - 메모리: 36 GB
      - 메모리확장: 선택안함
- 부팅 디스크
  - 운영체계/버전: Ubuntu 20.04 LTS
  - 부팅디스크 유형: 표준 영구 디스크
  - 크기: 300GB
- 네트워킹
  - 네트워크 태그: kubeflow
  - 네트워크 인터페이스
    - 외부IP: 임시
      - 네트워크 서비스 계층: 표준

## Kubeflow 설치

- Minikube를 사용하여 Single Node Cluster 구성

- [installKubeflow.sh](https://github.com/sds-arch-cert/kubeflow-edu/blob/main/00-install/installKubeflow.sh) 
  
  - 도커 설치
  
    - insecure-registries: ["registry.kube-system.svc.cluster.local:30000"]
  
  - kubectl 설치
  
  - minikube 설치 (K8s  v1.16.15)
  
  - K8s 대쉬보드 / Private Registry 설치 (minikube addons)
  
  - Kubeflow 설치 (v1.2.0)
  
  - K9s 설치
  
  - NodePort 설정
  
    | 서비스           | Node Port | 비고                           |
    | ---------------- | --------- | ------------------------------ |
    | Private Registry | 30000     | Port도 동일하게 30000으로 설정 |
    | K8s 대쉬보드     | 30003     |                                |
    | Minio            | 32001     |                                |
  
  - /etc/hosts
  
    ```
    127.0.0.1	registry.kube-system.svc.cluster.local
    ```
  
    

