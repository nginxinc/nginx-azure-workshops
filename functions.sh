#!/bin/sh

# Display colorized warning output for 'warnings'
function cwarn() {
	COLOR='\033[01;33m'	# bold yellow
	RESET='\033[00;00m'	# normal white
	STATUS="[WARN]"
	echo -e "${COLOR}${STATUS}${RESET}"
}

# Display colorized failure output for 'failures'
function cfail() {
	COLOR='\033[01;31m'	# bold red
	RESET='\033[00;00m'	# normal white
	STATUS="[FAIL]"
	echo -e "${COLOR}${STATUS}${RESET}"
}

# Display colorized passing output for 'passing'
function cpass() {
        COLOR='\033[01;32m'     # bold green
        RESET='\033[00;00m'     # normal white
        STATUS="[DONE]"
        echo -e "${COLOR}${STATUS}${RESET}"
}

# Display colorized passing output for 'not applicable'
function cnota() {
        COLOR='\033[01;36m'     # bold cyan
        RESET='\033[00;00m'     # normal white
        STATUS="[ NA ]"
        echo -e "${COLOR}${STATUS}${RESET}"
}

# Add padding to maake 80 characters on the line
function padding {
VAR1=$1
PAD=$((74-$VAR1))
for i in $(seq 1 $PAD); do echo -n ' '; done;
}

function azcli_test {
MESSAGE="Check for AZ CLI login"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

SIGNEDIN=`az ad signed-in-user show | jq -r .id`

if [ test -z "$SIGNEDIN" ]; then
	cfail
else
	cpass
fi
}

function setup(){
MESSAGE="Set variables for use in script"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

# This script creates clusters and switches k8s contexts.
# Removing this lock at the start makes things run smoother.
# If you changed the username for Owner you may need to edit this path.

rm -rf /Users/${MY_NAME}/.kube/config.lock
# Workaround on OS X for permissions for kubectl
export KUBECONFIG="~/.kube/config"

# Set some system variables for use in the script.
# you should be logged into azure cli before running this script

export MY_RESOURCEGROUP=${MY_NAME}-n4a-workshop
export MY_AZURE_PUBLIC_IP_NAME=n4a-publicIP # we chose this to standardize names for the workshop
export MY_PUBLICIP=$(curl -s ipinfo.io/ip)
export MY_SUBSCRIPTIONID=$(az account show --query id -o tsv)

if [[ -z "$MY_NAME" || -z "$MY_RESOURCEGROUP" || -z "$MY_PUBLICIP" || -z "$MY_SUBSCRIPTIONID" ]]; then
    cfail
    exit 1
else
    cpass
fi

# Let's display some of these variables so we have it for later.

YELLOW='\033[01;33m'
ENDCOLOR='\033[00;00m'

echo -e "\t${YELLOW}MY_NAME:${ENDCOLOR} $MY_NAME"
echo -e "\t${YELLOW}MY_RESOURCEGROUP:${ENDCOLOR} $MY_RESOURCEGROUP"
echo -e "\t${YELLOW}MY_LOCATION:${ENDCOLOR} $MY_LOCATION"
echo -e "\t${YELLOW}MY_PUBLICIP:${ENDCOLOR} $MY_PUBLICIP"
echo -e "\t${YELLOW}MY_SUBSCRIPTIONID:${ENDCOLOR} $MY_SUBSCRIPTIONID"

}

# Clean up any files from previous run.
function cleanup(){
MESSAGE="Cleanup from previous run"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

if [[ -d "n4a-configs-staging" ]]; then
  rm -r n4a-configs-staging
  cpass
else
  cnota
fi
}

function create_resource_group(){
MESSAGE="Creating Resource Group"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

CREATE_RESOURCE_GROUP=`az group create --name $MY_RESOURCEGROUP --location $MY_LOCATION --tags owner="$MY_NAME"`

if [[ -z "$CREATE_RESOURCE_GROUP" ]]; then
	cfail
else
	cpass
fi
}

