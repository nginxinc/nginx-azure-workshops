# Optional Exercises / Grafana

## Introduction

In this lab, you will build ( x,y,x ).

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Docker
:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Introduction to `xx`
- Build an `yyy` Nginx configuration
- Test access to your lab enviroment with Curl and Chrome
- Investigate `zzz`


## Pre-Requisites

- You must have `aaaa` installed and running
- You must have `bbbbb` installed
- See `Lab0` for instructions on setting up your system for this Workshop
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Docker concepts and commands
- Familiarity with basic HTTP protocol

<br/>

## Create and attach Azure Container Registry (ACR)

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


### Lab exercise 2

Nginx Rate Limiting here

### Lab exercise 3

<numbered steps are here>

### << more exercises/steps>>

<numbered steps are here>

<br/>

**This completes LabX.**

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX Plus Product Page](https://docs.nginx.com/nginx/)
- [NGINX Ingress Controller](https://docs.nginx.com//nginx-ingress-controller/)
- [NGINX on Docker](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/)
- [NGINX Directives Index](https://nginx.org/en/docs/dirindex.html)
- [NGINX Variables Index](https://nginx.org/en/docs/varindex.html)
- [NGINX Technical Specs](https://docs.nginx.com/nginx/technical-specs/)
- [NGINX - Join Community Slack](https://community.nginx.org/joinslack)
- [NGINX - HTTP Request Limits](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req_zone)


<br/>

### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to ([Lab Guide](../readme.md))
