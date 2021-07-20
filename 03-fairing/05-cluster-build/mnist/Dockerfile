FROM tensorflow/tensorflow

COPY /mnist/python-file-to-fairing.py \
     /train/mnist.py

RUN  pip install -U pip

# 예제 실행에 필요한건 아니지만 딱히 설치할게 없어서
RUN  pip install minio pipdeptree

CMD  ["python", "/train/mnist.py"]