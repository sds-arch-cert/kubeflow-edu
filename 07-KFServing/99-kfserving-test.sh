MODEL_NAME=covid19
# TEST_JSON="../01-prerequisite/image_data.json"
TEST_JSON=$1

# Jupyter Notebook Terminal (K8s 내부)에서 실행 시
INGRESS_HOST=kfserving-ingressgateway.istio-system
INGRESS_PORT=80

# K8s 외부 실행 시
# INGRESS_HOST=<VM 외부 IP>
# INGRESS_PORT=32380

SERVICE_HOSTNAME=$(kubectl get inferenceservice -n myspace $MODEL_NAME -o jsonpath='{.status.url}' | cut -d "/" -f 3)
SERVING_URL=http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/$MODEL_NAME:predict

curl -v -H "Host: ${SERVICE_HOSTNAME}" ${SERVING_URL} -d @${TEST_JSON}
