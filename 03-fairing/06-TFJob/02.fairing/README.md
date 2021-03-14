# TF Job 실습
## 사전준비
- Base Image 준비
  - **Docker 관련 작업은 모두 VM에서 수행**합니다.
      ```bash
      git clone https://github.com/sds-arch-cert/kubeflow-edu.git
      cd /root/kubeflow-edu/03-fairing/06-TFJob/02.fairing
      ./buildDcoker.sh
      ```

## 실행
- tfjob-fairing.ipynb 실행
- K8s에서 TFJob / Pod 확인
  - TFJob의 description을 확인하여 TFJob manifest 내용을 확인한다