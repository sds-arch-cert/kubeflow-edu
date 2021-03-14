# 실습환경 구성

## VM인스턴스 생성

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

- [installKubeflow.sh](https://github.com/sds-arch-cert/kubeflow-edu/blob/main/00-install/installKubeflow.sh) 
  - 도커 설치
  - kubectl 설치
  - minikube 설치
  - Kubeflow 설치
  - K9s 설치
