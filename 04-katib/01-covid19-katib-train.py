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
import numpy as np
import cv2
import os
import io
from PIL import Image

from minio import Minio
from minio.error import ResponseError
import argparse

from tensorflow.python.keras.callbacks import Callback

class KatibMetricLog(Callback):
    def on_epoch_begin(self, epoch, logs={}):
        print(
            "epoch " + str(epoch) + ":"
        )    
    def on_batch_end(self, batch, logs={}):
        print(
            "batch="               + str(batch),
            "accuracy="            + str(logs.get('accuracy')),
            "loss="                + str(logs.get('loss')),
        )
    def on_epoch_end(self, epoch, logs={}):
        print(
            "Validation-accuracy=" + str(logs.get('val_accuracy')),
            "Validation-loss="     + str(logs.get('val_loss')),
        )
        
parser = argparse.ArgumentParser()
parser.add_argument('--learning_rate', required=False, type=float, default=0.00001 )
parser.add_argument('--dense'        , required=False, type=float, default=128     )
args = parser.parse_args()    
print("args=", args)

# Hyperparameters 
LEARNING_RATE = args.learning_rate # List: 0.001, 0.0001, 0.0003, 0.00001, 0.00003
DENSE         = args.dense         # Range: 50-200

# Data Preparation

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

for i in minioClient.list_objects('dataset', prefix='covid19', recursive=True):
    label = i.object_name.split(os.path.sep)[-2]
    minioObj = minioClient.get_object('dataset', i.object_name)
    byteArray = minioObj.read()
    pil_image = Image.open(io.BytesIO(byteArray)).convert('RGB')
    image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
    image = cv2.resize(image, (256, 256))
    data.append(image)
    labels.append(label)

#normalise pixel values to real numbers between 0.0 - 1.0 
data = np.array(data) / 255.0
labels = np.array(labels)

# perform one-hot encoding for a 3-class labeling 
label_encoder = LabelEncoder()
integer_encoded = label_encoder.fit_transform(labels)
labels = to_categorical(integer_encoded)

print("... ... ", len(data), "images loaded in 3x classes:")
print(label_encoder.classes_)

(x_train, x_val, y_train, y_val) = train_test_split(data, labels, test_size=0.20, stratify=labels)

# Model 구성

model = Sequential()
adam_s = Adam(learning_rate = LEARNING_RATE)

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

# Model 학습

# train the head of the network
print("Training the full stack model...")

hist = model.fit(
    x_train, y_train, 
    verbose=0,   
    epochs=3, 
    validation_data=(x_val, y_val), 
    batch_size=8,
    callbacks=[KatibMetricLog()]    
)

loss         = hist.history['loss']
accuracy     = hist.history['accuracy']
val_loss     = hist.history['val_loss']
val_accuracy = hist.history['val_accuracy']

print(loss        )
print(accuracy    )
print(val_loss    )
print(val_accuracy)

# Model 저장

# os.environ.update({
#     'S3_ENDPOINT'          : 'minio-service.kubeflow:9000',
#     'AWS_ACCESS_KEY_ID'    : 'minio',
#     'AWS_SECRET_ACCESS_KEY': 'minio123',
#     'S3_USE_HTTPS'         : '0',   # Whether or not to use HTTPS. Disable with 0.                        
#     'S3_VERIFY_SSL'        : '0'    # If HTTPS is used, controls if SSL should be enabled. Disable with 0.
# })  

# model.save("s3://model/new-covid/1")

