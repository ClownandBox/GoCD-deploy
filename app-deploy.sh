如果您只想部署 nginx-deployment，可以简化脚本，去掉与服务和 Ingress 相关的部分。以下是修改后的脚本，仅保留部署 nginx-deployment 的逻辑：

bash
#!/usr/bin/env bash

# 替换镜像名称和标签
sed -i "s~#{image}~$IMAGE_NAME:$IMAGE_TAG~g" nginx-deployment.json

# 检查环境变量
if [ -z "$KUBE_TOKEN" ]; then
  echo "FATAL: Environment Variable KUBE_TOKEN must be specified."
  exit 1
fi

if [ -z "$NAMESPACE" ]; then
  echo "FATAL: Environment Variable NAMESPACE must be specified."
  exit 1
fi

echo
echo "Namespace: $NAMESPACE"

# 检查部署是否存在
status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments/$DEPLOYMENT_NAME" \
    -X GET -o /dev/null -w "%{http_code}")

if [ "$status_code" == 200 ]; then
  echo
  echo "Updating deployment"
  curl --fail -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments/$DEPLOYMENT_NAME" \
    -X PATCH -d @nginx-deployment.json
else
  echo
  echo "Creating deployment"
  curl --fail -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments" \
    -X POST -d @nginx-deployment.json
fi