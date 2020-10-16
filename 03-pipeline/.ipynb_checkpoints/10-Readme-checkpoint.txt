1. read kubeflow visualize page

1-1. minio tensorboard bucket
1-2. create secret
1-3. create configmap
     kubectl -n kubeflow create -f viewer-tensorboard-template-configmap.yaml
1-4. kubectl -n kubeflow edit deployment ml-pipeline-ui
