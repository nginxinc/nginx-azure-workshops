# Azure Montoring / Logging Analytics

## Introduction

In this lab, you will explore Azure based monitoring and Logging capabilities. You will create the basic access log_format within NGINX for Azure resource. As the basic log_format only contains a fraction of the information, you will then extend it and create a new log_format to include much more information, especially about the Upstream backend servers. You will add access logging to your NGINX for Azure resource and finally capture/see those logs within Azure monitoring tools.

NGINX aaS | Docker
:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Enable basic log format within NGINX for Azure resource

- Create enhance log format with additional logging metrics

- Test access logs within log analytics workspace

- Explore Azure Monitoring for NGINX for Azure

## Pre-Requisites

- Within your NGINX for Azure resource, you must have enabled sending metrics to Azure monitor.
  
- You must have created `Log Analytics workspace`.
- You must have created an Azure diagnostic settings resource that will stream the NGINX logs to the Log Analytics workspace.
- See `Lab1` for instructions if you missed any of the above steps.

<br/>

### Enable basic log format

1. Within Azure portal, open your resource group and then open your NGINX for Azure resource (nginx4a). From the left pane click on `Settings > NGINX Configuration`. This should open the configuration editor section. Open `nginx.conf` file.

    ![NGINX Config](media/lab6_nginx_conf_editor.png)

1. You will notice in previous labs, you have added the default basic log format inside the `http` block within the `nginx.conf` file as highlighted in above screenshot. You will make use of this log format initially to capture some useful metrics within NGINX logs.

    ```nginx
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    ```

1. Update the `access_log` directive to enable logging. Within this directive, you will pass the full path of the log file (eg. `/var/log/nginx/access.log`) and also the `main` log format that you created in previous step. Click on `Submit` to apply the changes.

    ```nginx
    access_log  /var/log/nginx/access.log  main;
    ```

    ![Access log update](media/lab6_main_access_log_update.png)

1. In subsequent sections you will test out the logs inside log analytics workspace.

### Create enhance log format with additional logging metrics

In this section you will create an extended log format which you will use with `cafe.example.com` server's access log.

1. Within the NGINX for Azure resource (nginx4a), open the `Settings > NGINX Configuration` pane.

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

    ![Extended log format add](media/lab6_main_ext_logformat_add.png)

1. Once the extended log format has been created, open `cafe.example.com.conf` file and update the `access_log` to make use of the extended log format as shown in the below screenshot. Click on `Submit` to apply the changes.

    ```nginx
    access_log  /var/log/nginx/cafe.example.com.log main_ext;
    ```

    ![cafe access log format update](media/lab6_cafe_access_log_update.png)

1. In next section, you will test out the extended log format within inside log analytics workspace.

### Test the access logs within log analytics workspace

1. To test out access logs, generate some traffic on your `cafe.example.com` server.

1. You can generate some traffic using your local Docker Desktop. Start and run the `WRK` load generation tool from a container using below command to generate traffic:

   First save your NGINX for Azure resource public IP in a environment variable.

    ```bash
    ## Set environment variables
    export MY_RESOURCEGROUP=s.dutta-workshop
    export MY_N4A_IP=$(az network public-ip show \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-publicIP \
    --query ipAddress \
    --output tsv)    
    ```

    Make request to the default server block which is using the `main` log format for access logging by running below command.

    ```bash
    docker run --name wrk --rm williamyeh/wrk -t4 -c200 -d1m --timeout 2s http://$MY_N4A_IP
    ```

    Make request to the `cafe.example.com` server block which is using the `main_ext` log format for access logging by running below command.

    ```bash
    docker run --name wrk --rm williamyeh/wrk -t4 -c200 -d1m --timeout 2s -H 'Host: cafe.example.com'  http://$MY_N4A_IP/coffee
    ```

1. Within Azure portal, open your NGINX for Azure resource (nginx4a). From the left pane click on `Monitoring > Logs`. This should open a new Qeury pane. Select `Resource type` from drop down and then type in `nginx` in the search box. This should show all the sample queries related to NGINX for Azure. Under `Show NGINXaaS access logs` click on `Run` button

    ![nginx4a logs](media/nginx4a_logs.png)

