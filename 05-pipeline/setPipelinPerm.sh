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
---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRoleBinding 
metadata:
  # name: bind-ml-pipeline-nb-mynamespace
  name: bind-ml-pipeline-nb-ns-${NAMESPACE}
  namespace: kubeflow
spec:
  roleRef:
    kind: ServiceRole
    name: ml-pipeline-services
  subjects:
  - properties:
      source.principal: cluster.local/ns/${NAMESPACE}/sa/default-editor
  - properties:
      source.principal: cluster.local/ns/${NAMESPACE}/sa/pipeline-runner
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  annotations:
    role: edit
    user: ${USERID}
  name: user-${NMESC}-clusterrole-edit
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubeflow-edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${USERID}
---
apiVersion: rbac.istio.io/v1alpha1
kind: ServiceRoleBinding
metadata:
  annotations:
    role: edit
    user: ${USERID}
  name: user-${NMESC}-clusterrole-edit
  namespace: ${NAMESPACE}
spec:
  roleRef:
    kind: ServiceRole
    name: ns-access-istio
  subjects:
  - properties:
      request.headers[kubeflow-userid]: ${USERID}
EOMFST
