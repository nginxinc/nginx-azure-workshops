## Azure CLI Basic Configuration Setting

You will need Azure Command Line Interface (CLI) installed on your client machine to manage your Azure services. See [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

If you do not have Azure CLI installed, you will need to install it to continue with the lab exercises.  To check Azure CLI version run below command:

```bash
az --version
```

1. Sign in with Azure CLI using your preferred method listed [here](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).

   >**Note:** We made use of Sign in interactively method for this workshop

    ```bash
    az login
    ```

1. Once you have logged in you can run below command to validate your tenent and subscription ID and name.

   ```bash
   az account show 
   ```

1. Optional: If you have multiple subscriptions and would like to change the current subscription to another then run below command.

   ```bash
   # change the active subscription using the subscription name
   az account set --subcription "{subscription name}"

   # OR

   # change the active subscription using the subscription ID
   az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  
   ```

1. Create a new Azure Resource Group called `<name>-workshop` , where `<name>` is your last name (or any unique value).  This would hold all the Azure resources that you would create for this workshop.
  
   ```bash
   az group create --name <name>-workshop --location <MY_Location>

   ## example
   az group create --name s.dutta-workshop --location centralus
   ```

1. Make sure the new Azure Resource Group has been created by running below command.

   ```bash
   az group list -o table | grep workshop
   ```

## Create Virtual Network, Subnets and Network Security Group

1. Create a virtual network (vnet) named `n4a-vnet` using below command.

    ```bash
    ## Set environment variables
    MY_RESOURCEGROUP=s.dutta-workshop
    MY_PUBLICIP=$(curl -4 ifconfig.co)
    ```

    ```bash
    az network vnet create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-vnet \
    --address-prefixes 10.0.0.0/16
    ```

1. Create a network security group(NSG) named `n4a-nsg` using below command.

    ```bash
    az network nsg create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-nsg
    ```

1. Add two NSG rules to allow any traffic on port 80 and 443 from your system's public IP. Run below command to create the two rules.

    ```bash
    ## Rule 1 for HTTP traffic

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
    ```

    ```bash
    ## Rule 2 for HTTPS traffic
    
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
    ```

1. Create a subnet that you will use with NGINX for Azure resource. You will also attach the NSG that you just created to this subnet.

    ```bash
    az network vnet subnet create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-subnet \
    --vnet-name n4a-vnet \
    --address-prefixes 10.0.1.0/24 \
    --network-security-group n4a-nsg \
    --delegations NGINX.NGINXPLUS/nginxDeployments
    ```

1. Create another subnet for your AKS cluster

    ```bash
    az network vnet subnet create \
    --resource-group $MY_RESOURCEGROUP \
    --name aks2-subnet \
    --vnet-name n4a-vnet \
    --address-prefixes 10.0.2.0/23
    ```

<!-- 1. Associate NSG with the Nginx for Azure Subnet. Also add a delegation to the subnet using below command.

    ```bash
    MY_RESOURCEGROUP=s.dutta-workshop

    az network vnet subnet update \
    --resource-group $MY_RESOURCEGROUP \
    --vnet-name n4a-vnet \
    --name n4a-subnet \
    --network-security-group n4a-nsg \
    --delegations NGINX.NGINXPLUS/nginxDeployments
    ``` -->

## Create Public IP and user identity to access NGINX for Azure resource

1. Now create a Public IP to access NGINX for Azure from outside using below command.

    ```bash
    az network public-ip create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-publicIP \
    --allocation-method Static \
    --sku Standard
    ```

1. Create a user identity that would be tied to the NGINX for Azure resource

   ```bash
   az identity create \
   --resource-group $MY_RESOURCEGROUP \
   --name n4a-useridentity
   ```

## Create NGINX for Azure resource

Once Vnet, NSG and publicIP has been created, you will now create the NGINX for Azure resource object using below command

```bash
## Set environment variables
MY_RESOURCEGROUP=s.dutta-workshop
MY_SUBSCRIPTIONID=$(az account show --query id -o tsv)
```

Below command error outs with `(LinkedAuthorizationFailed)` exception. Dev team is working with Microsoft partner engineer to figure out why it is not working.

```bash
az nginx deployment create \
--resource-group $MY_RESOURCEGROUP \
--name nginx4a \
--location centralus \
--sku name="standard_Monthly_gmz7xq9ge3py" \
--network-profile front-end-ip-configuration="{public-ip-addresses:[{id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/publicIPAddresses/n4a-publicIP}]}" network-interface-configuration="{subnet-id:/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/n4a-vnet/subnets/n4a-subnet}" \
--identity="{type:UserAssigned,userAssignedIdentities:{/subscriptions/$MY_SUBSCRIPTIONID/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/n4a-useridentity:{}}}"
```

## Things to improve

1. Documentation for N4A AzureCLI still has sku pointing to `preview_Monthly_gmz7xq9ge3py`. It is not intuitive to guess what SKU name to use for standard deployment. I had to deploy N4A using Azure portal and then run `az nginx deployment show` command to look inside the deployment deployed via azure portal to figure out what is the name for Standard SKU.
