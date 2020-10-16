#!/usr/bin/env python
# coding: utf-8

# In[1]:


# add for tensorboard code
from __future__ import absolute_import, division, print_function, unicode_literals
import argparse
import json
from tensorflow.python.lib.io import file_io

# origin fairing code
import tensorflow as tf
import os

class MyFashionMnist(object):
  def train(self):
           
    print("TensorFlow version: ", tf.__version__)

    mnist = tf.keras.datasets.mnist

    (x_train, y_train), (x_test, y_test) = mnist.load_data()
    x_train, x_test = x_train / 255.0, x_test / 255.0

    model = tf.keras.models.Sequential([
        tf.keras.layers.Flatten(input_shape=(28, 28)),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(10, activation='softmax')
    ])
    model.compile(optimizer='adam',
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
    model.summary()

    print("Training...")
    
    model.fit(x_train, y_train, epochs=3, validation_split=0.2 ) 
    
    score = model.evaluate(x_test, y_test, batch_size=128, verbose=0)
    print('Test accuracy: ', score[1])

if __name__ == '__main__':
    if os.getenv('FAIRING_RUNTIME', None) is None:
        from kubeflow import fairing
        from kubeflow.fairing.kubernetes import utils as k8s_utils
        
        DOCKER_REGISTRY = 'kubeflow-registry.default.svc.cluster.local:30000'   # 프라이빗 레지스트리

        fairing.config.set_builder(
            'append',
            image_name='tensorboard-job', # here not fairing job but katib job
            base_image='brightfly/kubeflow-jupyter-lab:tf2.0-cpu',
            registry=DOCKER_REGISTRY, 
            push=True
        )
        # cpu 1, memory 5GiB
        fairing.config.set_deployer('job',
                                    namespace='admin', # here
                                    pod_spec_mutators=[
                                        k8s_utils.get_resource_mutator(cpu=1,  # here
                                                                       memory=5)]
                                   )
        fairing.config.run()
    else:
        remote_train = MyFashionMnist()
        remote_train.train()


# In[ ]:




