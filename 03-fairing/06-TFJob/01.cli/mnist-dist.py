import os
import json
import tensorflow as tf
import tensorflow_datasets as tfds

import warnings
warnings.simplefilter("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"

def build_and_compile_model():
    model = tf.keras.models.Sequential([
        tf.keras.layers.Flatten(input_shape=(28, 28, 1)),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(10)
    ])
    model.compile(loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
                  optimizer=tf.keras.optimizers.Adam(),
                  metrics=['accuracy'])
    return model

@tfds.decode.make_decoder(output_dtype=tf.float32)
def decode_image(example, feature):
    return tf.cast(feature.decode_example(example), dtype=tf.float32) / 255

print("TensorFlow version: ", tf.__version__)

strategy = tf.distribute.experimental.MultiWorkerMirroredStrategy()
options = tf.data.Options()
options.experimental_distribute.auto_shard_policy = tf.data.experimental.AutoShardPolicy.OFF

tf_config = os.environ.get('TF_CONFIG', '{}')
print(f"TF_CONFIG [{tf_config}]")
tf_config_json = json.loads(tf_config)
cluster = tf_config_json.get('cluster')
job_name = tf_config_json.get('task', {}).get('type')
task_index = tf_config_json.get('task', {}).get('index')
print(f"cluster=[{cluster}] job_name=[{job_name}] task_index=[{task_index}]")

BATCH_SIZE = 64

tb_dir = '/data/logs'

mnist = tfds.builder('mnist', data_dir='/data/dataset')
mnist.download_and_prepare()

mnist_train, mnist_test = mnist.as_dataset(
    split=['train', 'test'],
    decoders={'image': decode_image()},
    as_supervised=True
)
train_input_dataset = mnist_train.cache().repeat().shuffle(buffer_size=50000).batch(BATCH_SIZE)
# eval_input_dataset = mnist_test.cache().repeat().batch(BATCH_SIZE)

train_input_dataset = train_input_dataset.with_options(options)

# https://www.tensorflow.org/guide/keras/custom_callback
class MyCallback(tf.keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        keys = list(logs.keys())
        print("End epoch {} of training; got log keys: {}".format(epoch, keys))
        
callbacks = [
    tf.keras.callbacks.TensorBoard(log_dir=tb_dir),
    # MyCallback()
]

print("Training...")

with strategy.scope():
    multi_worker_model = build_and_compile_model()

num_train_examples = mnist.info.splits['train'].num_examples
train_steps = num_train_examples // BATCH_SIZE
train_epochs = 3

history = multi_worker_model.fit(
    train_input_dataset, 
    epochs = train_epochs, 
    steps_per_epoch = train_steps, 
    callbacks = callbacks
)

print("\\ntraining_history:", history.history)

os.environ.update({
    'S3_ENDPOINT'          : 'minio-service.kubeflow:9000',
    'AWS_ACCESS_KEY_ID'    : 'minio',
    'AWS_SECRET_ACCESS_KEY': 'minio123',
    'S3_USE_HTTPS'         : '0',                     
    'S3_VERIFY_SSL'        : '0'
})  

MODEL_URI="s3://saved-model/mnist/1"
multi_worker_model.save(MODEL_URI)

