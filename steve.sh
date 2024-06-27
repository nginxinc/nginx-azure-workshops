#!/usr/bin/env bash

export OWNER=$(whoami)

export MY_RESOURCEGROUP=${OWNER}-n4a-workshop
export LOCATION=westus2
export MY_PUBLICIP=$(curl ipinfo.io/ip)
export MY_SUBSCRIPTIONID=$(az account show --query id -o tsv)
export MY_AZURE_PUBLIC_IP_NAME=n4a-publicIP

cat <<EOI
OWNER: $OWNER
MY_RESOURCEGROUP: $MY_RESOURCEGROUP
LOCATION: $LOCATION
MY_PUBLICIP: $MY_PUBLICIP
MY_SUBSCRIPTIONID: $MY_SUBSCRIPTIONID
EOI

## Clean up previous run...

if [ -d "n4a-configs-staging" ]; then
  rm -r n4a-configs-staging
fi

## Lab 1

echo
echo "--> Creating Resource Group..."
az group create --name $MY_RESOURCEGROUP --location $LOCATION --tags owner=$OWNER

## az group list -o table | grep workshop

echo
echo "--> Creating VNet..."
az network vnet create \
--resource-group $MY_RESOURCEGROUP \
--name n4a-vnet \
--address-prefixes 172.16.0.0/16

echo
echo "--> Creating Network Security Group..."
az network nsg create \
--resource-group $MY_RESOURCEGROUP \
--name n4a-nsg

echo
echo "--> Creating NSG Rules..."
az network nsg rule create \
--resource-group $MY_RESOURCEGROUP \
--nsg-name n4a-nsg \
--name HTTP \
--priority 320 \
--source-address-prefix $MY_PUBLICIP \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 80 \
--direction Inbound \
--access Allow \
--protocol Tcp \
--description "Allow HTTP traffic"

az network nsg rule create \
--resource-group $MY_RESOURCEGROUP \
--nsg-name n4a-nsg \
--name HTTPS \
--priority 300 \
--source-address-prefix $MY_PUBLICIP \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 443 \
--direction Inbound \
--access Allow \
--protocol Tcp \
--description "Allow HTTPS traffic"

az network nsg rule create \
--resource-group $MY_RESOURCEGROUP \
--nsg-name n4a-nsg \
--name HTTP_ALT \
--priority 310 \
--source-address-prefix $MY_PUBLICIP \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 8080 \
--direction Inbound \
--access Allow \
--protocol Tcp \
--description "Allow HTTPS traffic"

echo
echo "--> Creating Subnet ..."
az network vnet subnet create \
--resource-group $MY_RESOURCEGROUP \
--name n4a-subnet \
--vnet-name n4a-vnet \
--address-prefixes 172.16.1.0/24 \
--network-security-group n4a-nsg \
--delegations NGINX.NGINXPLUS/nginxDeployments

echo
echo "--> Creating Subnet for AKS Cluster One..."
az network vnet subnet create \
--resource-group $MY_RESOURCEGROUP \
--name aks1-subnet \
--vnet-name n4a-vnet \
--address-prefixes 172.16.10.0/23

echo
echo "--> Creating Subnet for AKS Cluster Two..."
az network vnet subnet create \
--resource-group $MY_RESOURCEGROUP \
--name aks2-subnet \
--vnet-name n4a-vnet \
--address-prefixes 172.16.20.0/23

echo
echo "--> Creating Public IP..."
az network public-ip create \
--resource-group $MY_RESOURCEGROUP \
--name $MY_AZURE_PUBLIC_IP_NAME \
--allocation-method Static \
--sku Standard

echo
echo "--> Caching Public Azure IP..."
export MY_AZURE_PUBLIC_IP=$(az network public-ip show --resource-group $MY_RESOURCEGROUP --name $MY_AZURE_PUBLIC_IP_NAME --query ipAddress --output tsv)

echo
echo "--> Creating Identity..."
az identity create \
--resource-group $MY_RESOURCEGROUP \
--name n4a-useridentity

echo
echo "--> Creating N4A Deployment..."
az nginx deployment create \
--resource-group $MY_RESOURCEGROUP \
--name nginx4a \
--sku name="standard_Monthly" \
--network-profile front-end-ip-configuration="{public-ip-addresses:[{id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/publicIPAddresses/n4a-publicIP}]}" network-interface-configuration="{subnet-id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/n4a-vnet/subnets/n4a-subnet}" \
--identity="{type:'SystemAssigned, UserAssigned',userAssignedIdentities:{/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/n4a-useridentity:{}}}"

echo
echo "--> Creating Log Analytics Monitor..."
az monitor log-analytics workspace create \
--resource-group $MY_RESOURCEGROUP \
--name n4a-loganalytics