function create_vnet(){
MESSAGE="Creating VNet"
LGTH=${#MESSAGE}

CREATE_VNET=`az network vnet create --resource-group $MY_RESOURCEGROUP --name n4a-vnet --address-prefixes 172.16.0.0/16`

if [[ -z "$CREATE_VNET" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_security_group(){
MESSAGE="Creating Network Security Group"
LGTH=${#MESSAGE}

CREATE_SECURITY_GROUP=`az network nsg create --resource-group $MY_RESOURCEGROUP --name n4a-nsg`

if [[ -z "$CREATE_SECURITY_GROUP" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_security_group_rules(){
MESSAGE="Creating NSG rules"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

CREATE_SECURITY_GROUP_RULES1=`az network nsg rule create --resource-group $MY_RESOURCEGROUP --nsg-name n4a-nsg --name HTTP --priority 320 --source-address-prefix $MY_PUBLICIP --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --direction Inbound --access Allow --protocol Tcp --description "Allow HTTP traffic"`
CREATE_SECURITY_GROUP_RULES2=`az network nsg rule create --resource-group $MY_RESOURCEGROUP --nsg-name n4a-nsg --name HTTPS --priority 300 --source-address-prefix $MY_PUBLICIP --source-port-range '*' --destination-address-prefix '*' --destination-port-range 443 --direction Inbound --access Allow --protocol Tcp --description "Allow HTTPS traffic"`
CREATE_SECURITY_GROUP_RULES3=`az network nsg rule create --resource-group $MY_RESOURCEGROUP --nsg-name n4a-nsg --name HTTP_ALT --priority 310 --source-address-prefix $MY_PUBLICIP --source-port-range '*' --destination-address-prefix '*' --destination-port-range 8080 --direction Inbound --access Allow --protocol Tcp --description "Allow HTTPS traffic"`

if [[ -z "$CREATE_SECURITY_GROUP_RULES1" || -z "$CREATE_SECURITY_GROUP_RULES2" || -z "$CREATE_SECURITY_GROUP_RULES3" ]]; then
	echo -ne $MESSAGE
    padding $LGTH
    cfail
else
    echo -ne $MESSAGE
    padding $LGTH
    cpass
fi
}

function create_subnets(){
MESSAGE="Creating Subnets"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

CREATE_SUBNET=`az network vnet subnet create --resource-group $MY_RESOURCEGROUP --name n4a-subnet --vnet-name n4a-vnet --address-prefixes 172.16.1.0/24 --network-security-group n4a-nsg --delegations NGINX.NGINXPLUS/nginxDeployments`
CREATE_VM_SUBNET=`az network vnet subnet create --resource-group $MY_RESOURCEGROUP --name vm-subnet --vnet-name n4a-vnet --address-prefixes 172.16.2.0/24`

CREATE_AKS1_SUBNET=`az network vnet subnet create --resource-group $MY_RESOURCEGROUP --name aks1-subnet --vnet-name n4a-vnet --address-prefixes 172.16.10.0/23`
CREATE_AKS2_SUBNET=`az network vnet subnet create --resource-group $MY_RESOURCEGROUP --name aks2-subnet --vnet-name n4a-vnet --address-prefixes 172.16.20.0/23`

if [[ -z "$CREATE_SUBNET" || -z "$CREATE_VM_SUBNET" || -z "$CREATE_AKS1_SUBNET" || -z "$CREATE_AKS2_SUBNET" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
    cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_public_ip(){
MESSAGE="Creating Public IP"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

CREATE_PUBLIC_IP=`az network public-ip create --name $MY_AZURE_PUBLIC_IP_NAME --resource-group $MY_RESOURCEGROUP --allocation-method Static --sku Standard --location $MY_LOCATION --tags owner="$MY_NAME" --zone 1`

export MY_AZURE_PUBLIC_IP=$(az network public-ip show --resource-group $MY_RESOURCEGROUP --name $MY_AZURE_PUBLIC_IP_NAME --query ipAddress --output tsv)

if [[ -z "$CREATE_PUBLIC_IP" ]]; then
	cfail
else
	cpass
fi
}

function create_identity(){
MESSAGE="Creating Managed Identity"
LGTH=${#MESSAGE}
echo -ne $MESSAGE
padding $LGTH

CREATE_IDENTITY=`az identity create --resource-group $MY_RESOURCEGROUP --name n4a-useridentity`

if [[ -z "$CREATE_IDENTITY" ]]; then
	cfail
else
	cpass
fi
}

function create_n4a_deployment(){
MESSAGE="Creating N4A Deployment"
LGTH=${#MESSAGE}

CREATE_N4A_DEPLOYMENT=`az nginx deployment create --resource-group $MY_RESOURCEGROUP --name nginx4a --sku name="standardv2_Monthly" --network-profile front-end-ip-configuration="{public-ip-addresses:[{id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/publicIPAddresses/n4a-publicIP}]}" network-interface-configuration="{subnet-id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/n4a-vnet/subnets/n4a-subnet}" --identity="{type:'SystemAssigned, UserAssigned',userAssignedIdentities:{/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/n4a-useridentity:{}}}"`
CREATE_N4A_DEPLOYMENT_DIAG=`az nginx deployment update --resource-group $MY_RESOURCEGROUP --name nginx4a --enable-diagnostics true`

export MY_N4A_ID=$(az nginx deployment show --resource-group $MY_RESOURCEGROUP --name nginx4a --query id --output tsv)

if [[ -z "$CREATE_N4A_DEPLOYMENT" || -z "$CREATE_N4A_DEPLOYMENT_DIAG" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_analytics(){
MESSAGE="Creating Log Analytics Monitor"
LGTH=${#MESSAGE}


CREATE_LOG_ANALYTICS=`az monitor log-analytics workspace create --resource-group $MY_RESOURCEGROUP --name n4a-loganalytics`

export MY_LOG_ANALYTICS_ID=`az monitor log-analytics workspace show --resource-group $MY_RESOURCEGROUP --name n4a-loganalytics --query id --output tsv`

CREATE_DIAG_SETTINGS=`az monitor diagnostic-settings create \
--name n4a-nginxlogs \
--resource $MY_N4A_ID \
--logs "[{category:NginxLogs,enabled:true,retention-policy:{enabled:false,days:0}}]" \
--resource-group $MY_RESOURCEGROUP \
--workspace $MY_LOG_ANALYTICS_ID`

if [[ -z "$CREATE_LOG_ANALYTICS" || -z "$CREATE_DIAG_SETTINGS" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
	echo -ne $MESSAGE
    padding $LGTH
    cpass
fi
}

function create_ubuntu_vm(){
MESSAGE="Creating the Ubuntu VM"
LGTH=${#MESSAGE}

ID=`az group show -n $MY_RESOURCEGROUP --query "id" -otsv`

CREATE_UBUNTU_VM=`az vm create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-ubuntuvm \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --vnet-name n4a-vnet \
    --subnet vm-subnet \
    --assign-identity \
    --scope $ID \
    --role Owner \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --custom-data labs/lab2/init.sh \
    --security-type TrustedLaunch \
    --enable-secure-boot true \
    --enable-vtpm true`

export UBUNTU_VM_PUBLICIP=$(az vm show -d -g $MY_RESOURCEGROUP -n n4a-ubuntuvm --query publicIps -o tsv)

# az wants to have a role assignment to grant access, so let's do that here:
VMPRINCIPALID=`az vm show -g $MY_RESOURCEGROUP -n n4a-ubuntuvm --query "identity.principalId" -otsv`
RA=`az role assignment create --assignee $VMPRINCIPALID --role contributor --scope $ID`

if [[ -z "$CREATE_UBUNTU_VM" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function secure_port_22(){
MESSAGE="Securing port 22"
LGTH=${#MESSAGE}

SECURE_PORT_22=`az network nsg rule update \
--resource-group $MY_RESOURCEGROUP \
--nsg-name n4a-ubuntuvmNSG \
--name default-allow-ssh \
--destination-port-ranges 22 \
--source-address-prefix $MY_PUBLICIP`

if [[ -z "$SECURE_PORT_22" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_windows_vm(){
MESSAGE="Creating the Windows VM"
LGTH=${#MESSAGE}

# Set the image we want to use to build this VM
export MY_VM_IMAGE=cognosys:iis-on-windows-server-2016:iis-on-windows-server-2016:1.2019.1009
#export MY_VM_IMAGE=cognosys:iis-on-win-server-2022:iis-on-win-server-2022:0.0.1

CREATE_WINDOWS_VM=`az vm create \
    --only-show-errors \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-windowsvm \
    --image $MY_VM_IMAGE \
    --vnet-name n4a-vnet \
    --subnet vm-subnet \
    --admin-username azureuser \
    --admin-password "Nginxuser@123" \
    --public-ip-sku Standard \
    --security-type Standard`

export WINDOWS_VM_PUBLICIP=$(az vm show -d -g $MY_RESOURCEGROUP -n n4a-windowsvm --query publicIps -o tsv)

if [[ -z "$CREATE_WINDOWS_VM" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function secure_port_3389(){
MESSAGE="Secure port 3389"
LGTH=${#MESSAGE}

CREATE_SECURITY_GROUP_RULES4=`az network nsg rule create --resource-group $MY_RESOURCEGROUP --nsg-name n4a-windowsvmNSG --name RDP --priority 410 --source-address-prefix $MY_PUBLICIP --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --direction Inbound --access Allow --protocol Tcp --description "Allow RDP traffic" --only-show-errors`

if [[ -z "$CREATE_SECURITY_GROUP_RULES4" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

## Lab 3
function create_aks_cluster1(){
# Set some variables to use with this part of the lab setup
export MY_AKS1=n4a-aks1
export MY_AKS2=n4a-aks2
export MY_NAME=${MY_NAME:-$(whoami)}
export K8S_VERSION=1.29
export MY_SUBNET1=$(az network vnet subnet show -g $MY_RESOURCEGROUP -n aks1-subnet --vnet-name n4a-vnet --only-show-errors --query id -o tsv)
export MY_SUBNET2=$(az network vnet subnet show -g $MY_RESOURCEGROUP -n aks2-subnet --vnet-name n4a-vnet --only-show-errors --query id -o tsv)
# This requires that you place your JWT file in the labs/lab3 directory and name it nginx-repo.jwt
export JWT=$(cat labs/lab3/nginx-repo.jwt)

MESSAGE="Creating AKS Cluster 1"
LGTH=${#MESSAGE}

CREATE_AKS_CLUSTER1=`az aks create \
   --only-show-errors \
   --resource-group $MY_RESOURCEGROUP \
   --name $MY_AKS1 \
   --node-count 3 \
   --node-vm-size Standard_B2s \
   --kubernetes-version $K8S_VERSION \
   --tags owner=$MY_NAME \
   --vnet-subnet-id=$MY_SUBNET1 \
   --enable-addons monitoring \
   --generate-ssh-keys`

AKS1_CREDS=`az aks get-credentials --only-show-errors --resource-group $MY_RESOURCEGROUP --name n4a-aks1 --overwrite-existing`

if [[ -z "$CREATE_AKS_CLUSTER1" ]]; then
    echo
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function clone_repo(){

if [ -d kubernetes-ingress/deployments ]; then
  EXISTS=1
  MESSAGE="Use Existing NGINX Ingress Controller Repo"
  LGTH=${#MESSAGE}
else
  CLONE=`git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.3.2`
  cd kubernetes-ingress/deployments
  MESSAGE="Cloning NGINX Ingress Controller Repo"
  LGTH=${#MESSAGE}
fi

if [[ -z "$CLONE" || -z "$EXISTS" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cpass
else
    echo -ne $MESSAGE
    padding $LGTH
	cfail
fi
}

function create_nic_resources1(){

MESSAGE="Creating NGINX Ingress Controller Resources"
LGTH=${#MESSAGE}

CREATE_NIC_RESOURCES1=`kubectl apply -f kubernetes-ingress/deployments/common/ns-and-sa.yaml
kubectl apply -f kubernetes-ingress/deployments/rbac/rbac.yaml
kubectl apply -f kubernetes-ingress/examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f kubernetes-ingress/deployments/common/nginx-config.yaml
kubectl apply -f kubernetes-ingress/deployments/common/ingress-class.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml`

if [[ -z "$CREATE_NIC_RESOURCES1" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_jwt1(){

MESSAGE="Creating Secret for NGINX Plus JWT"
LGTH=${#MESSAGE}

CREATE_JWT1=`kubectl create secret docker-registry regcred \
  --docker-server=private-registry.nginx.com \
  --docker-username=$JWT \
  --docker-password=none \
  -n nginx-ingress`

kubectl get secret regcred -n nginx-ingress -o yaml

if [[ -z "$CREATE_JWT1" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function deploy_nic1(){

MESSAGE="Deploying NGINX Ingress Controller"
LGTH=${#MESSAGE}

DEPLOY_NIC1=`kubectl apply -f labs/lab3/nginx-plus-ingress.yaml`
#kubectl get pods -n nginx-ingress

export AKS1_NIC=$(kubectl get pods -n nginx-ingress -o jsonpath='{.items[0].metadata.name}')

if [[ -z "$DEPLOY_NIC1" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_aks_cluster2(){

MESSAGE="Creating AKS Cluster 2"
LGTH=${#MESSAGE}

CREATE_AKS_CLUSTER2=`az aks create \
    --only-show-errors \
    --resource-group $MY_RESOURCEGROUP \
    --name $MY_AKS2 \
    --node-count 4 \
    --node-vm-size Standard_B2s \
    --kubernetes-version $K8S_VERSION \
    --tags owner=$MY_NAME \
    --vnet-subnet-id=$MY_SUBNET2 \
    --network-plugin azure \
    --enable-addons monitoring \
    --generate-ssh-keys`

AKS2_CREDS=`az aks get-credentials --resource-group $MY_RESOURCEGROUP --name n4a-aks2 --overwrite-existing --only-show-errors`
echo
# switch context for the next section
kubectl config use-context n4a-aks2

if [[ -z "$CREATE_AKS_CLUSTER2" ]]; then
    echo
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_nic_resources2(){

MESSAGE="Creating NGINX Ingress Controller Resources"
LGTH=${#MESSAGE}

CREATE_NIC_RESOURCES2=`kubectl apply -f kubernetes-ingress/deployments/common/ns-and-sa.yaml
kubectl apply -f kubernetes-ingress/deployments/rbac/rbac.yaml
kubectl apply -f kubernetes-ingress/examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f kubernetes-ingress/deployments/common/nginx-config.yaml
kubectl apply -f kubernetes-ingress/deployments/common/ingress-class.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f kubernetes-ingress/deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml`

if [[ -z "$CREATE_NIC_RESOURCES2" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function create_jwt2(){

MESSAGE="Creating Secret for NGINX Plus JWT"
LGTH=${#MESSAGE}

CREATE_JWT2=`kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=$JWT --docker-password=none -n nginx-ingress`
kubectl get secret regcred -n nginx-ingress -o yaml

if [[ -z "$CREATE_JWT2" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function deploy_nic2(){

MESSAGE="Deploying NGINX Ingress Controller"
LGTH=${#MESSAGE}

DEPLOY_NIC2=`kubectl apply -f labs/lab3/nginx-plus-ingress.yaml`
#kubectl get pods -n nginx-ingress

export AKS2_NIC=$(kubectl get pods -n nginx-ingress -o jsonpath='{.items[0].metadata.name}')

if [[ -z "$DEPLOY_NIC2" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

function kubectl_apply(){

MESSAGE="Applying Virtual Server and Dashboards"
LGTH=${#MESSAGE}

kubectl config use-context n4a-aks1 > /dev/null 2>&1 &
kubectl apply -f labs/lab3/dashboard-vs.yaml > /dev/null 2>&1 &
kubectl get svc,vs -n nginx-ingress > /dev/null 2>&1 &
kubectl apply -f labs/lab4/nodeport-static-redis.yaml > /dev/null 2>&1 &
kubectl config use-context n4a-aks2 > /dev/null 2>&1 &
kubectl apply -f labs/lab3/dashboard-vs.yaml > /dev/null 2>&1 &
kubectl get svc,vs -n nginx-ingress > /dev/null 2>&1 &
kubectl apply -f labs/lab4/nodeport-static-redis.yaml > /dev/null 2>&1 &
kubectl config use-context n4a-aks1 > /dev/null 2>&1 &
    echo -ne $MESSAGE
    padding $LGTH
	cpass
}


function create_nsg_rule_aks(){

MESSAGE="Allow traffic to NIC Dashboards"
LGTH=${#MESSAGE}

CREATE_NSG_RULE_AKS=`az network nsg rule create \
--only-show-errors \
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
--description "Allow traffic to NIC Dashboards"`

if [[ -z "$CREATE_NSG_RULE_AKS" ]]; then
    echo -ne $MESSAGE
    padding $LGTH
	cfail
else
    echo -ne $MESSAGE
    padding $LGTH
	cpass
fi
}

## lab 4
function deploy_apps(){

MESSAGE="Deploying Coffe/Tea App and Redis"
LGTH=${#MESSAGE}

kubectl config use-context n4a-aks1 > /dev/null 2>&1 &
kubectl apply -f labs/lab4/cafe.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/cafe-vs.yaml > /dev/null 2>&1 &
kubectl scale deployment coffee --replicas=2 > /dev/null 2>&1 &
kubectl scale deployment tea --replicas=2 > /dev/null 2>&1 &

kubectl config use-context n4a-aks2 > /dev/null 2>&1 &
kubectl apply -f labs/lab4/cafe.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/cafe-vs.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/redis-leader.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/redis-follower.yaml > /dev/null 2>&1 &
#kubectl get pods,svc -l app=redis
kubectl apply -f labs/lab4/global-configuration-redis.yaml > /dev/null 2>&1 &
kubectl describe gc nginx-configuration -n nginx-ingress > /dev/null 2>&1 &
kubectl apply -f labs/lab4/redis-leader-ts.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/redis-follower-ts.yaml > /dev/null 2>&1 &
kubectl apply -f labs/lab4/nodeport-static-redis.yaml > /dev/null 2>&1 &
rm -rf /Users/${MY_NAME}/.kube/config.lock

    echo -ne $MESSAGE
    padding $LGTH
	  cpass
}
#kubectl get svc -n nginx-ingress

function get_node_ids(){

MESSAGE="Get Node IDs and update configs"
LGTH=${#MESSAGE}

kubectl config use-context n4a-aks1
export AKS1_NODE_NUMBER=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}" | cut -d- -f 3)

kubectl config use-context n4a-aks2
export AKS2_NODE_NUMBER=$(kubectl get nodes -o jsonpath="{.items[0].metadata.name}" | cut -d- -f 3)

cp -r n4a-configs/ n4a-configs-staging/
sed -i '' 's/_AKS1_NODES_/'$AKS1_NODE_NUMBER'/g' n4a-configs-staging/etc/nginx/conf.d/aks1-upstreams.conf
sed -i '' 's/_AKS2_NODES_/'$AKS2_NODE_NUMBER'/g' n4a-configs-staging/etc/nginx/conf.d/aks2-upstreams.conf
sed -i '' 's/_AKS1_NODES_/'$AKS1_NODE_NUMBER'/g' n4a-configs-staging/etc/nginx/conf.d/nic1-dashboard-upstreams.conf
sed -i '' 's/_AKS2_NODES_/'$AKS2_NODE_NUMBER'/g' n4a-configs-staging/etc/nginx/conf.d/nic2-dashboard-upstreams.conf

echo -ne $MESSAGE
padding $LGTH
cpass
}

function create_archive(){
MESSAGE="Creating the archive"
LGTH=${#MESSAGE}

cd n4a-configs-staging
COPYFILE_DISABLE=1 tar --exclude='.DS_Store' -czf ../n4a-configs.tar.gz *
cd ..
rm -r n4a-configs-staging

echo -ne $MESSAGE
padding $LGTH
cpass
}

function upload_archive(){

MESSAGE="Prepare and upload archive package"
LGTH=${#MESSAGE}

export B64_N4A_CONFIG=$(base64 -i n4a-configs.tar.gz | tr -d '\n')
cat << EOF > package.json
{
"data": "$B64_N4A_CONFIG"
}
EOF

PACKAGE=`az nginx deployment configuration create \
  --configuration-name default \
  --deployment-name nginx4a \
  --resource-group $MY_RESOURCEGROUP \
  --root-file var/nginx.conf \
  --package "@package.json"`

if [[ -z "$PACKAGE" ]]; then
  echo -ne $MESSAGE
  padding $LGTH
	cfail
else
  echo -ne $MESSAGE
  padding $LGTH
	cpass
fi
}

function update_hosts_file(){

MESSAGE="Updating hosts file with Azure Public IP"
LGTH=${#MESSAGE}

HOST="cafe.example.com bar.example.com dashboard.example.com grafana.example.com prometheus.example.com juiceshop.example.com redis.example.com"
sudo sed -i '' '/cafe.example.com/ s/.*/'"$MY_AZURE_PUBLIC_IP"'\t'"$HOST"'/g' /etc/hosts

echo -ne $MESSAGE
padding $LGTH
cpass
}

function delete(){
MESSAGE="Resource Group Deletion"
LGTH=${#MESSAGE}

# This will remove the resource group and everything in it.  It will prompt for confirmation.
az group delete --name $MY_RESOURCEGROUP

    echo -ne $MESSAGE
    padding $LGTH
	cpass
}

function display(){
# Display more variable values that we used in the script.
# Per instructions, copy output and pastr back to teh terminal so we have these moving forward.
cat <<EOI
export MY_N4A_ID=$MY_N4A_ID
export MY_LOG_ANALYTICS_ID=$MY_LOG_ANALYTICS_ID
export AKS1_NIC=$AKS1_NIC
export AKS2_NIC=$AKS2_NIC
export MY_NAME=$MY_NAME
export MY_RESOURCEGROUP=$MY_RESOURCEGROUP
export MY_LOCATION=$MY_LOCATION
export MY_PUBLICIP=$MY_PUBLICIP
export MY_SUBSCRIPTIONID=$MY_SUBSCRIPTIONID
export MY_AZURE_PUBLIC_IP=$MY_AZURE_PUBLIC_IP
export UBUNTU_VM_PUBLICIP=$UBUNTU_VM_PUBLICIP
export WINDOWS_VM_PUBLICIP=$WINDOWS_VM_PUBLICIP

Copy the export statements and paste them into your terminal (so the variables exist outside the script.)

Access the Ubuntu VM with: ssh azureuser@$UBUNTU_VM_PUBLICIP
Access the Windows VM by using RDP to host: $WINDOWS_VM_PUBLICIP with user: azureuser and password: Nginxuser@123
EOI
}