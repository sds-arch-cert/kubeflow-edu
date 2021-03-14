FROM tensorflow/tensorflow:2.1.0-py3

RUN pip install -U pip && \
    pip install tensorflow-datasets

RUN  mkdir -p /app
COPY mnist-dist.py /app/