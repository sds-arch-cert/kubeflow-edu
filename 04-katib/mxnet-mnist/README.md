# Katib 실습

원본: [katib/examples/v1beta1/mxnet-mnist at master · kubeflow/katib (github.com)](https://github.com/kubeflow/katib/tree/master/examples/v1beta1/)

#### Mxnet image classification example

This is Mxnet image classification training container with recording time of the metrics.

It uses only simple multilayer perceptron network (mlp).

If you want to read more about this example, visit official [incubator-mxnet](https://github.com/apache/incubator-mxnet/tree/master/example/image-classification) github repository.

# 실행 준비

## Docker build

Katib을 실행할 로직을 Dockerizing.

Docker Hub에 사전에 repository를 만들거나 private image registry에서 진행 (아래 예에서는 myhost.local:32000/katib-mxnet-mnist)

Jupyter notebook Terminal에서는 docker 명령을 실행할 수 없으므로 VM에서 실행한다.

```bash
sudo docker build -t myhost.local:32000/katib-mxnet-mnist .
sudo docker push myhost.local:32000/katib-mxnet-mnist
```

## Experiment Manifest Yaml 수정

random-example.yaml을 수정한다

#### 실행 Image 수정

Katib을 실행할 로직이 Dockerzing 되어있는 Image로 수정 (아래 예에서는 reddiana/katib-mxnet-mnist)

```yaml
...생략...
  trialTemplate:
    ...생략...
    trialSpec:
      ...생략...
      spec:
        template:
          ...생략...
          spec:
            containers:
              - name: training-container
                image: myhost.local:32000/katib-mxnet-mnist
                command:
                  ...생략...
```

#### Namespace 수정

권한이 있는 Namespace로 변경 (아래 예에서는 myspace)

```yaml
apiVersion: "kubeflow.org/v1beta1"
kind: Experiment
metadata:
  name: random-example
spec:
  objective:       
    ...생략...
```

#### Istio sidecar injection 해제

Katib Experiment는 Istio sidecar injection 된 상태에서는 정상동작하지 않음.

다음과 같이 Istio sidecar injection을 false로 설정

```yaml
...생략...
  trialTemplate:
    ...생략...
    trialSpec:
      ...생략...
      spec:
        template:
          metadata:
            annotations:
              sidecar.istio.io/inject: "false"
          spec:
            containers:
              ...생략...
```

# 실행

## 방법1. kubectl apply

```bash
kubectl apply -f random-example.yaml -n <your namespace>
```

## 방법2. Katib UI 

- Kubeflow 포털 > Katib > Katib 햄버거메뉴 > Trial Manifests
- Kubeflow Dashboard > Experiments(AutoML) > NEW EXPERIMENT 

1. Metadata
    - Name: katib-mxnet-mnist-experiment
2. Trial Thresholds: default
3. Objective:
    - Type: Maximize
    - Metric: Validation-accuracy: 0.97
    
4. Search Algorithm
    - Hyper Parameter Turning: Random 또는 Grid

5. Early Stopping: default
6. Hyper Parameters
    - lr: default
    - num-layers: 
      - min: 2
      - max: 5
      - optimizer: default
7. Metrics Collector: Stdout
8. Trial Template
    - Katib 로 실행할 Trial 을 설정하는 단계
    - Source type: ConfigMap 
      - YAML: Trial 의 YAML 을 직접 등록하여 사용
      - ConfigMap: 미리 Trial Template 을 Configmap 에 등록한 경우 사용
    - Trial Template YAML 의 변수를 6. Hyper parameters 단계 에서 설정한 값으로 입력
      - learingRate: lr
      - numberLayers: num-layers
      - optimizer: optimizer

CREATE 클릭하여 Katib 실행


## 실행 확인

#### Katib Dashbard

#### Katib 관련 K8s resource dependencies 예

- experiment.kubeflow.org/random-experiment-2
  - suggestion.kubeflow.org/random-experiment-2
    - service/random-experiment-2-random
    - deployment.apps/random-experiment-2-random
      - replicaset.apps/random-experiment-2-random-77dd7d79b
        - pod/random-experiment-2-random-77dd7d79b-sszcg
  - trial.kubeflow.org/random-experiment-2-ctcv7lbq
    - job.batch/random-experiment-2-ctcv7lbq
      - pod/random-experiment-2-ctcv7lbq-78m7t
  - trial.kubeflow.org/random-experiment-2-kvc2tcpz
    - job.batch/random-experiment-2-kvc2tcpz
      - pod/random-experiment-2-kvc2tcpz-ch7z9
  - trial.kubeflow.org/random-experiment-2-w4st4xt5
    - job.batch/random-experiment-2-w4st4xt5
      - pod/random-experiment-2-w4st4xt5-mv8qg

