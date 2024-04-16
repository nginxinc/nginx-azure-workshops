#  AKS / Nginx Ingress Controller Deployment 

## Introduction

In this lab, you will explore how Nginx for Azure can route and load balance traffic to backend Kubernetes applications, pods, and services.  But first, you will need to create a test environment.  You will create 2 AKS Kubernetes clusters, and deploy NGINX Plus Ingress Controller.  This will be your testing platform for Nginx for Azure with AKS - deploying and managing applications, networking, and using both NGINX for Azure and NGINX Plus Ingress features to control traffic to your Modern Apps running in the clusters.  You will deploy a Kubernetes Service to access the Nginx Plus Ingress Dashboard, and expose it with Nginx for Azure, so you can see in real time what is happening inside both AKS clusters.

<br/>

## Learning Objectives

- Deploy 2 Kubernetes clusters using Azure CLI.
- Pulling and deploying the NGINX Plus Ingress Controller image.
- Test and verify proper operation of both AKS clusters.
- Deploy the Nginx Plus Ingress Dashboard.
- Expose the Nginx Ingress Dashboards with Nginx for Azure.

## Pre-Requisites

- You must have Azure Networking configured for this Workshop
- You must have Azure CLI tool installed on your local system
- You must have Kubectl installed on your local system
- You must have Git installed on your local system
- You must Docker Desktop or Docker client tools installed on your local system
- You must have your Nginx for Azure instance deployed and running
- Familiarity with Azure Resource types - Groups, VMs, NSG, AKS, etc 
- Familiarity with basic Linux commands and commandline tools
- Familiarity with Kubernetes / AKS concepts and commands
- Familiarity with basic HTTP protocol
- Familiarity with Ingress Controller concepts
- See `Lab0` for instructions on setting up your system for this Workshop

## What is Azure AKS?

Azure Kubernetes Service is a service provided for Kubernetes on Azure infrastructure. The Kubernetes resources will be fully managed by Microsoft Azure, which offloads the burden of maintaining the infrastructure, and makes sure these resources are highly available and reliable at all times.  This is often a good choice for Modern Applications running as containers, and using Kubernetes Services to control them.

## Workshop and Azure naming convention suggestions