1. This should open a `new query` window, which is made up of a query editor pane at the top and query result pane at the bottom as shown in below screenshot.

    ![default query](media/lab6_default_query.png)

    > **NOTE:** The logs may take couple of minutes to show up. If the results pane doesn't show the logs then wait for a minute and then click on the `Run` button to run the query again.

1. Azure makes use of Kusto Query Language(KQL) to query logs. Have a look in the [references](#references) section to learn more about KQL.

1. You will modify the default query to show logs for `cafe.example.com` server block. Update the default query with the below query in the query editor pane. Click on the `Run` button to execute the query.

    ```kql
    // Show NGINXaaS access logs 
    // A list of access logs sorted by time. 
    NGXOperationLogs
    | where FilePath == "/var/log/nginx/cafe.example.com.log"
    | sort by TimeGenerated desc
    | project TimeGenerated, FilePath, Message
    | limit 100
    ```

    ![cafe query](media/lab6_cafe_query.png)

1. Within the Results pane, expand one of the logs to look into its details. You can also hover your mouse over the message to show the message details as shown in below screenshot. Note that the message follows the `main_ext` log format.

    ![cafe query details](media/lab6_cafe_query_details.png)

1. You can save the custom query if you wish by clicking on the `Save` button and then selecting `Save as query`. Within the `Save as query` pane provide a query name and optional description and then finally click on `Save` button.

    ![cafe query save](media/lab6_cafe_query_save.png)

### Explore Azure Monitoring for NGINX for Azure

1. Within the NGINX for Azure resource (nginx4a), open the `Settings > NGINX Configuration` pane.

1. Modify the `includes/split-clients.conf` file, to set traffic split ratio as 30% to aks1_ingress, 30% to aks2_ingress and rest 40% to cafe_nginx:

    ```nginx
    # Nginx 4 Azure to AKS1/2 NICs and/or UbuntuVMs for Upstreams
    # Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
    # HTTP Split Clients Configuration for AKS Cluster1/Cluster2 or UbuntuVM ratios
    #
    split_clients $request_id $upstream {

        # Uncomment the percent wanted for AKS Cluster #1, #2, or UbuntuVM
        # 0.1% aks1_ingress;
        # 1.0% aks1_ingress;
        # 5.0% aks1_ingress;
        30% aks1_ingress;      # 30% traffic to AKS1
        # 50% aks1_ingress;
        # 80% aks1_ingress;
        # 95% aks1_ingress;
        # 99% aks1_ingress;
        # * aks1_ingress;
        30% aks2_ingress;      # 30% traffic to AKS2
        * cafe_nginx;          # Rest 40% traffic to Ubuntu VM containers
        # * aks1_nic_direct;    # Direct to NIC pods - headless/no nodeport

    }
    ```

1. Within the `cafe.example.com.conf` file, modify the `proxy_pass` directive in your `location /` block, to use the `$upstream` variable. Click on Submit to save the config file

    ```nginx
    ...
        location / {
            #
            # return 200 "You have reached cafe.example.com, location /\n";
            
            # proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
            # add_header X-Proxy-Pass cafe_nginx;  # Custom Header

            # proxy_pass http://windowsvm;        # Proxy AND load balance to a list of servers
            # add_header X-Proxy-Pass windowsvm;  # Custom Header

            # proxy_pass http://aks1_ingress;        # Proxy AND load balance to AKS1 Nginx Ingress
            # add_header X-Proxy-Pass aks1_ingress;  # Custom Header

            # proxy_pass http://aks2_ingress;        # Proxy AND load balance to AKS2 Nginx Ingress
            # add_header X-Proxy-Pass aks2_ingress;  # Custom Header

            proxy_pass http://$upstream;            # Use Split Clients config
            add_header X-Proxy-Pass $upstream;      # Custom Header

        }

    ...
    ```

1. Now generate some steady traffic using your local Docker Desktop. Start and run the `WRK` load generation tool from a container using below command to generate traffic:

    ```bash
    docker run --name wrk --rm williamyeh/wrk -t4 -c200 -d30m --timeout 2s http://cafe.example.com/coffee
    ```

    The above command would run for 30 minutes and send request to `http://cafe.example.com/coffee` using 4 threads and 200 connections.

1. Within Azure portal, open your NGINX for Azure resource (nginx4a). From the left pane click on `Monitoring > Metrics`. This should open a new Chart pane as shown in below screenshot.

    ![default chart](media/lab6_default_chart.png)

1. For the first chart, within **Metric Namespace** drop-down, select `nginx requests and response statistics`. For the **metrics** drop-down, select `plus.http.request.count`. For the **Aggregation** drop-down, select `Avg`.

   Click on the **Apply Splitting** button. Within the **Values** drop-down, select `server_zone`. From top right change the **Time range** to `Last 30 minutes` and click on `Apply`. This should generate a chart similar to below screenshot.

    ![server zone request chart](media/lab6_server_request_chart.png)

1. You will now save this chart in a new custom dashboard. Within the chart pane, click on `Save to dashboard > Pin to dashboard`.

    Within the `Pin to dashboard` pane, select the `Create new` tab to create your new custom dashboard. Provide a name  for your custom dashboard. Once done click on `Create and pin` button to finish dashboard creation.

    ![Create Dashboard](media/lab6_create_dashboard.png)

1. To view your newly created dashboard, within Azure portal, navigate to `Dashboard` resource.

    By default, this should open the default `My Dashboard` private dashboard. From the top drop-down select your custom dashboard name (`Nginx4a Dashboard`in the screenshot). This should open your custom dashboard which includes the pinned server request chart.

    ![show dashboard](media/lab6_show_dashboard.png)

1. Now you will add some more charts to your newly created dashboard. Navigate back to NGINX for Azure resource (nginx4a) and from the left pane click on `Monitoring > Metrics`.

1. Within the chart pane, click on **Metric Namespace** drop-down and select `nginx upstream statistics`. For the **metrics** drop-down, select `plus.http.upstream.peers.response.time`. For the **Aggregation** drop-down, select `Avg`.

    Click on the **Add filter** button. Within the **Property** drop-down, select `upstream`. Leave the **Operator** to `=`. In **values** drop-down, select `aks1_ingress`, `aks2_ingress` and `cafe_nginx`.

    Click on the **Apply Splitting** button. Within the **Values** drop-down, select `upstream`. From top right change the **Time range** to `Last 30 minutes` and click on `Apply`. This should generate a chart similar to below screenshot.

    ![upstream response time chart](media/lab6_upstream_response_time_chart.png)

1. You will now pin this chart to your custom dashboard. Within the chart pane, click on `Save to dashboard > Pin to dashboard`.

    Within the `Pin to dashboard` pane, by default the `Existing` tab should be open with your recently created dashboard selected. Click on `Pin` button to pin the chart to your dashboard.

    ![pin upstream chart](media/lab6_pin_upstream_chart.png)

1. Navigate back to `Dashboard` resource within Azure portal and select your dashboard. You will notice that the chart that you recently pinned shows up in your dashboard.

    ![upstream chart dashboard](media/lab6_upstream_chart_dashboard.png)

    You can also edit your dashboard by clicking on the pencil icon to reposition/resize charts as per your taste.

1. Please look into the [References](#references) section to check the metric catalog and explore various other metrics available with NGINX for Azure. Feel free to play around and pin multiple metrics to your dashboard.

<br/>

**This completes Lab6.**

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
  
- [Kusto Query Language](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/tutorials/learn-common-operators)

- [NGINX Metrics catalog](https://docs.nginx.com/nginxaas/azure/monitoring/metrics-catalog/)

- [NGINX - Join Community Slack](https://community.nginx.org/joinslack)

<br/>

### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to ([Lab7](../lab7/readme.md) | [LabGuide](../readme.md))
