# Nginx for Azure Workshop Outline / Summary

## Lab 0 - Prequesites - Subscription / Resources
## Lab 1 - Azure VNet/Subnet / Network Security Group / Nginx for Azure Overview
## Lab 2 - UbuntuVM/Docker / Windows VM / Cafe Demo Deployment 
## Lab 3 - AKS / Nginx Plus Ingress Deployment / NIC Dashboard
## Lab 4 - Cafe Demo / Redis Deployment
## Lab 5 - Nginx for Azure Load Balancing / Reverse Proxy
## Lab 6 - Azure Key Vault / TLS Essentials
## Lab 7 - Azure Monitoring / Logging Analytics
## Lab 8 - Nginx Garage or Azure Petshop
## Lab 9 - Nginx Caching / Rate Limits / Juiceshop
## Lab 10 - Grafana for Azure
## Lab 11 - Optional Exercises - Windows VM
## Summary and Wrap-up

<br/>

## Introduction

This NGINXpert Workshop will explore the Nginx for Azure Service, available and running in Microsoft's Azure Cloud.  As a Cloud Architect, Platform or DevOps Engineer, you will create different Azure Resources and Services, and use Nginx for Azure to load balance, route, terminate TLS, split, cache, rate limit, and use other Nginx functions to manage traffic to these Azure resources.  The Workshop is led by Instructors that will show you how to do these things, and explain the technical and business merits of these solutions with Nginx for Azure.  As you follow along, the Hands On Lab Exercises will show you how to configure Nginx, and integrate with different Azure Services like Azure Key Vault, Azure Monitoring, Azure Logging / Analytics / Grafana.  A variety of different systems and applications are used as examples, including VMs, Docker containers, Kubernetes Clusters, Nginx Ingress Controllers.

This is an Intermediate, 200 Level Workshop.  Students will require existing skills with Nginx, Azure CLI/Portal, Docker, Linux, and various networking tools.  You will also need a Subscription to Azure for the Hands On Labs, with Owner level access to create and configure various Azure Services.

NGINXpert Workshops are also available for Nginx Basics and Nginx Ingress Controller, which are highly recommended as Prerequisites for this Workshop.  You can find those on Github as well.

### Lab 0 - Prequesites - Subscription / Resources

- Overview
In this Lab, the Prerequisite Requirements for both the Student and the Azure environment will be detailed.  It is imperative that you have the appropriate computer, tools, skills, and Azure access to successfully complete the workshop.  The Lab exercises must be done sequentially to build the environment as described.  This is an intermediate level class, you must be proficient in several areas to successfully complete the workshop.  Beginner level workshops are available from Nginx, to help prepare you for this workshop - see the References section below.

- Learning Objectives
Verify you have the proper computer requirements - hardware and software.
- Hardware:  Laptop, Admin rights, Internet connection
- Software:  Visual Studio, Terminal, Chrome, Docker, AKS and AZ CLI, Redis-CLI.
Verify you have proper computer skills.
- Computer skills:  Linux CLI, file mgmt, SSH/Terminal, Docker/Compose, Azure Portal, HTTP/S, Kubernetes Nodes/Pods/Services skills, Load Balancing concepts
- Optional: TLS, DNS, HTTP caching, Prometheus, Grafana, Redis
Verify you have the proper access to Azure resources.
- Azure subscription, list of Azure Roles/permissions here

- Nginx for Azure Workshop has the following REQUIRED Nginx Skills
Students must be familiar with Nginx basic operations, configurations, and concepts for HTTP traffic.
-- The Nginx Basics Workshop is HIGHLY recommended, students should have taken this workshop prior.
-- The Nginx Plus Ingress Controller workshop is also HIGHLY recommended, students should have taken this workshop prior.
-- Previous training on Azure Resource Groups, VMs, Azure Networking, AKS, and NSG is HIGHLY recommended.

<br/>

### Lab 1 - Azure VNet/Subnet / Network Security Group / Nginx for Azure Overview

- Overview
In this lab, you will be adding and configuring the Azure Networking components needed for this workshop.  This will require a few network resources, and a Network Security Group to allow incoming traffic to your Nginx for Azure workshop resources.  Then you will explore the Nginx for Azure product, as a quick Overview of what it is and how to deploy it.

- Learning Objectives
Setup your Azure Vnet and Subnets
Setup your Azure Network Security Group for inbound traffic
Explore Nginx for Azure
Deploy an Nginx for Azure instance / enable logging
Test Nginx for Azure welcome page

<br/>

### Lab 2 - Ubuntu VM/Docker / Windows VM / Cafe Demo Deployment

