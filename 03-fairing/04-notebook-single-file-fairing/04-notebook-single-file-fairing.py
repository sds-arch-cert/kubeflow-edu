#!/usr/bin/env python
# coding: utf-8

# In[1]:


import tensorflow as tf
import os

class MyFashionMnist(object):
  def train(self):
    mnist = tf.keras.datasets.mnist

    (x_train, y_train), (x_test, y_test) = mnist.load_data()
    x_train, x_test = x_train / 255.0, x_test / 255.0

    model = tf.keras.models.Sequential([
        tf.keras.layers.Flatten(input_shape=(28, 28)),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(10, activation='softmax')
    ])

    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    model.summary()

    print("Training...")
    
    model.fit(
        x_train, y_train, 
        epochs=3, 
        validation_split=0.2 
    ) 
    
    score = model.evaluate(x_test, y_test, batch_size=128, verbose=0)
    print('Test accuracy: ', score[1])


# In[2]:


if __name__ == '__main__':
    if os.getenv('FAIRING_RUNTIME', None) is None:
        from kubeflow import fairing
        from kubeflow.fairing.kubernetes import utils as k8s_utils
        
        PRIVATE_REGISTRY = 'kubeflow-registry.default.svc.cluster.local:30000'
        
        # fairing.config.set_preprocessor(
        #     'notebook', 
        #     command = ['python3'],  # default: python
        # )
        
        fairing.config.set_builder(
            'append',
            base_image=f'{PRIVATE_REGISTRY}/kf-base:latest', # 사전준비에서 마련한 Base Image
            registry = PRIVATE_REGISTRY,
            image_name='my-04-notebook-single-file-fairing-job', 
            push=True
        )
        
        fairing.config.set_deployer(
            'job',
            namespace='myspace',
            pod_spec_mutators=[
                k8s_utils.get_resource_mutator(cpu=1, memory=5)]
        )
        
        fairing.config.run()
    else:
        remote_train = MyFashionMnist()
        remote_train.train()


# In[ ]:




