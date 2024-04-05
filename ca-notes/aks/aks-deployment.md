akker# az aks create      --resource-group $MY_RESOURCEGROUP      --name $MY_AKS      --location $MY_LOCATION      --node-count 3      --node-vm-size $AKS_NODE_VM      --kubernetes-version $K8S_VERSION      --tags owner=$MY_NAME      --enable-addons monitoring      --generate-ssh-keys      --enable-fips-image


--vnet-subnet-id <YOUR_SUBNET_RESOURCE_ID>
--vnet-subnet-id /subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/cakker/providers/Microsoft.Network/virtualNetworks/demo1-vnet/subnets/aks

/subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/cakker/providers/Microsoft.Network/virtualNetworks/demo1-vnet/subnets/aks2


Second cluster, using azure CNI and new "aks2" subnet, as $MY_SUBNET :

az aks create --resource-group $MY_RESOURCEGROUP --name $MY_AKS --location $MY_LOCATION --node-count 3 --node-vm-size $AKS_NODE_VM --kubernetes-version $K8S_VERSION --tags owner=$MY_NAME --vnet-subnet-id=$MY_SUBNET --network-plugin option: azure --enable-addons monitoring --generate-ssh-keys --enable-fips-image
