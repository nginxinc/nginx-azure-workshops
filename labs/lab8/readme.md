#  NGINX My Garage


## Introduction


In this lab, you will install the My Garage application, configure it for external access, learn to scale the web service, and set up caching for the image gallery (optional).

The My Garage application is a modern web application built using Microsoft .Net technologies. It is comprised of a frontend application and supporting web service backend. The front-end is a Single Page Application (SPA) that uses [Blazor WebAssembly](https://dotnet.microsoft.com/en-us/apps/aspnet/web-apps/blazor) to render the UI in the browser. The back-end is a RESTful API built using [ASP.Net Core MVC](https://learn.microsoft.com/en-us/aspnet/core/mvc/overview?view=aspnetcore-8.0).

| ![My Garage Home Page](./MyGarage-Home.png) | ![My Garage Vehicles Page](./MyGarage-Vehicles.png) |
|------|------|
| ![My Garage Photo Gallery Page](./MyGarage-PhotoGallery.png) | ![My Garage Seed Data Page](./MyGarage-SeedData.png) |


## Learning Objectives

By the end of the lab you will be able to:

- Create all the resources necessary to deploy the My Garage application
- Ensure the My Garage application is accessible from the internet
- Monitor traffic to the My Garage application using the NGINX Dashboard

## Pre-Requisites@A

You need to have followed the labs up to this point. Specifically, Lab 0 and Lab 4 are required to have been completed. 

- You must have the Azure CLI installed and configured to manage Azure Resources
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Docker concepts and commands
- You must have created a Resource Group

<br/>

### Lab exercise 1

In this exercise you will establish the necessary Azure resources to deploy the My Garage application. There are two Azure resources that need to be created: 

1. A Storage Account to store the images for the photo gallery	
1. An AppConfig to store configuration settings for the My Garage application

First, let's establish the Storage Account.

Shell script to create the Azure resources:
```shell
#!/bin/sh

# establish-azure-resources.sh
#
# This script creates all the Micorosft Azure Resources needed to run the My Garage application.
#
# The script assumes that you have the Azure CLI installed and configured to point to the desired Azure Subscription.

function calculate_ticks() {
  timestamp=$(date +%s)
  milliseconds=$(date +%N | awk '{print $1 / 1000}')
  ticks="$timestamp$milliseconds"
  echo $ticks | sed 's/\.//g'
}

clear

# These need to be set by the user before running the script
resourceGroupName="<YOUR_RESOURCE_GROUP_NAME>"
sasExpiry="<YOUR_EXPIRY_DATE_AND_TIME>"
redisConnectionString="<YOUR_REDIS_CONNECTION_STRING>"

ticks=$(calculate_ticks)
location=westus2
storageAccountName="mygsa$ticks"
storageContainerName="mygsc$ticks"
sasTokenName="mygsas$ticks"
appConfigName="mygac$ticks"
owner=$(whoami)

# These correspond to the keys in the AppConfig that the My Garage application will use to access the resources, do not modify
sasTokenAppConfigKey="AzureStorageSasToken"
storageConnectionStringConfigKey="AzureStorageConnectionString"      
storageContainerNameConfigKey="AzureStorageContainerName"
redisConnectionStringConfigKey="RedisConnectionString"


## Create the stuff
echo Creating Resources...

# Storage Account, The Place to Store Stuff
# * The --allow-blob-public-access true is required to allow the container to be public
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS --kind StorageV2 --access-tier Cool --allow-blob-public-access true --tags owner=$owner

# The Account Key is needed for subsequent resources
accountKey=$(az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query "[0].value" --output tsv)

# CORS ensure that the storage account can be accessed from the web
az storage cors add --account-name $storageAccountName --account-key $accountKey --services b --origins "*" --methods GET HEAD --allowed-headers "*" --exposed-headers "*" --max-age 3600

# The Storage Connection String is necessary for the App Configuration Store, it is used to let the Application store images
storageConnectionString=$(az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --output tsv)

# Storage Container, The Place to Store Images
az storage container create --name $storageContainerName --account-name $storageAccountName --account-key $accountKey --public-access blob

# The App Configuration Store, The Place to Store Configuration
az appconfig create --name $appConfigName --resource-group $resourceGroupName --location $location --sku Standard --query id --output tsv

# The Web Application -- My Garage -- needs this to be able to connect to the AppConfig instance and grab configuration
appConfigConnectionString=$(az appconfig credential list --name $appConfigName --resource-group $resourceGroupName --query "[?name=='Primary Read Only'].connectionString" -o tsv)

# The values required by the application need to be seeded. Note that all except for the RedisConnectionString have been gathered by this script
az appconfig kv set --yes --name $appConfigName --key $storageConnectionStringConfigKey --value "$storageConnectionString"
az appconfig kv set --yes --name $appConfigName --key $storageContainerNameConfigKey --value "$storageContainerName"
az appconfig kv set --yes --name $appConfigName --key $redisConnectionStringConfigKey --value "$redisConnectionString"

# Burp out the AppConfig ConnectionString so it can be included in the MyGarage application startup. It is an argument to the docker-compose command:
# The docker-compose file will be updated to include this value in the environment variables
echo "AppConfig Connection String: $appConfigConnectionString"


```

PowerShell script to create the Azure resources:
```powershell
<#
    establish-azure-resources.ps1

    This script creates all the Micorosft Azure Resources needed to run the My Garage application.

    The script assumes that you have the Azure CLI installed and configured to point to the desired Azure Subscription.
#>

# These need to be set by the user before running the script
$ResourceGroupName = "<YOUR_RESOURCE_GROUP_NAME>"                       # **User Input: This is the name of the Resource Group created in previous labs
$SasExpiry = "<YOUR_EXPIRY_DATE_AND_TIME>"                              # **User Input: Example: "2024-12-31T23:59:59Z"
$RedisConnectionString = "<YOUR_REDIS_CONNECTION_STRING>"               # **User Input: This is the connection string for the Redis Cache

$Ticks = (Get-Date).Ticks                                               # This is used to make the resource names unique
$Location = "westus2"                                                   # Change this to the Azure Region of choice
$StorageAccountName = "mygsa" + $Ticks
$StorageContainerName = "mygsc" + $Ticks
$SasTokenName = "mygsas" + $Ticks
$AppConfigName = "mygac" + $Ticks
$owner = $(whoami)                                                      # Used for tagging resources, change as desired

# These correspond to the keys in the AppConfig that the My Garage application will use to access the resources, do not modify
$SasTokenAppConfigKey = "AzureStorageSasToken"
$StorageConnectionStringConfigKey = "AzureStorageConnectionString"      
$StorageContainerNameConfigKey = "AzureStorageContainerName"
$RedisConnectionStringConfigKey = "RedisConnectionString"

clear

<# -------------------------------- #>
<# Create a new set of stuff #>

echo "Creating resources..."
    
# Storage Account, The Place to Store Stuff
# * The --allow-blob-public-access true is required to allow the container to be public
az storage account create --name $StorageAccountName --resource-group $ResourceGroupName --location $Location --sku Standard_LRS --kind StorageV2 --access-tier Cool --allow-blob-public-access true --tags environment=production owner=$owner

# The Account Key is needed for subsequent resources
$accountKey=$(az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountName --query "[0].value" --output tsv)

# CORS ensure that the storage account can be accessed from the web
az storage cors add --account-name $StorageAccountName --account-key $accountKey --services b --origins "*" --methods GET HEAD --allowed-headers "*" --exposed-headers "*" --max-age 3600

# The Storage Connection String is necessary for the App Configuration Store, it is used to let the Application store images
$storageConnectionString=$(az storage account show-connection-string --name $StorageAccountName --resource-group $ResourceGroupName --output tsv)

# Storage Container, The Place to Store Images
az storage container create --name $StorageContainerName --account-name $StorageAccountName --account-key $accountKey --public-access blob

# The App Configuration Store, The Place to Store Configuration
az appconfig create --name $AppConfigName --resource-group $ResourceGroupName --location $Location --sku Standard --query id --output tsv

# The Web Application -- My Garage -- needs this to be able to connect to the AppConfig instance and grab configuration
$appConfigConnectionString=$(az appconfig credential list --name $AppConfigName --resource-group $ResourceGroupName --query "[?name=='Primary Read Only'].connectionString" -o tsv)

# The values required by the application need to be seeded. Note that all except for the RedisConnectionString have been gathered by this script
az appconfig kv set --yes --name $AppConfigName --key $StorageConnectionStringConfigKey --value "$storageConnectionString"
az appconfig kv set --yes --name $AppConfigName --key $StorageContainerNameConfigKey --value "$StorageContainerName"
az appconfig kv set --yes --name $AppConfigName --key $RedisConnectionStringConfigKey --value "$RedisConnectionString"

# Burp out the AppConfig ConnectionString so it can be included in the MyGarage application startup. It is an argument to the docker-compose command:
# The docker-compose file will be updated to include this value in the environment variables
echo "AppConfig Connection String: $appConfigConnectionString"

```


<numbered steps are here>

### Lab exercise 2

<numbered steps are here>

### Lab exercise 3

<numbered steps are here>

### << more exercises/steps>>

<numbered steps are here>

<br/>

**This completes Lab8.**

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
- Steve Wagner - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to ([Lab9](../lab9/readme.md) | [LabX](../labX/readme.md))
