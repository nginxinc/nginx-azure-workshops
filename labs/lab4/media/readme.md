#  NIC Dashboard / Cafe Demo / Redis Deployment 

## Introduction

In this lab, you will build ( x,y,x ).

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Cafe | Redis
:-------------------:|:-------------------:|:-------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Cafe](media/cafe-icon.png) |![Redis](media/redis-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Deploying the Cafe Demo application
- Deploying the Redis In Memory cache
- Expose the Cafe Demo app with Nginx for Azure
- Expose the Redis Cache with Nginx for Azure


## Pre-Requisites

- You must have `aaaa` installed and running
- You must have `bbbbb` installed
- See `Lab0` for instructions on setting up your system for this Workshop
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Docker concepts and commands
- Familiarity with basic HTTP protocol

<br/>

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

### Deploy the Nginx CAFE Demo app in the 2nd cluster

1. Repeat the previous section to deploy the CAFE Demo app in your second AKS cluster.  Do not Scale the coffee and tea replicas down, leave three of each pod running.
1. Repeat the same NodePort deployment, to expose the Nginx Ingress Controller outside the cluster.

## Update local DNS

We will be using FQDN hostnames for the labs, and you will need to update your local computer's `/etc/hosts` file, to use these names with N4A and Nginx Ingress Controller.

Edit your local hosts file, adding the FQDNs as shown below.  Use the `External-IP` Address of Nginx for Azure:

```bash
vi /etc/hosts

13.86.100.10 cafe.example.com dashboard.example.com    # Added for N4A Workshop 
```

>**Note:** Both hostnames are mapped to the same N4A External-IP.  You will use the NGINX Ingress Controller to route the traffic correctly in the upcoming labs.  
Your N4A External-IP address will be different than the example.

### Lab exercise 2

<numbered steps are here>

### Lab exercise 3

<numbered steps are here>

### << more exercises/steps>>

<numbered steps are here>

<br/>

**This completes Lab2.**

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

<br/>

### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to ([Lab3](../lab3/readme.md) | [LabX](../labX/readme.md))
