# NGINXaaS for Azure and NLK - NGINXaaS Loadbalancer for Kubernetes

## Introduction

The NGINX for Azure as a Service now includes the `NGINX Loadbalancer for Kubernetes` Controller, to support manual and dynamic AutoScaling of AKS clusters with matching NGINXaaS configurations.

Using NGINXaaS with NLK synchronizes the AKS Worker Nodes of the cluster with the NGINX upstream server list automatically, so that all Worker nodes can receive incoming traffic.  This provides High Availability, increased Performance, dynamic scaling, and allows NGINXaaS to mirror the Kubernetes Node or Service changes made to the cluster by the AKS admin or any cluster automation tools.

What is the NLK Controller and how does it work?  It is a standard Kubernetes Container, written as a Controller object that interfaces with the Kubernetes cluster administration control plane, including the Kubernetes Cluster API.  It Registers itself as a Controller with the API, which allows it to `Watch and be Notified` of certain Kubernetes Events.  The Notifications of `Node and Service changes` allow the Controller to then send it's own API updates to the Nginx for Azure instance.  The updates are limited to modifying the `upstream server IP:Ports` in the Nginx config files.  You will configure and test this in this lab exercise.

Using both manual and autoscaling with AKS clusters is a common practice, the most obvious scenario is the need for the Cluster resources to be scaled `in response to changing workloads` running in the Cluster.  If you scale Worker nodes up/down, NLK will detect these changes and update your Nginx instance for you, automatically.

<br/>

NGINXaaS for Azure | AKS | Nginx Loadbalancer Kubernetes
:-------------------------:|:-------------------------:|:-----------------:
![N4A](media/nginx-azure-icon.png) | ![AKS](media/aks-icon.png) | ![NLK](media/nlk-icon.jpeg)

<br/>

## Learning Objectives 

By the end of the lab you will be able to:
- Create NGINXaaS API Key 
- Deploy the NLK Controller to your cluster
- Configure NGINXaaS for NLK updates
- Deploy the nginx-ingress Service for NLK
- Test the traffic flows for Nginx Cafe
- Test the AKS AutoScaling and NLK integration

<br/>

## Prerequisites

- NGINX for Azure Subscription
- Complete Labs 1-4 deployments in your Azure Resource Group
- 

## Create new NGINXaaS API Key

The NLK controller uses an API key to be able to send updates to your Nginx instance.  Create a new one following these steps:

1. Using the N4A Web Console, in your N4A deployment, Settings, click on `NGINX API keys`, then `+ New API Key`.

1. On the right in `Add API Key` sidebar, give it a name.  Optionally change the Expiration Date.  In this example, you will use:
- Name: nlk-api-key
- Expiration Date: 365 Days (12 monthes)

Click `Add API Key` at the bottom.

NOTE:  Click the Copy icon next to the Value, and SAVE this API Key somewhere safe, is it only displayed in full here, one time only!

On this same window, copy/paste/save the `Dataplane API endpoint` at the top fo the screen, you will also need this value.  This is the endpoint where NLK will send the API updates.

< ss here >

## Deploy the NGINX Loadbalancer Kubernetes Controller using Azure Portal

< nlk icon here >

Go the Azure Marketplane, or click on this link to show you the NLK Controller.  https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-nginx-for-azure-aks-extension

Click on `Get It Now`, then `Continue`.

Select the Subscription and Resource Group for the deployment; Select `No` for a new AKS cluster.  You will use your existing clusters from Lab3 for this lab exercise.

Click `Next`, and chose `n4a-aks1` under Cluster Details.

Click `Next`, and fill out as follows:
- Type `aks1nlk` for the Cluster extension resouce name
- Leave the namespace as `nlk`
- Check the `Allow minor version updates`
- Paste your Dataplane API Key value
- Paste your Dataplane API Endpoint URL **and ADD `nplus` to the end**

Click `Next`, Review your settings.

If you scroll to the bottom, you will see your entered data, take a screenshot if you did not SAVE it somewhere :-)  If you are satisifed with your Settiings, click `Create`.  You can safely ignore the billing warning, NLK is free of charge at the time of this writing.

< ss here >

Wait for the Deployment to be successful, it can take several minutes.  When completed, create a new Dashboard called NLK and pin it.

Verify it is running in your `n4a-aks1` cluster.

Check that your kubectl config context is set for n4a-aks1, and check for everything in the `nlk` namespace, as shown:

```bash
kubectl config use-context n4a-aks1
kubectl get all -n nlk

```

You should see a pod, deployment, and replicaset, all in a READY state.

```bash
## Sample output ##
NAME                                                            READY   STATUS    RESTARTS   AGE
pod/aks1nlk-nginxaas-loadbalancer-kubernetes-79d8655d7d-kspxc   1/1     Running   0          2m21s

NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/aks1nlk-nginxaas-loadbalancer-kubernetes   1/1     1            1           2m21s

NAME                                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/aks1nlk-nginxaas-loadbalancer-kubernetes-79d8655d7d   1         1         1       2m21s

```

