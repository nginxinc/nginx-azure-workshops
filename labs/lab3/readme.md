#  AKS / NGINX Ingress Controller / Cafe or Garage Demo Deployment 

## Introduction

In this lab, you will explore how Nginx for Azure can route and load balance traffic to backend Kubernetes applications, pods, and services.  You will create 2 AKS Kubernetes clusters, install NGINX Plus Ingress Controllers, and several demo applications.  This will be your testing platform for Nginx for Azure with AKS - deploying and managing applications, networking, and using both NGINX for Azure and NGINX Ingress features to control traffic to your Modern Apps running in the clusters.  Then you will pull an NGINX Plus Ingress Controller Image from the F5 NGINX Private Registry. Then you will deploy the NGINX Ingress Controllers, and configure it to route traffic to the demo app.

<br/>

## Learning Objectives

- Deploy 2 Kubernetes clusters using Azure CLI.
- Pulling and deploying the NGINX Plus Ingress Controller image.
- Deploying the Nginx Ingress Dashboard
- Deploying the Cafe Demo application
- Test and verify proper operation on both AKS clusters.
- Expose the Cafe Demo app and Nginx Ingress Dashboards

## What is Azure AKS?

Azure Kubernetes Service is a service provided for Kubernetes on Azure
infrastructure. The Kubernetes resources will be fully managed by Microsoft Azure, which offloads the burden of maintaining the infrastructure, and makes sure these resources are highly available and reliable at all times.  This is often a good choice for Modern Applications running as containers, and using Kubernetes Services to control them.

## Azure Regions and naming convention suggestions

1. Check out the available [Azure Regions](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview).<br/>
Decide on a [Datacenter region](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/#geographies) that is closest to you and meets your needs. <br/>
Check out the [Azure latency test](https://www.azurespeed.com/Azure/Latency)! We will need to choose one and input a region name in the following steps.

2. Consider a naming and tagging convention to organize your cloud assets to support user identification of shared subscriptions.

**Example:** 

You are located in Chicago, Illinois.  You choose the Datacenter region
`Central US`.  These labs will use the following naming convention:

```bash
<asset_type>-<your_name>-<location>

```

So for the 2 AKS Clusters you will deploy in `Central US`, and
will name your Clusters `aks-shouvik-centralus` and `aks2-shouvik-centralus`.

You will also use the Owner tag `owner=shouvik` to further identify your assets in a shared account.

## Azure CLI Basic Configuration Setting

You will need the Azure Command Line Interface (CLI) tool installed on your client machine to manage your Azure services. See [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

If you do not have Azure CLI installed, you will need to install it to continue the lab exercises.  To check Azure CLI version run below command: 

```bash
az --version

```

1. Sign in with Azure CLI using your preferred method listed [here](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).
   
   >**Note:** We made use of Sign in interactively method for this workshop
    ```bash
    az login

    ``` 

1. Once you have logged in you can run below command to validate your tenant and subscription ID and name.
   ```bash
   az account show 

   ```

2. Optional: If you have multiple subscriptions and would like to change the current subscription to another then run below command.
   ```bash
   # change the active subscription using the subscription name
   az account set --subcription "{subscription name}"

   # OR

   # change the active subscription using the subscription ID
   az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

   ```

3. Create a new Azure Resource Group called `<name>-workshop` , where `<name>` is your last name.  This will hold all the Azure resources that you will create for this workshop.  
   ```bash
   az group create --name <name>-workshop --location centralus

   ```

## Deploy 1st Kubernetes Cluster with Azure CLI

1. With the use of Azure CLI, you can deploy a production-ready AKS cluster with some options using a single command (**This will take a while**).
   ```bash
    MY_RESOURCEGROUP=s.dutta
    MY_LOCATION=centralus
    MY_AKS=aks-shouvik
    MY_NAME=shouvik
    AKS_NODE_VM=Standard_B2s
    K8S_VERSION=1.27

    # Create AKS Cluster
    az aks create \
        --resource-group $MY_RESOURCEGROUP \
        --name $MY_AKS \
        --location $MY_LOCATION \
        --node-count 3 \
        --node-vm-size $AKS_NODE_VM \
        --kubernetes-version $K8S_VERSION \
        --tags owner=$MY_NAME \
        --enable-addons monitoring \
        --generate-ssh-keys
   ```
   >**Note**: 
   >1. At the time of this writing, 1.27 is the latest kubernetes version available in Azure AKS. 
   >2. To list all possible VM sizes that an AKS node can use, run below command:      
   >     ```bash
   >     az vm list-sizes --location centralus --output table
   >     ```


2. **(Optional Step)**: If kubectl ultility tool is not installed in your workstation then you can install `kubectl` locally using below command:
   ```bash
   az aks install-cli
   ```

3. Configure `kubectl`` to connect to your Azure AKS cluster using below command.
   ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks-shouvik

   az aks get-credentials --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

## Deploy 2nd Kubernetes Cluster with Azure CLI

1. Open a second Terminal, log into to Azure, and repeat the Steps above for the Second AKS Cluster, this one has 4 nodes and a different name.

   ```bash
    MY_RESOURCEGROUP=s.dutta
    MY_LOCATION=centralus
    MY_AKS=aks2-shouvik       # Change name to aks2
    MY_NAME=shouvik
    AKS_NODE_VM=Standard_B2s
    K8S_VERSION=1.27

    # Create Second AKS Cluster
    az aks create \
        --resource-group $MY_RESOURCEGROUP \
        --name $MY_AKS \
        --location $MY_LOCATION \
        --node-count 4 \
        --node-vm-size $AKS_NODE_VM \
        --kubernetes-version $K8S_VERSION \
        --tags owner=$MY_NAME \
        --enable-addons monitoring \
        --generate-ssh-keys
   ```

1. **Managing Both Clusters:** As you are managing multiple Kubernetes clusters, you can easily change between Contexts using the `kubectl config set-context` command:
   
   ```bash
   # Get a list of kubernetes clusters in your local .kube config file:
   kubectl config get-clusters
   ```
   ```bash
   ###Sample Output###
   NAME
   local-k8s-cluster
   aks-development
   minikube
   aks-shouvik
   aks2-shouvik
   ```
   ```bash 
   # Set context
   kubectl config set-context aks-shouvik
   ```
   ```bash
   # Check which context you are currently targeting
   kubectl config current-context
   ```
   ```bash
   ###Sample Output###
   aks-shouvik
   ```
   ```bash
   # Allows you to switch between contexts using their name
   kubectl config use-context <CONTEXT_NAME>
   ```
1. Test if you are able to access your newly created AKS cluster.
   ```bash
   # Get Nodes in the target kubernetes cluster
   kubectl get nodes
   ```
   ```bash
   ###Sample Output###
   NAME                                STATUS   ROLES   AGE     VERSION
   aks-nodepool1-76910942-vmss000000   Ready    agent   9m23s   v1.27.3
   aks-nodepool1-76910942-vmss000001   Ready    agent   9m32s   v1.27.3
   aks-nodepool1-76910942-vmss000002   Ready    agent   9m30s   v1.27.3    
   ```

1. Finally to stop a running AKS cluster use this command.
   ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks-shouvik

   az aks stop --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

1. To start an already deployed AKS cluster use this command.
   ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks-shouvik

   az aks start --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

## Create an Azure Container Registry (ACR)

1.  Create a container registry using the `az acr create` command. The registry name must be unique within Azure, and contain 5-50 alphanumeric characters
    ```bash
    MY_RESOURCEGROUP=s.dutta
    MY_ACR=acrshouvik

    az acr create \
        --resource-group  $MY_RESOURCEGROUP \
        --name $MY_ACR \
        --sku Basic   
    ```

2. From the output of the `az acr create` command, make a note of the `loginServer`. The value of `loginServer` key is the fully qualified registry name. In our example the registry name is `acrshouvik` and the login server name is `acrshouvik.azurecr.io`.

3. Login to the registry using below command. Make sure your local Docker daemon is up and running.
   ```bash
   MY_ACR=acrshouvik

   az acr login --name $MY_ACR
   ```
   At the end of the output you should see `Login Succeeded`!

### Test access to your Azure ACR 

We can quickly test the ability to push images to our Private ACR from our client machine.

1. If you do not have a test container image to push to ACR, you can use a simple container for testing, e.g.[nginxinc/ingress-demo](https://hub.docker.com/r/nginxinc/ingress-demo).  You will use this same container for the lab exercises.

   ```bash
   az acr import --name $MY_ACR --source docker.io/nginxinc/ingress-demo:latest --image nginxinc/ingress-demo:v1
   ```
   The above command pulls the `nginxinc/ingress-demo` image from docker hub and pushes it to Azure ACR.

2. Check if the image was successfully pushed to ACR using the azure cli command below:

   ```bash
   MY_ACR=acrshouvik
   az acr repository list --name $MY_ACR --output table 
   ```
   ```bash
   ###Sample Output###
   Result
   ---------------------
   nginxinc/ingress-demo
   ```

### Attach an Azure Container Registry (ACR) to Azure Kubernetes cluster (AKS)

1. You will attach the newly created ACR to both AKS clusters. This will enable you to pull private images within AKS clusters directly from your ACR. Run below command to attach ACR to 1st AKS cluster:
   ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks-shouvik         # first cluster
   MY_ACR=acrshouvik

   az aks update -n $MY_AKS -g $MY_RESOURCEGROUP --attach-acr $MY_ACR
   ```

1. Change the $MY_AKS environment variable, so you can attach your ACR to your second Cluster:
      ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks2-shouvik        # change to second cluster
   MY_ACR=acrshouvik

   az aks update -n $MY_AKS -g $MY_RESOURCEGROUP --attach-acr $MY_ACR
   ```

   **NOTE:** You need the Owner, Azure account administrator, or Azure co-administrator role on your Azure subscription. To avoid needing one of these roles, you can instead use an existing managed identity to authenticate ACR from AKS. See [references](#references) for more details.


## Pulling NGINX Plus Ingress Controller Image using F5 Private Registry

<< can we change the following NIC Pull process to use the JWT token instead ?? >>

Yes, plz change

1. For NGINX Ingress Controller, you must have the NGINX Ingress Controller subscription – download the NGINX Plus Ingress Controller (per instance) certificate (nginx-repo.crt) and the key (nginx-repo.key) from [MyF5](https://my.f5.com/). You can also request for a 30-day trial key from [here](https://www.nginx.com/free-trial-connectivity-stack-kubernetes/).
   
2. Once you have the certificate and key, you need to configure the Docker environment to use certificate-based client-server authentication with F5 private container registry `private-registry.nginx.com`.<br/>
To do so create a `private-registry.nginx.com` directory under below paths based on your operating system. (See [references](#references) section for more details)
     -  **linux** : `/etc/docker/certs.d`
     -  **mac** : `~/.docker/certs.d`
     -  **windows** : `~/.docker/certs.d` 

3. Copy your `nginx-repo.crt` and `nginx-repo.key` file in the newly created directory.
     -  Below are the commands for mac/windows based systems
        ```bash
        mkdir -p ~/.docker/certs.d/private-registry.nginx.com
        cp nginx-repo.crt ~/.docker/certs.d/private-registry.nginx.com/client.cert
        cp nginx-repo.key ~/.docker/certs.d/private-registry.nginx.com/client.key
        ```  

4. ***Optional** Step only for Mac and Windows system
     - Restart Docker Desktop so that it copies the `~/.docker/certs.d` directory from your Mac or Windows system to the `/etc/docker/certs.d` directory on **Moby** (the Docker Desktop `xhyve` virtual machine).

5. Once Docker Desktop has restarted, run below command to pull the NGINX Plus Ingress Controller image from F5 private container registry.
    ```bash
    docker pull private-registry.nginx.com/nginx-ic/nginx-plus-ingress:3.2.1-alpine
    ```
    >**Note**: At the time of this writing `3.2.1-alpine` is the latest NGINX Plus Ingress version that is available. Please feel free to use the latest version of NGINX Plus Ingress Controller. Look into [references](#references) for the latest Ingress images.

6. Set below variables to tag and push image to Azure ACR
    ```bash
    MY_ACR=acrshouvik
    MY_REPO=nginxinc/nginx-plus-ingress
    MY_TAG=3.2.1-alpine
    MY_IMAGE_ID=$(docker images private-registry.nginx.com/nginx-ic/nginx-plus-ingress:$MY_TAG --format "{{.ID}}") 
    ```
    Check all variables have been set properly by running below command:
    ```bash
    set | grep MY_
    ```

7. After setting the variables, tag the pulled NGINX Plus Ingress image using below command
    ```bash
    docker tag $MY_IMAGE_ID $MY_ACR.azurecr.io/$MY_REPO:$MY_TAG
    ```
8. Login to the ACR registry using below command. 
   ```bash
   az acr login --name $MY_ACR
   ```

9. Push your tagged image to ACR registry
   ```bash
   docker push $MY_ACR.azurecr.io/$MY_REPO:$MY_TAG
   ```

10. Once pushed you can check the image by running below command
    ```bash
    az acr repository list --name $MY_ACR --output table
    ```

<< we need the output here, to show the ingress-demo and Nic images exist >>

<br/>

## Deploy Nginx Plus Ingress Controller to both clusters

< NIC deployment steps here - use nodeport-static Manifest at the end >

## Introduction

In this section, you will be installing NGINX Ingress Controller in both AKS clusters using manifest files. You will be then checking and verifying the Ingress Controller is running. 

Finally, you are going to use the NGINX Plus Dashboard to monitor both NGINX Ingress Controller as well as our backend applications. This is a great feature to allow you to watch and triage any potential issues with NGINX Plus Ingress controller as well as any issues with your backend applications.

<br/>

## Learning Objectives

- Install NGINX Ingress Controller using manifest files
- Check your NGINX Ingress Controller
- Deploy the NGINX Ingress Controller Dashboard
- (Optional Section): Look "under the hood" of NGINX Ingress Controller

## Install NGINX Ingress Controller using Manifest files

1. Make sure your AKS cluster is running. If it is in stopped state then you can start it using below command. 
   ```bash
   MY_RESOURCEGROUP=s.dutta
   MY_AKS=aks-shouvik

   az aks start --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```
   >**Note**: The FQDN for API server for AKS might change on restart of the cluster which would result in errors running `kubectl` commands from your workstation. To update the FQDN re-import the credentials again using below command. This command would prompt about overwriting old objects. Enter "y" to overwrite the existing objects.
   >```bash
   >az aks get-credentials --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   >```
   >```bash
   >###Sample Output###
   >A different object named aks-shouvik already exists in your kubeconfig file.
   >Overwrite? (y/n): y
   >A different object named clusterUser_s.dutta_aks-shouvik already exists in your kubeconfig file.
   >Overwrite? (y/n): y
   >Merged "aks-shouvik" as current context in /Users/shodutta/.kube/config
   >```

2. Clone the Nginx Ingress Controller repo and navigate into the /deployments folder to make it your working directory:
   ```bash
   git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.2.1
   cd kubernetes-ingress/deployments
   ```

3. Create a namespace and a service account for the Ingress Controller
    ```bash
    kubectl apply -f common/ns-and-sa.yaml
    ```
4. Create a cluster role and cluster role binding for the service account
    ```bash
    kubectl apply -f rbac/rbac.yaml
    ```

5. Create Common Resources:
     1. Create a secret with TLS certificate and a key for the default server in NGINX.
        ```bash
        cd ..
        kubectl apply -f examples/shared-examples/default-server-secret/default-server-secret.yaml
        cd deployments
        ```
     2. Create a config map for customizing NGINX configuration.
        ```bash
        kubectl apply -f common/nginx-config.yaml
        ```
     3. Create an IngressClass resource. 
   
         >**Note:** If you would like to set the NGINX Ingress Controller as the default one, uncomment the annotation `ingressclass.kubernetes.io/is-default-class` within the below file.
        ```bash
        kubectl apply -f common/ingress-class.yaml
        ```

6. Create Custom Resources
    1. Create custom resource definitions for VirtualServer and VirtualServerRoute, TransportServer and Policy resources:
        ```bash
        kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
        kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
        kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
        kubectl apply -f common/crds/k8s.nginx.org_policies.yaml
        ```
   
    2. Create a custom resource for GlobalConfiguration resource:
        ```bash
        kubectl apply -f common/crds/k8s.nginx.org_globalconfigurations.yaml
        ```
7. Deploy the Ingress Controller as a Deployment:

   The sample deployment file(`nginx-plus-ingress.yaml`) can be found within `deployment` sub-directory within your present working directory.

   Highlighted below are some of the parameters that would be changed in the sample `nginx-plus-ingress.yaml` file.
   - Change Image Pull to Private Repo
   - Enable Prometheus
   - Add port and name for dashboard
   - Change Dashboard Port to 9000
   - Allow all IPs to access dashboard
   - Make use of default TLS certificate
   - Enable Global Configuration for Transport Server
   
   <br/>

   Navigate back to the Workshop's `labs` directory 
    ```bash
    cd ../../labs
    ```
  
    Observe the `lab3/nginx-plus-ingress.yaml` looking at below details:
     - On line #36, the `nginx-plus-ingress:3.2.1` placeholder is changed to the workshop image that you pushed to your private ACR registry as instructed in a previous step.
  
         >**Note:** Make sure you replace the image with the appropriate image that you pushed in your ACR registry.
     - On lines #50-51, we have added TCP port 9000 for the Plus Dashboard.
     - On lines #96-97, we have enabled the Dashboard and set the IP access controls to the Dashboard.
     - On lines #16-19, we have enabled Prometheus related annotations.
     - On line #106, we have enabled Prometheus to collect metrics from the NGINX Plus stats API.
     - On line #95, uncomment to make use of default TLS secret.
     - On line #109, uncomment to enable the use of Global Configurations.

    Now deploy NGINX Ingress Controller as a Deployment using your updated manifest file.
    ```bash
    kubectl apply -f lab3/nginx-plus-ingress.yaml
    ```

## Check your NGINX Ingress Controller

1. Verify the NGINX Plus Ingress controller is up and running correctly in the Kubernetes cluster:

   ```bash
   kubectl get pods -n nginx-ingress
   ```

   ```bash
   ###Sample Output###
   NAME                            READY   STATUS    RESTARTS   AGE
   nginx-ingress-5764ddfd78-ldqcs   1/1     Running   0          17s
   ```

   >**Note**: You must use the `kubectl` "`-n`", namespace switch, followed by namespace name, to see pods that are not in the default namespace.

2. Instead of remembering the unique pod name, `nginx-ingress-xxxxxx-yyyyy`, we can store the Ingress Controller pod name into the `$NIC` variable to be used throughout the lab.

   >**Note:** This variable is stored for the duration of the terminal session, and so if you close the terminal it will be lost. At any time you can refer back to this step to save the `$NIC` variable again.

   ```bash
   export NIC=$(kubectl get pods -n nginx-ingress -o jsonpath='{.items[0].metadata.name}')
   ```

   Verify the variable is set correctly.
   ```bash
   echo $NIC
   ```
   >**Note:** If this command doesn't show the name of the pod then run the previous command again.

## Deploy the NGINX Ingress Controller Dashboard

We will deploy a `Service` and a `VirtualServer` resource to provide access to the NGINX Plus Dashboard for live monitoring.  NGINX Ingress [`VirtualServer`](https://docs.nginx.com/nginx-ingress-controller/configuration/virtualserver-and-virtualserverroute-resources/) is a [Custom Resource Definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) used by NGINX to configure NGINX Server and Location blocks for NGINX configurations.


1. In the `lab3` folder, apply the `dashboard-vs.yaml` file to deploy a `Service` and a `VirtualServer` resource to provide access to the NGINX Plus Dashboard for live monitoring:

    ```bash
    kubectl apply -f lab3/dashboard-vs.yaml
    ```
    ```bash
    ###Sample output###
    service/dashboard-svc created
    virtualserver.k8s.nginx.org/dashboard-vs created
    ```

## Deploy the Nginx CAFE Demo app

In this section, you will deploy the "Cafe Nginx" Ingress Demo, which represents a Coffee Shop website with Coffee and Tea applications. You will be adding the following components to your Kubernetes Cluster: Coffee and Tea pods, matching coffee and tea services, and a Cafe VirtualServer.

The Cafe application that you will deploy looks like the following diagram below. Coffee and Tea pods and services, with NGINX Ingress routing the traffic for /coffee and /tea routes, using the `cafe.example.com` Hostname.  There is also a hidden third service - more on that later!

< cafe diagram here >

1. Inspect the `lab3/cafe.yaml` manifest.  You will see we are deploying 3 replicas of each the coffee and tea Pods, and create a matching Service for each.

1. Deploy the Cafe application by applying these two manifests:

```bash
kubectl apply -f lab3/cafe.yaml
kubectl apply -f lab3/cafe-virtualserver.yaml

```

```bash
###Sample output###
deployment.apps/coffee created
service/coffee-svc created
deployment.apps/tea created
service/tea-svc created
virtualserver.k8s.nginx.org/cafe-vs created

```

1. Check that all pods are running, you should see three Coffee and three Tea pods:

```bash
kubectl get pods
###Sample output###
NAME                      READY   STATUS    RESTARTS   AGE
coffee-56b7b9b46f-9ks7w   1/1     Running   0             28s
coffee-56b7b9b46f-mp9gs   1/1     Running   0             28s
coffee-56b7b9b46f-v7xxp   1/1     Running   0             28s
tea-568647dfc7-54r7k      1/1     Running   0             27s
tea-568647dfc7-9h75w      1/1     Running   0             27s
tea-568647dfc7-zqtzq      1/1     Running   0          27s

```

1. In AKS1 cluster, you will run only 2 Replicas of the coffee and tea pods, so Scale both deployments down:

```bash
kubectl scale deployment coffee --replicas=2
kubectl scale deployment tea --replicas=2

```

Now there should be only 2 of each running:

```bash
kubectl get pods
###Sample output###
NAME                      READY   STATUS    RESTARTS   AGE
coffee-56b7b9b46f-9ks7w   1/1     Running   0             28s
coffee-56b7b9b46f-mp9gs   1/1     Running   0             28s
tea-568647dfc7-54r7k      1/1     Running   0             27s
tea-568647dfc7-9h75w      1/1     Running   0             27s

```

1. Check that the Cafe `VirtualServer`, **cafe-vs**, is running:

```bash
kubectl get virtualserver cafe-vs

```
```bash
###Sample output###
NAME      STATE   HOST               IP    PORTS   AGE
cafe-vs   Valid   cafe.example.com                 4m6s

```

**Note:** The `STATE` should be `Valid`. If it is not, then there is an issue with your yaml manifest file (cafe-vs.yaml). You could also use `kubectl describe vs cafe-vs` to get more information about the VirtualServer you just created.

### Deploy the Nginx Ingress Dashboard

1. Inspect the `lab3/dashboard-vs` manifest.  This will create an `nginx-ingress` Service and a VirtualServer that will expose the Nginx Ingress Controller's Plus Dashboard outside the cluster, so you can see what Nginx Ingress Controller is doing.

```bash
kubectl apply -f lab3/dashboard-vs.yaml

```

1. Test access to the NIC's Plus Dashboard.  Using Kubernetes Port-Forward utility, connect to the NIC pod in cluster #1.

```bash
# Set Kube Context to cluster 1:
kubectl config use-context aks1-<name>

```

Use the $NIC Nginx Ingress Controller pod name variable:

Port-forward to the NIC Pod on port 9000:
```bash
kubectl port-forward $NIC -n nginx-ingress 9000:9000
```

Open your local browser to http://localhost:9000/dashboard.html.  You should see the Plus dashboard.  It should have the `HTTP Zones` cafe.example.com and dashboard.example.com - these are your VirtualServers / Hostnames.  If you check the `HTTP Upstreams` tab, it should have 2 coffee and 2 tea pods.

When you are done checking out the Dashboard, type `Ctrl+C` to quit the Kubectl Port-Forward.

1. Change your `Kube Context` to your second AKS cluster, and check access to the Dashboard using the steps as above.  You should find the exact same output, the Nginx Ingress Plus Dashboard running, with Zones and Upstreams of similar.  However, the IP addresses of the Upstreams `WILL` be different between the clusters, because each cluster assigns IPs to it's Pods.  

1.  Optional Exercise:  If you want to see both NIC Dashboards at the same time, you can use 2 Terminals, each with a different Kube Context, and different Port-Forward commands.  In Terminal#1, try port-forward 9001:9000 for cluster1, and in Terminal#2, try port-forward 9002:9000 for cluster2.  Then two browser windows side by side for comparison.

Try scaling the number of coffee pods in one cluster, and see what happens.

```bash
kubectl scale deployment coffee --replicas=8
```

> Pretty cool - Nginx Ingress picks up the new Pods, health-checks them first, and brings them online for load balancing just a few seconds after Kubernetes spins them up.  Scale them up and down as you choose, while watching the Dashboard, Nginx will track them accordingly.

### Expose your Nginx Ingress Controller

1. Inspect the `lab4/nodeport-static.yaml` manifest.  This is a NodePort Service defintion that will open high-numbered ports on the Kubernetes nodes, to expose several Services that are running in the cluster.  The NodePorts are defined as static, because you will be using these port numbers with N4A, and you don't them to change.  We are using the following table to expose different Services on different Ports:

Service Port | External NodePort | Name
|:--------:|:------:|:-------:|
80 | 32080 | http
443 | 32443 | https
9000 | 32090 | dashboard


1. Deploy a NodePort Service to expose the Nginx Ingress Controller outside the cluster.

```bash
kubectl apply -f lab3/nodeport-static.yaml

```

1. Verify the NodePort Service was created:

```bash
kubectl get svc nginx-ingress -n nginx-ingress

```

```bash
#Sample output


```

## Deploy the Nginx CAFE Demo app in the 2nd cluster

1. Repeat the previous section to deploy the CAFE Demo app in your second cluster.  Do not Scale the coffee and tea replicas down, leave three of each pod running.
1. Report the same NodePort deployment, to expose the Nginx Ingress Controller outside the cluster.

## Update local DNS

We will be using FQDN hostnames for the labs, and you will need to update your local computer's `/etc/hosts` file, to use these names with N4A and Nginx Ingress Controller.

Edit your local hosts file, adding the FQDNs as shown below.  Use the `External-IP` Address of Nginx for Azure:

```bash
vi /etc/hosts

13.86.100.10 cafe.example.com dashboard.example.com    # Added for N4A Workshop 
```

>**Note:** Both hostnames are mapped to the same N4A External-IP.  You will use the NGINX Ingress Controller to route the traffic correctly in the upcoming labs.  
Your N4A External-IP address will be different than the example.

## Test Access to Nginx Cafe, and Nginx Ingress Dashboards



**This completes the Lab.** 

<br/>

## References: 

- [Deploy AKS cluster using Azure CLI](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)
- [Azure CLI command list for AKS](https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest)
- [Create private container registry using Azure CLI](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli)
- [Azure CLI command list for ACR](https://learn.microsoft.com/en-us/cli/azure/acr?view=azure-cli-latest)
- [Authenticate with ACR from AKS cluster](https://learn.microsoft.com/en-us/azure/container-registry/authenticate-kubernetes-options#scenarios)
- [Pulling NGINX Plus Ingress Controller Image](https://docs.nginx.com/nginx-ingress-controller/installation/pulling-ingress-controller-image)
- [Add Client Certificate Mac](https://docs.docker.com/desktop/faqs/macfaqs/#add-client-certificates)
- [Add Client Certificate Windows](https://docs.docker.com/desktop/faqs/windowsfaqs/#how-do-i-add-client-certificates)
- [Docker Engine Security Documentation](https://docs.docker.com/engine/security/certificates/)
- [Latest NGINX Plus Ingress Images](https://docs.nginx.com/nginx-ingress-controller/technical-specifications/#images-with-nginx-plus)

<br/>


### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to ([Lab5](../lab5/readme.md) | [LabX](../labX/readme.md))
