# TF Job 실습
## 사전준비
1. Jupyter Notebook 생성 시, Data Volume 마운트
  - Data Volumes > [+ADD VOLUME] 클릭
    - Name: mnist-tfjob-data-volume
    - Mode: ReadWriteMany
    - Mount Point: /data
1. Dataset 준비
  - Jupyter Notebook Terminal에서 학습코드 실행하면 tensorflow_datasets 라이브러리가 Dataset을 다운로드 받음 -> /data
    - 이미 다운로드 받아져 있으면 다운로드 Skip함
      ```bash
      pip install tensorflow_datasets
      python mnist-dist.py
      ```
1. TF Job으로 실행시킬 Image 준비
  - **Docker 관련 작업은 모두 VM에서 수행**합니다.
      ```bash
      git clone https://github.com/sds-arch-cert/kubeflow-edu.git
      cd /root/kubeflow-edu/03-fairing/06-TFJob/01.cli
      ./buildDcoker.sh
      ```

## 실행
- Jupyter Notebook Terminal에서도 실행 가능
    ```bash
    kubectl apply -f tfjob.yaml
    ```
- K8s에서 TFJob / Pod 확인    