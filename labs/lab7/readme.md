# Azure Montoring / Logging Analytics

## Introduction

In this lab, you will explore Azure based monitoring and Logging capabilities. You will create the basic access log_format within NGINX for Azure resource. As the basic log_format only contains a fraction of the information, you will then extend it and create a new log_format to include much more information, especially about the Upstream backend servers. You will add access logging to your NGINX for Azure resource and finally capture/see those logs within Azure monitoring tools.

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Docker
:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Create and enable basic log format within NGINX for Azure resource

- Create enhance log format with additional logging metrics

- Test access logs within log analytics workspace

- Understanding Kusto Query Language (KQL) to pull out and print all access and error logs from log analytics workspace

## Pre-Requisites

- Within your NGINX for Azure resource, you must have enabled sending metrics to Azure monitor.
  
- You must have created `Log Analytics workspace`.
- You must have created an Azure diagnostic settings resource that will stream the NGINX logs to the Log Analytics workspace.
- See `Lab1` for instructions if you missed any of the above steps.

<br/>

### Create and enable basic log format

1. Within Azure portal, open your resource group and then open your NGINX for Azure resource (nginx4a). From the left pane click on `NGINX Configuration`. This should open the configuration editor section. Open `nginx.conf` file.
    ![NGINX Config](media/nginx_conf_editor.png)

1. Add below default basic log format inside the `http` block within the `nginx.conf` file as shown in the below screenshot. Click on `Submit` to save the config file.

    ```nginx
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    ```

    ![main logformat add](media/main_logformat_add.png)

1. Update the `access_log` directive to enable logging. Within this directive, you will pass the full path of the log file (eg. `/var/log/nginx/access.log`) and also the `main` log format that you created in previous step. Click on `Submit` to apply the changes.

    ```nginx
    access_log  /var/log/nginx/access.log  main;
    ```

    ![Access log update](media/main_access_log_update.png)

1. In subsequent sections you will test out the logs inside log analytics workspace.

### Create enhance log format with additional logging metrics

1. Within the NGINX for Azure resource (nginx4a), open the `NGINX Configuration` pane.

1. Within the `nginx.conf` file add a new extended log format named `main_ext` as shown in the below screenshot. Click on `Submit` to save the config file

    ```nginx
    # Extended Log Format
    log_format  main_ext    'remote_addr="$remote_addr", '
                            '[time_local=$time_local], '
                            'request="$request", '
                            'status="$status", '
                            'http_referer="$http_referer", '
                            'body_bytes_sent="$body_bytes_sent", '
                            'Host="$host", '
                            'sn="$server_name", '
                            'request_time=$request_time, '
                            'http_user_agent="$http_user_agent", '
                            'http_x_forwarded_for="$http_x_forwarded_for", '
                            'request_length="$request_length", '
                            'upstream_address="$upstream_addr", '
                            'upstream_status="$upstream_status", '
                            'upstream_connect_time="$upstream_connect_time", '
                            'upstream_header_time="$upstream_header_time", '
                            'upstream_response_time="$upstream_response_time", '
                            'upstream_response_length="$upstream_response_length", ';
    ```

    ![Extended log format add](media/main_ext_logformat_add.png)

1. Once the extended log format has been created, open `cafe.example.com.conf` file and update the `access_log` to make use of the extended log format as shown in the below screenshot. Click on `Submit` to apply the changes.

    ```nginx
    access_log  /var/log/nginx/cafe.example.com.log main_ext;
    ```

    ![cafe access log format update](media/cafe_access_log_update.png)

1. In subsequent sections you will test out the extended log format within inside log analytics workspace.

### Test the access logs within log analytics workspace

1. To test out access logs, generate some traffic on your `cafe.example.com` server.

1. Open your browser and send some request to [http://cafe.example.com](http://cafe.example.com) so that you can look into the access logs.

1. Within Azure portal, open your NGINX for Azure resource (nginx4a). From the left pane click on `Logs`. This should open a new Qeury pane. Select `Resource type` from drop down and then type in `nginx` in the searchbox. This should show all the sample queries related to NGINX for Azure. Under `Show NGINXaaS access logs` click on `Run` button

    ![nginx4a logs](media/nginx4a_logs.png)



### Understanding Kusto Query Language (KQL) to pull out and print all access and error logs from log analytics workspace

<numbered steps are here>

<br/>

**This completes Lab7.**

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

Navigate to ([Lab8](../lab8/readme.md) | [LabX](../labX/readme.md))