## Configure NGINXaaS for NLK updates

Now that the NLK Controller is running, you need a matching Upstream configuration in your N4A instance, that will match how traffic is sent to your Cluster.  In this example, you will great a new upstream config named `aks1-nlk-upstreams.conf`.  *Notice - this upstream block will NOT contain any server IP:PORT directives*, because the NLK Controller will be dynamically adding them for you.  

1. Using the N4A web console, create a new file `/etc/nginx/conf.d/aks1-nlk-upstreams.conf`.  You can use this example as shown, just copy/paste.

```nginx
# Chris Akker, Shouvik Dutta, Adam Currier - Jan 2025
# Nginx Upstream Block for NLK Controller
#
# Nginx 4 Azure - aks1-nlk-upstreams.conf
#
upstream aks1-nlk-upstreams {
   zone aks1-nlk-upstreams 256K;             # required for metrics
   state /tmp/aks1-nlk-upstreams.state;      # required for backup

   least_time last_byte;                # choose the fastest NodePort

   # Server List dynamically managed by NLK Controller

   keepalive 16;

}

```

DeepDive explanation of the Upstream block:

- upstream <name>; - choose a name that will be easy to remember, which cluster, NLK tag, and even the protocol being used (you will can change this to https if needed, of course)
- zone <name>; this is the shared memory zone used by Nginx Plus to collect all the upstream server metrics; like connections, health checks, handshakes, requests, responses, and response time
- state <file>; - this is a backup file of the Server List, in case Nginx is restarted, or the host is rebooted.  Because the Server List only exists in memory, this backup file is required, usually the file name matched the upstream name.
- least_time last_byte; - this is the advanced load balancing algorithm that watches the HTTP Response time, and favors the fastest server.  This is a critical setting for obtaining optimal performance in Kubernetes environments.
- keepalive <num>; - this creates a TCP connection pool that Nginx uses for Requests.  Also critical for optimal performance
- Consult the Nginx Plus documentation for further details on these Directives, there is a link in the References Section.

Submit your Configuration.

## Create the Kubernetes NodePort Service

Now a Kubernetes Service is required, to expose your application outside of the cluster.  NLK uses a standard `NodePort` definition, with a few additions needed for the NLK Controller.  In this exercise, you will expose the `nginx-ingress Service`, which is the Nginx Ingress Controller running inside the Cluster.  This create TWO layers of Nginx Loadbalancing - N4A outside the Cluster is sending traffic to Nginx Ingress inside the Cluster.  NIC will then route the requests to the correct services and pods.  (NOTE that data plane traffic does NOT go through the NLK Controller at all, as it is part of the control plane).

1. Using kubectl, set your config context for `aks1`, and apply the NodePort manifest file provided here:

```bash
kubectl config use-context aks1
kubectl apply -f nodeport-aks1.yaml

```
```bash
## Sample output ##

```

DeepDive explanation of the `nodeport-ask1.yaml` manifest:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
  namespace: nginx-ingress
  annotations:
    # Let the controller know to pay attention to this K8s Service.
    nginx.com/nginxaas: nginxaas
spec:
  # expose the HTTP port on the nodes
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    # The port name maps to N4A upstream. It must be prefixed with `http-`
    # and the rest of the name must match the name of an upstream
    name: http-aks1-nlk-upstreams
  selector:
    app: nginx-ingress

```

Check that your Service was created.

```bash
kubectl describe svc nginx-ingress -n nginx-ingress

```

```
## Sample output ##
Name:                     nginx-ingress
Namespace:                nginx-ingress
Labels:                   <none>
Annotations:              nginx.com/nginxaas: nginxaas
Selector:                 app=nginx-ingress
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.47.161
IPs:                      10.0.47.161
Port:                     http-aks1-nlk-upstreams  80/TCP
TargetPort:               80/TCP
NodePort:                 http-aks1-nlk-upstreams  31729/TCP
Endpoints:                10.244.0.4:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>

```

Notice that Kubernetes chooses an ephemeral high-port TCP Port, `31729` in this example.  The NLK Controller is Notified of this Service change, and will send the API commands to N4A to update the Upstream Server List.  The Server List will be each workers `NodeIP:31729`.  (K8s Control Nodes are intentionally excluded from this List).

You can confirm this in several ways.







NOTE:  If you have a second AKS cluster, you will need another Upstream file.  Just change the name and directive to match `aks2` following the example above.


<br/>

**This completes Lab 12.**

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)

- [NGINX Plus Product Page](https://docs.nginx.com/nginx/)
- [NGINX Directives Index](https://nginx.org/en/docs/dirindex.html)
- [NGINX Variables Index](https://nginx.org/en/docs/varindex.html)
- [NGINX Technical Specs](https://docs.nginx.com/nginx/technical-specs/)

<br/>

### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to [LabGuide](../readme.md))