echo
echo "--> Updating N4A Deployment to enable diagnostics... "
az nginx deployment update \
--resource-group $MY_RESOURCEGROUP \
--name nginx4a \
--enable-diagnostics true

echo
echo "--> Caching the N4A Id... "
export MY_N4A_ID=$(az nginx deployment show \
--resource-group $MY_RESOURCEGROUP \
--name nginx4a \
--query id \
--output tsv)

echo
echo "--> Caching the Analytics Id... "
export MY_LOG_ANALYTICS_ID=$(az monitor log-analytics workspace show \
--resource-group $MY_RESOURCEGROUP \
--name n4a-loganalytics \
--query id \
--output tsv)

echo
echo "--> Creating Diagnostics Setting..."
az monitor diagnostic-settings create \
--resource $MY_N4A_ID \
--name n4a-nginxlogs \
--resource-group $MY_RESOURCEGROUP \
--workspace $MY_LOG_ANALYTICS_ID \
--logs "[{category:NginxLogs,enabled:true,retention-policy:{enabled:false,days:0}}]"

## Lab 3

export MY_AKS1=n4a-aks1
export MY_AKS2=n4a-aks2
export MY_NAME=${OWNER:-$(whoami)}
export K8S_VERSION=1.27
export MY_SUBNET1=$(az network vnet subnet show -g $MY_RESOURCEGROUP -n aks1-subnet --vnet-name n4a-vnet --query id -o tsv)
export MY_SUBNET2=$(az network vnet subnet show -g $MY_RESOURCEGROUP -n aks2-subnet --vnet-name n4a-vnet --query id -o tsv)
source ~/nginx-trial.jwt

echo
echo "--> Creating AKS Cluster One..."
az aks create \
   --resource-group $MY_RESOURCEGROUP \
   --name $MY_AKS1 \
   --node-count 3 \
   --node-vm-size Standard_B2s \
   --kubernetes-version $K8S_VERSION \
   --tags owner=$MY_NAME \
   --vnet-subnet-id=$MY_SUBNET1 \
   --enable-addons monitoring \
   --generate-ssh-keys

echo
echo "--> Getting the credentials for AKS Cluster One..."
az aks get-credentials \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-aks1 \
    --overwrite-existing

echo
echo "--> Cloning the NGINX Ingress Controller Repo..."
git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.3.2
cd kubernetes-ingress/deployments

echo
echo "--> Creating NGINX Ingress Controller Resources ..."
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml
kubectl apply -f ../examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/ingress-class.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml

cd -

echo
echo "--> Creating Secret for NGINX Plus JWT..."
kubectl create secret docker-registry regcred \
  --docker-server=private-registry.nginx.com \
  --docker-username=$JWT \
  --docker-password=none \
  -n nginx-ingress

kubectl get secret regcred -n nginx-ingress -o yaml

echo
echo "--> Deploying NGINX Ingress Controller ..."
kubectl apply -f labs/lab3/nginx-plus-ingress.yaml

kubectl get pods -n nginx-ingress

echo
echo "--> Caching the AKS1 NIC ..."
export AKS1_NIC=$(kubectl get pods -n nginx-ingress -o jsonpath='{.items[0].metadata.name}')

echo
echo "--> Creating AKS Cluster Two..."
az aks create \
    --resource-group $MY_RESOURCEGROUP \
    --name $MY_AKS2 \
    --node-count 4 \
    --node-vm-size Standard_B2s \
    --kubernetes-version $K8S_VERSION \
    --tags owner=$MY_NAME \
    --vnet-subnet-id=$MY_SUBNET2 \
    --network-plugin azure \
    --enable-addons monitoring \
    --generate-ssh-keys

echo
echo "--> Getting the credentials for AKS Cluster Two..."
az aks get-credentials \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-aks2 \
    --overwrite-existing

kubectl config use-context n4a-aks2
kubectl get nodes

cd kubernetes-ingress/deployments

echo
echo "--> Creating NGINX Ingress Controller Resources..."
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml
kubectl apply -f ../examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/ingress-class.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml

cd -

echo
echo "--> Creating Secret for NGINX Plus JWT..."
kubectl create secret docker-registry regcred \
  --docker-server=private-registry.nginx.com \
  --docker-username=$JWT \
  --docker-password=none \
  -n nginx-ingress

kubectl get secret regcred -n nginx-ingress -o yaml

kubectl apply -f labs/lab3/nginx-plus-ingress.yaml

echo
echo "--> Deploying the NGINX Ingress Controller ..."
kubectl get pods -n nginx-ingress

echo
echo "--> Caching the AKS2 NIC..."
export AKS2_NIC=$(kubectl get pods -n nginx-ingress -o jsonpath='{.items[0].metadata.name}')

kubectl config use-context n4a-aks1
kubectl apply -f labs/lab3/dashboard-vs.yaml
kubectl get svc,vs -n nginx-ingress

