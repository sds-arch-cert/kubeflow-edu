#!/bin/bash

USERID=anonymous@kubeflow.org

NOTEBOOKNAME=$(echo $NB_PREFIX | awk -F '/' '{print $4}')
NAMESPACE=$(cat /run/secrets/kubernetes.io/serviceaccount/namespace)
NMESC=$(echo ${USERID} | sed 's/[\.@]/-/g')


mkdir -p ~/.config/kfp
cat > ~/.config/kfp/context.json << EOJ
{"namespace": "${NAMESPACE}"}
EOJ

# kubectl get envoyfilter -ojson | jq '
#   .items[0] 
#   | select(.spec.workloadSelector.labels."notebook-name"=="'$NOTEBOOKNAME'") 
#   | .metadata.name'

kubectl apply -f - << EOMFST
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: add-header-user-${NMESC}-nb-ns-${NOTEBOOKNAME}
  namespace: ${NAMESPACE}
spec:
  configPatches:
  - applyTo: VIRTUAL_HOST
    match:
      context: SIDECAR_OUTBOUND
      routeConfiguration:
        vhost:
          name: ml-pipeline.kubeflow.svc.cluster.local:8888
          route:
            name: default
    patch:
      operation: MERGE
      value:
        request_headers_to_add:
        - append: true
          header:
            key: kubeflow-userid
            value: ${USERID}
  workloadSelector:
    labels:
      notebook-name: ${NOTEBOOKNAME}
EOMFST
