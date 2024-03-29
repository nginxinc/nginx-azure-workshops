# Nginx for Azure Workshop Outline / Summary

## Lab 0 - Prequesites - Subscription / Resources
## Lab 1 - Azure VNet and Subnet and Network Security Group
## Lab 2 - Nginx for Azure Overview and Deployment
## Lab 3 - UbuntuVM, Docker, and Cafe or Garage Demo Deployment
## Lab 4 - AKS / Nginx Ingress Controller / Cafe or Garage Demo Deployment
## Lab 5 - Nginx Load Balancing / Reverse Proxy
## Lab 6 - Azure Key Vault / TLS Essentials
## Lab 7 - Azure Montoring / Logging Analytics
## Lab 8 - Nginx Garage or Azure Petshop
## Lab 9 - Nginx and AzureAD / Entra Integration
## Lab 10 - Nginx Caching / Juiceshop or Garage
## Lab 11 - Optional Exercises / Grafana
## Summary and Wrap-up

<br/>

### Lab 0 - Prequesites - Subscription / Resources

- Overview
In this Lab, the requirements for both the student and the Azure environment will be detailed.  It is imperative that you have the appropriate computer, tools, and Azure access to successfully complete the workshop.  The Lab exercises must be done sequentially to build the environment as described.

- Learning Objectives
Verify you have the proper computer requirements - hardware and software.
- Hardware:  Laptop, Admin rights, Internet connection
- Software:  Visual Studio, Terminal, Chrome, Docker, AKS and AZ CLI.
Verify you have proper computer skills.
- Computer skills:  Linux CLI, files, SSH/Terminal, Docker/Compose, Azure Portal, HTTP/S, Load Balancing concepts
- Optional: TLS, DNS, FIPS, HTTP caching, Prometheus, Grafana
Verify you have the proper access to Azure resources.
- Azure subscription, list of Azure Roles/permissions here

- Nginx for Azure Workshop has minimum REQUIRED Nginx Skills
Students must be familiar with Nginx basic operation, configurations, and concepts for HTTP traffic.
-- The Nginx Basics Workshop is HIGHLY recommended, students should have taken this workshop prior.
-- The Nginx Plus Ingress Controller workshop is also HIGHLY, students should have taken this workshop prior.

<br/>

### Lab 1 - Azure VNet and Subnet and Network Security Group

- Overview
In this lab, you will be adding and configuring the Azure Networking components needed for this workshop.  This will require only a few network resources, and a Network Security Group to allow incoming traffic to your Azure resources.

- Learning Objectives
Setup your Azure Vnet
Setup your Azure Subnets
Setuo your Azure Network Security group for inbound traffic

<br/>

### Lab 2 - Nginx for Azure Overview and Deployment

- Overview
In this lab, you will deploy and config a new Nginx for Azure instance.

- Learning Objectives
Deploy Nginx for Azure
Enable Log Analytics
Test basic HTTP traffic
Create inital Nginx configurations to test with

<br/>

### Lab 3 - UbuntuVM, Docker, and Cafe or Garage Demo Deployment

- Overview
In this lab, you will deploy and Ubuntu VM, and configure it for a Legacy web application.

- Learning Objectives
Deploy Ubuntu VM
Install Docker and Docker-compose
Run Legacy docker container apps
Configure Nginx Load Balancing for these apps

<br/>

### Lab 4 - AKS / Nginx Ingress / Redis / Cafe or Garage Demo Deployment

- Overview
In this lab, you will deploy 2 AKS clusters, with Nginx Ingress Controllers, a Redis cluster, and a Modern Web Application.

- Learning Objectives
Deploy 2 AKS clusters using the Azure AZ CLI.
Deploy Nginx Plus Ingress Controller to Azure Container Registry, and to the Clusters.
Deploy and test a Redis In Memory Cache to the AKS cluster.
Configure Nginx Ingress for Redis Leader traffic.
Deploy a modern web application in the cluster.
Configure Nginx Ingress Controller to route traffic to the application.

<br/>

### Lab 5 - Nginx Load Balancing / Reverse Proxy

- Overview
In this lab, you will configure Nginx for Azure to Load Balance various workloads running in Azure.  After successful configuration and adding Best Practice Nginx parameters, you will Load Test these applications, and test multiple load balancing and request routing parameters to suit different use cases.

- Learning Objectives
Configure Nginx for Azure, to Load Balance traffic to both AKS Nginx Ingress Controllers.
Expose the NIC Plus Dashboards externally for Live Monitoring
Configure HTTP Split Clients, and route traffic to all 3 backend systems.
Load test the Legacy and Modern web applications.

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

### Lab 9 - Nginx and AzureAD / Entra Integration

- Overview
In this lab, you will create and configure an Azure Active Directory integration that will provide User based authentication to your web application.  You will then create and test the Nginx for Azure AD configuration that will enforce this user authentication requirement.

- Learning Objectives
Create and configure Azure AD Security settings.
Create and configure Nginx for Azure to provide user authentication to your web application.
Test and validate AzureAD is working as expected.
Explore AzureAD related logging.

<br/>

### Lab 10 - Nginx Caching / Garage / Juiceshop

- Overview
In this lab, you will deploy an image rich application, and use Nginx Caching to cache images to improve performance.

- Learning Objectives
Deploy JuiceShop in AKS cluster.
Expose JuiceShop with Nginx Ingress Controller
Configure Nginx for Azure for load balancing JuiceShop.
Add Nginx Caching to improve delivery of images.

<br/>

### Lab 11 - Optional Exercises

Optional - Grafana with Azure
- Overview
In this lab, you will explore the Nginx and Grafana for Azure integration.

- Learning Objectives
Deploy Grafana for Azure.
Configure the Datasource
Explore a sample Grafana Dashboard for Nginx for Azure


<br/>

### Summary and Wrap-up

- Summary and Wrap-up comments here