kubectl config use-context n4a-aks2
kubectl apply -f labs/lab3/dashboard-vs.yaml
kubectl get svc,vs -n nginx-ingress

kubectl config use-context n4a-aks1
kubectl apply -f labs/lab4/nodeport-static-redis.yaml
kubectl get svc nginx-ingress -n nginx-ingress


kubectl config use-context n4a-aks2
kubectl apply -f labs/lab4/nodeport-static-redis.yaml
kubectl get svc nginx-ingress -n nginx-ingress


kubectl config use-context n4a-aks1
kubectl get nodes

az network nsg rule create \
--resource-group $MY_RESOURCEGROUP \
--nsg-name n4a-nsg \
--name NIC_Dashboards \
--priority 330 \
--source-address-prefix $MY_PUBLICIP \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 9001-9002 \
--direction Inbound \
--access Allow \
--protocol Tcp \
--description "Allow traffic to NIC Dashboards"

## lab 4

kubectl config use-context n4a-aks1
kubectl apply -f labs/lab4/cafe.yaml
kubectl apply -f labs/lab4/cafe-vs.yaml
kubectl scale deployment coffee --replicas=2
kubectl scale deployment tea --replicas=2

kubectl config use-context n4a-aks2
kubectl apply -f labs/lab4/cafe.yaml
kubectl apply -f labs/lab4/cafe-vs.yaml

kubectl config use-context n4a-aks2
kubectl apply -f labs/lab4/redis-leader.yaml
kubectl apply -f labs/lab4/redis-follower.yaml

kubectl get pods,svc -l app=redis

kubectl apply -f labs/lab4/global-configuration-redis.yaml
kubectl describe gc nginx-configuration -n nginx-ingress

kubectl apply -f labs/lab4/redis-leader-ts.yaml
kubectl apply -f labs/lab4/redis-follower-ts.yaml

kubectl get transportserver

kubectl config use-context n4a-aks2
kubectl apply -f labs/lab4/nodeport-static-redis.yaml

kubectl get svc -n nginx-ingress

echo
echo "--> Getting the Node Ids for the AKS1 Cluster..."

kubectl config use-context n4a-aks1
export AKS1_NODE_NUMBER=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}" | cut -d- -f 3)

echo
echo "--> Getting the Node Ids for the AKS2 Cluster..."

kubectl config use-context n4a-aks2
export AKS2_NODE_NUMBER=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}" | cut -d- -f 3)

echo
echo "--> Update n4a configs..."

cp -r n4a-configs/ n4a-configs-staging/
sed -i "s/_AKS1_NODES_/$AKS1_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/aks1-upstreams.conf
sed -i "s/_AKS2_NODES_/$AKS2_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/aks2-upstreams.conf
sed -i "s/_AKS1_NODES_/$AKS1_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/nic1-dashboard-upstreams.conf
sed -i "s/_AKS2_NODES_/$AKS2_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/nic2-dashboard-upstreams.conf
sed -i "s/_AKS2_NODES_/$AKS2_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/the-garage-upstreams.conf
sed -i "s/_AKS2_NODES_/$AKS2_NODE_NUMBER/g" n4a-configs-staging/etc/nginx/conf.d/my-garage-upstreams.conf

echo
echo "--> Creating the archive..."
cd n4a-configs-staging
tar -czf ../n4a-configs.tar.gz *
cd ..
rm -r n4a-configs-staging

echo
echo "--> Prepare the upload package..."
export B64_N4A_CONFIG=$(base64 -i n4a-configs.tar.gz | tr -d '\n')
cat << EOF > package.json
{
"data": "$B64_N4A_CONFIG"
}
EOF

echo
echo "--> Uploading the configuration..."
az nginx deployment configuration create \
  --configuration-name default \
  --deployment-name nginx4a \
  --resource-group $MY_RESOURCEGROUP \
  --root-file var/nginx.conf \
  --package "@package.json"

echo
echo "--> Updating the hosts file with the new Azure Public IP..."
sudo sed -i "/N4AWSEX/{n;s/^[^ ]*/$MY_AZURE_PUBLIC_IP/}" /etc/hosts

cat <<EOI
export MY_N4A_ID=$MY_N4A_ID
export MY_LOG_ANALYTICS_ID=$MY_LOG_ANALYTICS_ID
export AKS1_NIC=$AKS1_NIC
export AKS2_NIC=$AKS2_NIC
export OWNER=$OWNER
export MY_RESOURCEGROUP=$MY_RESOURCEGROUP
export LOCATION=$LOCATION
export MY_PUBLICIP=$MY_PUBLICIP
export MY_SUBSCRIPTIONID=$MY_SUBSCRIPTIONID
export MY_AZURE_PUBLIC_IP=$MY_AZURE_PUBLIC_IP
EOI
