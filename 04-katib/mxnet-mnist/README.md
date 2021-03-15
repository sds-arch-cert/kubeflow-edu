# Katib 실습

원본: [katib/examples/v1beta1/mxnet-mnist at master · kubeflow/katib (github.com)](https://github.com/kubeflow/katib/tree/master/examples/v1beta1/mxnet-mnist)

#### Mxnet image classification example

This is Mxnet image classification training container with recording time of the metrics.

It uses only simple multilayer perceptron network (mlp).

If you want to read more about this example, visit official [incubator-mxnet](https://github.com/apache/incubator-mxnet/tree/master/example/image-classification) github repository.

# 실행 준비

## Docker build

Katib을 실행할 로직을 Dockerizing.

Docker Hub에 사전에 repository를 만들고 진행 (아래 예에서는 reddiana/katib-mxnet-mnist)

Jupyter notebook Terminal에서는 docker 명령을 실행할 수 없으므로 VM에서 실행한다.

```bash
docker build -t reddiana/katib-mxnet-mnist .
docker push reddiana/katib-mxnet-mnist
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
                image: reddiana/katib-mxnet-mnist
                command:
                  ...생략...
```

#### Namespace 수정

권한이 있는 Namespace로 변경 (아래 예에서는 myspace)

```yaml
apiVersion: "kubeflow.org/v1beta1"
kind: Experiment
metadata:
  namespace: myspace
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
kubectl apply -f random-example.yaml
```

## 방법2. Katib UI - YAML File

- Kubeflow 포털 > Katib > Katib 햄버거메뉴 > HP > Submit > YAML File 탭
  - Textarea에 random-example.yaml 내용을 복붙
  - 화면 하단 DEPLOY 버튼 클릭

## 방법3. Katib UI - Parameters

- Kubeflow 포털 > Katib > Katib 햄버거메뉴 > Trial Manifests
  - ADD TEMPLATE 클릭
    - New ConfigMap 체크
    - Namespace: myspace
    - Name: my-new-trial-template
    - Template ConfigMap Path: myTrialTemplate
    - Textarea: random-example.yaml에서 trialSpec 하위 부분을 복붙
- Kubeflow 포털 > Katib > Katib 햄버거메뉴 > HP > Submit > Parameters 탭
  - Name: random-experiment-<중복 없도록 순번 등을 append> 
  - Namespace: myspace
  - Common Parameters, Objective, Algorithm, Parameters: random-example.yaml의 내용 참고
  - Trial Template Spec
    - ConfigMap Namespace and Name
      - Namespace: myspace
      - Name: my-new-trial-template
    - Trial Template ConfigMap Path: myTrialTemplate
    - 나머지: random-example.yaml의 내용 참고
  - 화면 하단 DEPLOY 버튼 클릭

## 실행 확인

#### Katib UI > Monitoring

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

