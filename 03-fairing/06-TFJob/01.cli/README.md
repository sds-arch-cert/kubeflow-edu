# TF Job 실습
## 사전준비
- TF Job으로 실행시킬 Image 준비
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