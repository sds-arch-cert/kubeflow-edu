#!/usr/bin/env python
# coding: utf-8

# In[1]:


from tensorflow.keras.layers import AveragePooling2D, Dropout, Flatten, Dense, Input, BatchNormalization
from tensorflow.keras.models import Model, Sequential
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.utils import to_categorical
from tensorflow.keras import optimizers, models, layers
from tensorflow.keras.applications.inception_v3 import InceptionV3
from tensorflow.keras.applications import ResNet50V2

from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from imutils import paths
import matplotlib.pyplot as plt
import numpy as np
import cv2
import os
import io
from PIL import Image

from minio import Minio
# from minio.error import ResponseError


# # Data Preparation

# In[2]:


print("Loading images...")

minioClient = Minio(
                'minio-service.kubeflow:9000',
                access_key='minio', 
                secret_key='minio123', 
                secure=False
            )

data = []
labels = []

# read all X-Rays in the specified path, and resize them all to 256x256

for i in minioClient.list_objects('dataset', prefix='covid-19', recursive=True):
    label = i.object_name.split(os.path.sep)[-2]
    minioObj = minioClient.get_object('dataset', i.object_name)
    byteArray = minioObj.read()
    pil_image = Image.open(io.BytesIO(byteArray)).convert('RGB')
    image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
    image = cv2.resize(image, (256, 256))
    data.append(image)
    labels.append(label)


# In[3]:


#normalise pixel values to real numbers between 0.0 - 1.0 
data = np.array(data) / 255.0
labels = np.array(labels)

# perform one-hot encoding for a 3-class labeling 
label_encoder = LabelEncoder()
integer_encoded = label_encoder.fit_transform(labels)
labels = to_categorical(integer_encoded)

print("... ... ", len(data), "images loaded in 3x classes:")
print(label_encoder.classes_)


# In[4]:


(x_train, x_val, y_train, y_val) = train_test_split(data, labels, test_size=0.20, stratify=labels)


# # Model 구성

# In[5]:


# Hyperparameters 
LEARNING_RATE = 0.00001 # List: 0.001, 0.0001, 0.0003, 0.00001, 0.00003
DENSE = 128             # Range: 50-200


# In[6]:


model = Sequential()
adam_s = Adam(learning_rate = LEARNING_RATE)

#model.add(VGG16(input_shape=(224, 224, 3), include_top=False, weights='imagenet', pooling='average'))
model.add(ResNet50V2(input_shape=(256, 256, 3),include_top=False, weights='imagenet',pooling='average'))

for layer in model.layers:
    layer.trainable = False

model.add(BatchNormalization())
model.add(Flatten())
model.add(Dense(DENSE, activation='relu'))
model.add(Dense(DENSE, activation='relu'))
model.add(Dense(3, activation='softmax'))
model.compile(loss='categorical_crossentropy', optimizer=adam_s, metrics=['accuracy'])

model.summary()


# # Model 학습

# In[7]:


# train the head of the network
print("Training the full stack model...")
hist = model.fit(x_train, y_train, epochs=3, validation_data=(x_val, y_val), batch_size=8)


# In[8]:


loss        = hist.history['loss'][-1]
accuracy    = hist.history['accuracy'][-1]
valloss     = hist.history['val_loss'][-1]
valaccuracy = hist.history['val_accuracy'][-1]


# # Model 저장

# In[ ]:


os.environ.update({
    'S3_ENDPOINT'          : 'minio-service.kubeflow:9000',
    'AWS_ACCESS_KEY_ID'    : 'minio',
    'AWS_SECRET_ACCESS_KEY': 'minio123',
    'S3_USE_HTTPS'         : '0',   # Whether or not to use HTTPS. Disable with 0.                        
    'S3_VERIFY_SSL'        : '0'    # If HTTPS is used, controls if SSL should be enabled. Disable with 0.
})  

#model.save("s3://model/covid19/1")
model.save("./covid19/1")


# In[ ]:


print(valloss)
print(valaccuracy)


# In[ ]:




