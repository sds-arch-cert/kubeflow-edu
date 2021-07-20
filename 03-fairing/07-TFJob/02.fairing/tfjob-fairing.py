from kubeflow import fairing
from kubeflow.fairing.kubernetes import utils as k8s_utils
import uuid

fairing.config.set_preprocessor(
    'notebook', 
    notebook_file = 'mnist-dist.ipynb',
)

PRIVATE_REGISTRY = 'registry.kube-system.svc.cluster.local:30000'
# base_image=f'{PRIVATE_REGISTRY}/mymnistbase'
base_image='reddiana/mybase'
fairing.config.set_builder(
    'append',
    base_image=base_image,
    registry = PRIVATE_REGISTRY,
    image_name='tfjob-fairing-mnist', 
    push=True,
)

fairing.config.set_deployer(
    'tfjob',
    # namespace='mysapce', # 생략 시 현재 노트북의 네임스페이스 사용
    job_name=f'my-mnist-{uuid.uuid4().hex[:8]}',
    chief_count=1, 
    worker_count=2,
    pod_spec_mutators=[
        # k8s_utils.mounting_pvc(pvc_name='mnist-tfjob-data-volume', pvc_mount_path='/data'),
        k8s_utils.get_resource_mutator(cpu=0.5, memory=2),
    ]
)

fairing.config.run()