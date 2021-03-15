#!/bin/bash

kubectl apply -f - << EOMFST
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
