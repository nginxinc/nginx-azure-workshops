# NGINX Garage (UNDER CONSTRUCTION)


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

Set some environment variables to be used when creating the Azure Resources:

```shell
# Modify these as desired
export MY_RESOURCEGROUP="${MY_RESOURCEGROUP:-$(whoami)-n4a-workshop}"
export SAS_EXPIRY=2024-12-31Z23:59:59
export REDIS_CONNECTION_STRING=redis.example.com:6379
export LOCATION=westus2

# Using the ticks value ensures the naming requirements for Azure Resources are met 
timestamp=$(date +%s)
milliseconds=$(date +%N | awk '{print $1 / 1000}')
export TICKS="$timestamp$milliseconds"
export STORAGE_ACCOUNT_NAME="mygsa$TICKS"
export STORAGE_CONTAINER_NAME="mygsa$TICKS"
export SAS_TOKEN_NAME="mygsas$TICKS"
export APP_CONFIG_NAME="mygac$TICKS"
export OWNER=$(whoami)
  
# These correspond to the keys in the AppConfig that the My Garage application will use to access the resources, do not modify
export SAS_TOKEN_APP_CONFIG_KEY="AzureStorageSasToken"
export STORAGE_CONNECTION_STRING_CONFIG_KEY="AzureStorageConnectionString"      
export STORAGE_CONTAINER_NAME_CONFIG_KEY="AzureStorageContainerName"
export REDIS_CONNECTION_STRING_CONFIG_KEY="RedisConnectionString"
```

### Lab exercise 1

In this exercise you will establish the necessary Azure resources to deploy the My Garage application. There are two Azure resources that need to be created: 

1. A Storage Account to store the images for the photo gallery	
1. An AppConfig to store configuration settings for the My Garage application

   1. First, let's establish the Storage Account. Containers, where the Photo Gallery files will be saved, are created in the Storage Account.
   The `--allow-blob-public-access true` is required to allow the container to be public.

       ```shell
       az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $MY_RESOURCEGROUP --location $LOCATION --sku Standard_LRS --kind StorageV2 --access-tier Cool --allow-blob-public-access true --tags owner=$OWNER
       ```

      Sample output

      ```shell
      {
         "accessTier": "Cool",
         "accountMigrationInProgress": null,
         "allowBlobPublicAccess": true,
         "allowCrossTenantReplication": false,
         "allowSharedKeyAccess": null,
         "allowedCopyScope": null,
         "azureFilesIdentityBasedAuthentication": null,
         "blobRestoreStatus": null,
         "creationTime": "2024-05-30T19:44:17.165991+00:00",
         "customDomain": null,
         "defaultToOAuthAuthentication": null,
         "dnsEndpointType": null,
         "enableHttpsTrafficOnly": true,
         "enableNfsV3": null,
         "encryption": {
         "encryptionIdentity": null,
         "keySource": "Microsoft.Storage",
         "keyVaultProperties": null,
         "requireInfrastructureEncryption": null,
         "services": {
         "blob": {
         "enabled": true,
         "keyType": "Account",
         "lastEnabledTime": "2024-05-30T19:44:17.322273+00:00"
      },
         "file": {
         "enabled": true,
         "keyType": "Account",
         "lastEnabledTime": "2024-05-30T19:44:17.322273+00:00"
      },
      {
         "queue": null,
         "table": null
      },
         "extendedLocation": null,
         "failoverInProgress": null,
         "geoReplicationStats": null,
         "id": "/subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/ciroque-n4-workshop/providers/Microsoft.Storage/storageAccounts/mygsa1717095655594493",
         "identity": null,
         "immutableStorageWithVersioning": null,
         "isHnsEnabled": null,
         "isLocalUserEnabled": null,
         "isSftpEnabled": null,
         "isSkuConversionBlocked": null,
         "keyCreationTime": {
         "key1": "2024-05-30T19:44:17.306681+00:00",
         "key2": "2024-05-30T19:44:17.306681+00:00"
      },
         "keyPolicy": null,
         "kind": "StorageV2",
         "largeFileSharesState": null,
         "lastGeoFailoverTime": null,
         "location": "westus2",
         "minimumTlsVersion": "TLS1_0",
         "name": "mygsa1717095655594493",
         "networkRuleSet": {
         "bypass": "AzureServices",
         "defaultAction": "Allow",
         "ipRules": [],
         "ipv6Rules": [],
         "resourceAccessRules": null,
         "virtualNetworkRules": []
      },
         "primaryEndpoints": {
         "blob": "https://mygsa1717095655594493.blob.core.windows.net/",
         "dfs": "https://mygsa1717095655594493.dfs.core.windows.net/",
         "file": "https://mygsa1717095655594493.file.core.windows.net/",
         "internetEndpoints": null,
         "microsoftEndpoints": null,
         "queue": "https://mygsa1717095655594493.queue.core.windows.net/",
         "table": "https://mygsa1717095655594493.table.core.windows.net/",
         "web": "https://mygsa1717095655594493.z5.web.core.windows.net/"
      },
         "primaryLocation": "westus2",
         "privateEndpointConnections": [],
         "provisioningState": "Succeeded",
         "publicNetworkAccess": null,
         "resourceGroup": "ciroque-n4-workshop",
         "routingPreference": null,
         "sasPolicy": null,
         "secondaryEndpoints": null,
         "secondaryLocation": null,
         "sku": {
         "name": "Standard_LRS",
         "tier": "Standard"
      },
      "statusOfPrimary": "available",
      "statusOfSecondary": null,
      "storageAccountSkuConversionStatus": null,
      "tags": {
      "owner": "ciroque"
      },
        "type": "Microsoft.Storage/storageAccounts"
      }
      ```