- Overview
In this lab, you will deploy an Ubuntu VM, and configure it for a Legacy web application.  You will deploy a Windows VM.  You will configure Nginx for Azure to proxy and load balance these backends.

- Learning Objectives
Deploy Ubuntu VM
Install Docker and Docker-compose
Run Legacy docker container apps - Cafe Demo
Optional Exercise: Deploy Windows VM
Configure Nginx Load Balancing for these apps

<br/>

### Lab 3 - AKS / Nginx Ingress Controller Deployment / NIC Dashboard

- Overview
In this lab, you will deploy 2 AKS clusters, with Nginx Ingress Controllers. 

- Learning Objectives
Deploy 1 AKS cluster using the Azure AZ CLI.
Deploy 2nd AKS cluster with a bash script.
Deploy Nginx Plus Ingress Controller with F5 Private Registry, to both the Clusters.
Configure Nginx Plus Ingress Controller Dashboards.
Expose the NIC Plus Dashboards externally for Live Monitoring.

<br/>

### 4 - Nginx Cafe Demo / Redis Deployment

- Overview
In this lab, you will deploy the Nginx Cafe Demo, with Nginx Ingress Controllers, a Redis cluster, and expose them with Nginx for Azure.  

- Learning Objectives
Deploy the Nginx Cafe Demo web application in both clusters.
Configure Nginx Ingress for Cafe.
Configure Nginx for Azure for Cafe applications.
Deploy Redis In Memory Cache to the AKS cluster.
Configure Nginx Ingress for Redis Leader.
Configure Nginx for Azure for Redis applications.

<br/>

### Lab 5 - Nginx Load Balancing / Reverse Proxy

- Overview
In this lab, you will configure Nginx for Azure to Load Balance various workloads running in Azure.  After successful configuration and adding Nginx Best Practice parameters, you will Load Test these applications, and test multiple load balancing and request routing parameters to suit different use cases.

- Learning Objectives
Configure Nginx for Azure, to Load Balance traffic to both AKS Clusters / Nginx Ingress Controllers.
Configure HTTP Split Clients, Blue/Green traffic Splitting - route traffic to verious backend systems using 0-100% Ratios.
Load test the Legacy and Modern web applications.
Run an HTTP Load Test on Cafe.
Configure Nginx for Azure, to Load Balance Nginx Ingress Controllers as a Headless Service with ClusterIPs.
Run a Redis Benchmark test on Redis Leader.
Configure Nginx for Azure, to Load Balance Nginx Ingress Controllers as a Headless Service with ClusterIPs.

<br/>

### Lab 6 - Azure Key Vault / TLS Essentials

- Overview
In this lab, you use Azure Key Vault for TLS certificates and keys.  You will configure Nginx for Azure to use these Azure resources to terminate TLS.

- Learning Objectives
Create a sample Azure Key Vault
Create a TLS cert/key
Configure and test Nginx for Azure to use the Azure Keys
Update the previous Nginx configurations to use TLS for apps
Update NSGs for TLS inbound traffic

<br/>

### Lab 7 - Azure Montoring / Logging Analytics

- Overview
Enable and configure Azure Monitoring for Nginx for Azure.  Create custom Azure Dashboards for your applications.  Gain experience using Azure Logs and logging tools.

- Learning Objectives
Enable, configure, and test Azure Monitoring for Nginx for Azure.
Create a couple custom dashboards for your load balanced applications.
Explore the Azure logging and Analytics tools available.

<br/>

### Lab 8 - Nginx Garage or Azure Petshop

- Overview
In this lab, you will deploy a modern application in your AKS cluster.  You will expose it with Nginx Ingress Controller and Nginx for Azure.

- Learning Objectives
Deploy the modern app in AKS
Test and Verify the app is working correctly
Expose this application outside the cluster with Nginx Ingress Controller
Configure Nginx for Azure for this new application

<br/>

### Lab 9 - Nginx Caching / Rate Limits / Juiceshop

- Overview
In this lab, you will deploy an image rich application, and use Nginx Caching to cache images to improve performance.

- Learning Objectives
Deploy JuiceShop in AKS cluster.
Expose JuiceShop with Nginx Ingress Controller.
Configure Nginx for Azure for load balancing JuiceShop.
Add Nginx Caching to improve delivery of images.

<br/>

### Lab 10 - Grafana for Azure

- Overview
In this lab, you will explore the Nginx and Grafana for Azure integration.

- Learning Objectives
Deploy Grafana for Azure.
Configure the Datasource
Explore a sample Grafana Dashboard for Nginx for Azure


<br/>

### Lab 11 - Optional Exercises




<br/>

### Summary and Wrap-up

- Summary and Wrap-up comments here