1. Check out the available [Azure Regions](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview).<br/>
Decide on a [Datacenter region](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/#geographies) that is closest to you and meets your needs. <br/>
Check out the [Azure latency test](https://www.azurespeed.com/Azure/Latency)! You will need to choose one and provide a region name in the following steps.

2. Consider a naming and tagging convention to organize your Azure assets to support user identification of shared subscriptions.  If you share a subscription with others, it's important to minimize duplication and identify owners of Resources in Azure.  (Or you will get nag mail for excessive charges from the boss.)

**Example:** 

You are located in Chicago, Illinois.  You choose the Datacenter region `Central US`.  These labs will use the following naming convention:

```bash
n4a-<asset_type>

```

So for the 2 AKS Clusters you will deploy in `Central US`, and
will name your Clusters: 

- `n4a-aks1`
- `n4a-aks2`

- You will also use your name or email for the Owner tag, like  `owner=shouvik` to further identify your assets in a shared Azure account.

## Deploy 1st Kubernetes Cluster with Azure CLI

1. With the use of Azure CLI, you can deploy a production-ready AKS cluster with some options using a single command (**This will take a while**).

First, you need to set multiple ENVIRONMENT variables, which are passed to the Azure CLI, to create the objects required for the Workshop.  Set your Environment variables as follows:

   ```bash
    # Set Variables to match your Workshop settings
    MY_RESOURCEGROUP=dutta
    MY_LOCATION=centralus
    MY_AKS=n4a-aks1
    MY_NAME=s.dutta
    AKS_NODE_VM=Standard_B2s
    K8S_VERSION=1.27
    MY_VNET=n4a-vnet
    MY_SUBNET=/subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/$MY_VNET/subnets/aks1

    # Create First AKS Cluster
    az aks create \
        --resource-group $MY_RESOURCEGROUP \
        --name $MY_AKS \
        --location $MY_LOCATION \
        --node-count 3 \
        --node-vm-size $AKS_NODE_VM \
        --kubernetes-version $K8S_VERSION \
        --tags owner=$MY_NAME \
        --vnet-subnet-id=$MY_SUBNET
        --enable-addons monitoring \
        --generate-ssh-keys
   ```
   >**Note**: 
   >At the time of this writing, 1.27 is the latest kubernetes version available in Azure AKS. 


2. **(Optional Step)**: If kubectl ultility tool is not installed in your workstation then you can install `kubectl` locally using below command:
   ```bash
   az aks install-cli
   ```

3. Configure `kubectl`` to connect to your Azure AKS cluster using below command.
   ```bash
   MY_RESOURCEGROUP=dutta
   MY_AKS=n4a-aks2

   az aks get-credentials --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

## Deploy 2nd Kubernetes Cluster with script

1. Open a second Terminal, log into to Azure, and repeat the Steps above for the Second AKS Cluster, this one has 4 nodes and a different name.

   ```bash
    # Set Variables to match your Workshop settings
    MY_RESOURCEGROUP=dutta
    MY_LOCATION=centralus
    MY_AKS=n4a-aks2           # Change name 
    MY_NAME=s.dutta
    AKS_NODE_VM=Standard_B2s
    K8S_VERSION=1.27
    MY_VNET=n4a-vnet
    MY_SUBNET=/subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/$MY_RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/$MY_VNET/subnets/aks2

    # Create Second AKS Cluster
    az aks create \
        --resource-group $MY_RESOURCEGROUP \
        --name $MY_AKS \
        --location $MY_LOCATION \
        --node-count 4 \
        --node-vm-size $AKS_NODE_VM \
        --kubernetes-version $K8S_VERSION \
        --tags owner=$MY_NAME \
        --vnet-subnet-id=$MY_SUBNET \
        --network-plugin option: azure \
        --enable-addons monitoring \
        --generate-ssh-keys
   ```

1. **Managing Both Clusters:** As you are managing multiple Kubernetes clusters, you can easily change between Contexts using the `kubectl config use-context` command:
   
   ```bash
   # Get a list of kubernetes clusters in your local .kube config file:
   kubectl config get-contexts
   ```

   ```bash
   ###Sample Output###
   CURRENT   NAME                          CLUSTER           AUTHINFO                         NAMESPACE
*         n4a-aks1                   n4a-aks1        clusterUser_shouvik_n4a-aks1
          n4a-aks2                   n4a-aks2        clusterUser_shouvik_n4a-aks2
          kubernetes-admin@kubernetes   kubernetes        kubernetes-admin
          rancher-desktop               rancher-desktop   rancher-desktop
   ```
   ```bash 
   # Set context
   kubectl config use-context n4a-aks1
   ```
   ```bash
   # Check which context you are currently targeting
   kubectl config current-context
   ```
   ```bash
   ###Sample Output###
   n4a-aks1
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
   MY_RESOURCEGROUP=dutta
   MY_AKS=n4a-aks1

   az aks stop --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

1. To start an already deployed AKS cluster use this command.
   ```bash
   MY_RESOURCEGROUP=dutta
   MY_AKS=n4a-aks1

   az aks start --resource-group $MY_RESOURCEGROUP --name $MY_AKS
   ```

## Pulling NGINX Plus Ingress Controller Image using F5 Private Registry

1. For NGINX Plus Ingress Controller, you must have a software subscription license – download the NGINX Plus Ingress Controller license JWT Token file (nginx-repo.jwt) from your account on [MyF5](https://my.f5.com/). 

If you do not have a license, you can request a 30-day Trial key from [here](https://www.nginx.com/free-trial-connectivity-stack-kubernetes/).

>However, in this Workshop, a Trial License will be provided to you, so you can pull and run the Nginx Plus Commercial version of the Ingress Controller from Nginx.  This is NOT the same Ingress Controller provided by the Kubernetes Community.  (If you are unsure which Ingress Controller you are using in your other Kubernetes environments, you can find a link to the Blog from Nginx that explains the differences).
   
1. Once your Workshop Instructor has provide the access key, follow these instructions to create a Kubernetes Secret named `regcred`, of type docker-registry.  You will need to create the Secret in both of your AKS clusters, switch Clusters with `kubectl config use-context n4a-aks#`. 

1. Copy the `nginx-repo.jwt` file provided in the newly created directory.

1. Export the contents of the JWT file to an environment variable.

```bash
export JWT=$(cat nginx-repo.jwt)

```
```bash
# Check $JWT
echo $JWT

```

1. Create a Kubernetes `docker-registry` Secret type on the cluster, using the JWT token as the username and none for password (as the password is not used).  The name of the docker server is private-registry.nginx.com.  Replace the <docker-username> parameter with the contents of the `nginx-repo.jwt` file:

    ```bash
    kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=$JWT --docker-password=none
    ```
    
   > It is important that the --docker-username=<JWT Token> contains the contents of the token and is not pointing to the token itself. Ensure that when you copy the contents of the JWT token, there are no additional characters or extra whitespaces. This can invalidate the token and cause 401 errors when trying to authenticate to the registry.

1. Confirm the Secret was created successfully by running:

```bash
kubectl get secret regcred --output=yaml

```
```bash
# Sample output
apiVersion: v1
data:
  .dockerconfigjson: 
  ...snipped Token Here
kind: Secret
metadata:
  creationTimestamp: "2024-04-16T19:21:09Z"
  name: regcred
  namespace: default
  resourceVersion: "5838852"
  uid: 30c60523-6b89-41b3-84d8-d22ec60d30a5
type: kubernetes.io/dockerconfigjson

```

1. Repeat the Docker Config Secret procedure in your Second AKS Cluster, n4a-aks2:  

```bash
# Change contexts
kubectl config use-context n4a-aks2

```

1. Create a Docker Config Secret in your Second cluster.  Replace the <docker-username> parameter with the contents of the `nginx-repo.jwt` file:

    ```bash
    kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=$JWT --docker-password=none
    ```

1. Confirm the Secret was created successfully by running:

```bash
kubectl get secret regcred --output=yaml

```
```bash
# Sample output

```

1. Once you are sure you have correctly created the Secrets on both Clusters, switch Context back to `n4a-aks1`, and you can continue with the next step.

<br/>

## Deploy Nginx Plus Ingress Controller to both clusters

In this section, you will be installing NGINX Plus Ingress Controller in both AKS clusters using manifest files. You will be then checking and verifying the Ingress Controller is running. 

<br/>

1. Make sure your AKS cluster is running. Check the Nodes using below command. 
   ```bash
   kubectl get nodes

   ```
   ```bash
   #Sample output
   NAME                                STATUS   ROLES   AGE   VERSION
   aks-agentpool-25373057-vmss00000k   Ready    agent   21h   v1.27.9
   aks-agentpool-25373057-vmss00000l   Ready    agent   21h   v1.27.9
   aks-userpool-76919110-vmss000008    Ready    agent   21h   v1.27.9
   aks-userpool-76919110-vmss000009    Ready    agent   21h   v1.27.9
   ```

2. Clone the Nginx Ingress Controller repo and navigate into the /deployments folder to make it your working directory:
   ```bash
   git clone https://github.com/nginxinc/kubernetes-ingress.git --branch v3.3.2
   cd kubernetes-ingress/deployments
   ```
   >**Note**: At the time of this writing `3.3.2` is the latest NGINX Plus Ingress version that is available. Please feel free to use the latest version of NGINX Plus Ingress Controller. Look into [references](#references) for the latest Ingress images.

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
     - On line #36, the `nginx-plus-ingress:3.3.2` placeholder is changed to the workshop image that you pushed to your private ACR registry as instructed in a previous step.
  
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

Finally, you are going to use the NGINX Plus Dashboard to monitor both NGINX Ingress Controller as well as our backend applications. This is a great feature to allow you to watch and triage any potential issues with NGINX Plus Ingress controller as well as any issues with your backend applications.

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
- [Installing NGINX Plus Ingress Controller Image](https://docs.nginx.com/nginx-ingress-controller/installation/nic-images/using-the-jwt-token-docker-secret/)
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