1. After this is created, grab the Account Key for later use...

    ```shell
    export ACCOUNT_KEY=$(az storage account keys list --resource-group $MY_RESOURCEGROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" --output tsv)
    echo $ACCOUNT_KEY
    ```

1. Add CORS to ensure that the storage account can be accessed from the web

    ```shell
    az storage cors add --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY --services b --origins "*" --methods GET HEAD --allowed-headers "*" --exposed-headers "*" --max-age 3600
    ```

1. The Storage Connection String is necessary for the App Configuration Store, it is used to let the Application store images

    ```shell
    export STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name $STORAGE_ACCOUNT_NAME --resource-group $MY_RESOURCEGROUP --output tsv)
    echo $STORAGE_CONNECTION_STRING
    ```

1. Storage Container, The Place to Store Images

    ```shell
    az storage container create --name $STORAGE_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY --public-access blob
    ```
   
   Sample output:

   ```shell
   {
      "created": true
   }
   ```

1. The App Configuration Store, The Place to Store Configuration

    ```shell
    az appconfig create --name $APP_CONFIG_NAME --resource-group $MY_RESOURCEGROUP --location $LOCATION --sku Standard --query id --output tsv
    ```

   Sample output:
      
   ```shell
   /subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/ciroque-n4-workshop/providers/Microsoft.AppConfiguration/configurationStores/mygac1717095655594493
   ```

1. The Web Application -- My Garage -- needs this to be able to connect to the AppConfig instance and grab configuration

    ```shell
    export APP_CONFIG_CONNECTION_STRING=$(az appconfig credential list --name $APP_CONFIG_NAME --resource-group $MY_RESOURCEGROUP --query "[?name=='Primary Read Only'].connectionString" -o tsv)
    echo $APP_CONFIG_CONNECTION_STRING
    ```

   Sample output:

   ```shell
   Endpoint=https://mygac1717095655594493.azconfig.io;Id=FdhE;Secret=7mx92osNJalVfzg7AkDllEaDT8yqeSxNLWggm5m44SGq5cJ5KgBfJQQJ99AEAC8vTIns17ujAAABAZACYsE6
   ```

   1. The values required by the application need to be seeded. Note that all except for the RedisConnectionString have been gathered by this script

       ```shell
       az appconfig kv set --yes --name $APP_CONFIG_NAME --key $STORAGE_CONNECTION_STRING_CONFIG_KEY --value "$STORAGE_CONNECTION_STRING"
       az appconfig kv set --yes --name $APP_CONFIG_NAME --key $STORAGE_CONTAINER_NAME_CONFIG_KEY --value "$STORAGE_CONTAINER_NAME"
       az appconfig kv set --yes --name $APP_CONFIG_NAME --key $REDIS_CONNECTION_STRING_CONFIG_KEY --value "$REDIS_CONNECTION_STRING"
    
       echo "AppConfig Connection String: $APP_CONFIG_CONNECTION_STRING"
       ```

      Sample output:

      ```shell
      {
         "contentType": "",
         "etag": "-E-bQ-9J3tM60m1wMleds1D1X0HQZ10ImgOlOlnaG-k",
         "key": "AzureStorageConnectionString",
         "label": null,
         "lastModified": "2024-05-30T19:52:50+00:00",
         "locked": false,
         "tags": {},
         "value": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=mygsa1717095655594493;AccountKey=ZSuhwkwu8/w9CH/LJKEvOsD5npv3HIwKH7ZdvZif82bQyp63ub+XlFWdv7BznhsnCQT0TrLltyc4+AStI/S5xA==;BlobEndpoint=https://mygsa1717095655594493.blob.core.windows.net/;FileEndpoint=https://mygsa1717095655594493.file.core.windows.net/;QueueEndpoint=https://mygsa1717095655594493.queue.core.windows.net/;TableEndpoint=https://mygsa1717095655594493.table.core.windows.net/"
      }
      {
         "contentType": "",
         "etag": "4FCiXDJPWO_QKTU2SrkShDxakOxQHPFXLHcGAsPbd_4",
         "key": "AzureStorageContainerName",
         "label": null,
         "lastModified": "2024-05-30T19:52:52+00:00",
         "locked": false,
         "tags": {},
         "value": "mygsa1717095655594493"
      }
      {
      "contentType": "",
      "etag": "ZIbhl1qmkZk3U8fJ6P7JvehSof0v-30GYGpri5RmNMU",
      "key": "RedisConnectionString",
      "label": null,
      "lastModified": "2024-05-30T19:52:54+00:00",
      "locked": false,
      "tags": {},
      "value": "redis.example.com:6379"
      }

      AppConfig Connection String: Endpoint=https://mygac1717095655594493.azconfig.io;Id=FdhE;Secret=7mx92osNJalVfzg7AkDllEaDT8yqeSxNLWggm5m44SGq5cJ5KgBfJQQJ99AEAC8vTIns17ujAAABAZACYsE6   
      ```

### Lab exercise 2

In this exercise you will establish the NGINX for Azure configuration. 



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

Navigate to ([Lab9](../lab9/readme.md) | [LabGuide](../readme.md))
