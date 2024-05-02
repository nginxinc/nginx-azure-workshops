#  NGINX Load Balancing / Reverse Proxy 

## Introduction

In this lab, you will configure Nginx4Azure to Proxy and Load Balance several different backend systems, including Nginx Ingress Controllers in AKS, and a Windows VM.  You will create and configure the needed Nginx config files, and then verify access to these systems.  The Docker containers, VMs, or AKS Pods are running simple websites that represent web applications.  You will also configure and load balance traffic to a Redis in-memory cache running in the AKS cluster. The AKS Clusters and Nginx Ingress Controllers provide access to these various K8s workloads.


NGINX aaS | AKS | Nginx Ingress | Redis
:-----------------:|:-----------------:|:-----------------:|:-----------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![AKS](media/aks-icon.png) |![NIC](media/nginx-ingress-icon.png) |![NIC](media/redis-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Configure Nginx4Azure to Proxy and Load balance AKS workloads
- Configure Nginx4Azure to Proxy a Windows Server VM
- Test access to your N4A configurations with Curl and Chrome
- Inspect the HTTP content coming from these systems
- Run an HTTP Load Test on your systems
- Enable HTTP Split Clients for Blue/Green, A/B Testing
- Configure Nginx4Azure to Proxy to Nginx Ingress Headless

## Pre-Requisites

- You must have your Nginx4Azure instance up and running
- You must access to the N4A Configuration Panel in Azure Portal
- You must have both AKS Clusters with Nginx Ingress Controllers running
- You must have the sample application running in both clusters
- You must have curl and a modern Browser installed on your system
- You should have Redis Client Tools installed on your local system
- See `Lab0` for instructions on setting up your system for this Workshop

<br/>

< Lab specific Image here >

<br/>

### Nginx 4 Azure Proxy to AKS Clusters

This exercise will create Nginx Upstream configurations for the AKS clusters.  You will add the NodePorts of the Nginx Ingress Controllers running in AKS cluster 1, and AKS Cluster 2.  These were previously deployed and configured in a previous lab.  Now the fun part, sending traffic to them!

Using the Nginx4Azure configuration tool, create a new file called `/etc/nginx/conf.d/aks1-upstreams.conf`.  Copy and Paste the contents of the provided file.  You will have to EDIT this example config file, and change the `server` entries to match your AKS Cluster1 nodepool node names.  You can find your AKS1 nodepool nodenames from the Azure Portal.  Make sure you use `:32080` for the port number, this is the static `nginx-ingress NodePort Service` for HTTP traffic that was defined earlier.

```nginx

# Nginx 4 Azure to NIC, AKS Nodes for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# AKS1 nginx ingress upstreams
#
upstream aks1_ingress {
  zone aks1_ingress 256k;

  least_time last_byte;
  
  # from nginx-ingress NodePort Service / aks Node names
  # Note: change servers to match
  #
  server aks-userpool-76919110-vmss000002:32080;    #aks1 node1:
  server aks-userpool-76919110-vmss000003:32080;    #aks1 node2:

  keepalive 32;

   }

```

Submit your Changes.  If you have the Server names:port correct, Nginx4Azure will validate and return a Success message.

**Important!**  If you stop then re-start your AKS cluster, or scale up/down, or add/remove VMSS worker nodes in the AKS NodePools, this Upstream list `WILL` have to be updated to match!  Any changes to the Worker nodes in the Cluster will need to be matched exactly, as it is a static configuration that must match the Worker Nodes:NodePort definition in your AKS cluster.  If you change the static nginx-ingress NodePort Service, you will have to match it here as well.

Repeat the step above, but create a new file called `/etc/nginx/conf.d/aks2-upstreams.conf`, for your second, AKS2 Cluster:

```nginx
# Nginx 4 Azure to NIC, AKS Node for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# AKS2 nginx ingress upstreams
#
upstream aks2_ingress {
  zone aks2_ingress 256k;

  least_time last_byte;
  
  # from nginx-ingress NodePort Service / aks Node names
  # Note: change servers to match
  #
  server aks-nodepool1-19485366-vmss00000h:32080;    #aks node1:
  server aks-nodepool1-19485366-vmss00000i:32080;    #aks node2:
  server aks-nodepool1-19485366-vmss00000j:32080;    #aks node3: 

  keepalive 32;

}

```

Note, there are 3 upstreams, matching the 3 Worker Nodes in AKS2 cluster.

Submit your Changes.  If you have the Server name:port correct, Nginx4Azure will validate and return a Success message.

**Warning:**  If you stop and start your AKS cluster, or add/remove Nodes in the Pools, this Upstream list `WILL` have to be updated to match.  It is a static configuration that must match the Worker Nodes:NodePort definition in your AKS cluster. If you change the static nginx-ingress NodePort Service, you will have to match it here as well.  Unfortunately, there are no auto-magic way to synchronize AKS/NodePorts with N4A Upstreams... yet :-)

### Test Nginx 4 Azure to AKS1 Cluster Ingress Controller

Now that you have these new Nginx Upstream blocks created, you can test them.

Inspect, then modify the `# comments for proxy_pass` in the `location /` block in the `/etc/nginx/conf.d/cafe.example.com.conf` file, to disable the proxy_pass to `cafe-nginx`, and enable the proxy_pass to `aks1_ingress`, as shown:

```nginx
...

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";
         
        # proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        # proxy_pass http://vm1:32779;          # Proxy to another server
        # proxy_pass http://nginx.org;       # Proxy to another website
        
        proxy_pass http://aks1_ingress;       # Proxy to AKS1 Nginx Ingress Controller NodePort
        add_header X-Proxy-Pass aks1_ingress;  # Custom Header
        
        # proxy_pass http://aks2_ingress;       # Proxy to AKS2 Nginx Ingress Controller NodePort
        # proxy_pass http://aks1_nic_direct;       # Proxy to AKS Nginx Ingress Controller Direct
        # proxy_pass http://$upstream;          # Use Split Clients config

    }
...

```

This changes where Nginx will `proxy_pass` the requests.  Nginx will now forward and load balance requests to your AKS1 Ingress Controller, listening on port 32080 on each AKS1 Node.

Submit your change.

Test your change with curl.  Do you see the X-Proxy-Pass Header that you added, so you know which Upstream block is being used ?

```bash
HTTP/1.1 200 OK
Server: N4A-1.25.1-cakker
Date: Fri, 05 Apr 2024 20:08:24 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Expires: Fri, 05 Apr 2024 20:08:23 GMT
Cache-Control: no-cache
X-Proxy-Pass: aks1_ingress

```

Test your change in Upstreams with Chrome, hitting Refresh several times - what do you see ?

The Server Name and IP address should now match PODS running in your AKS1 cluster!  (they were Docker names before, remember?) But how do you verify this ?  Observe, the Server name is a K8s assigned POD name, and the Server IP address is the POD IP address, also assiged by K8s.  

Verify this with `kubectl`.  Set your Kubectl Config Context to aks1:

```bash
kubectl config use-context aks1

```

Then list the Pod names:
```bash
kubectl get pods
```

Notice the names of the coffee and tea pods.  Check the `coffee-svc` Endpoints:

```bash
kubectl describe svc coffee-svc

```

You should see a list of the POD IPs for the Service.

You can also see this list, using the Nginx Plus Dashboard for the Ingress Controller, check the HTTP Upstreams, you should see the Pod IPs for both the coffee-svc and tea-svc.

### Test Nginx 4 Azure to AKS2 Cluster Ingress Controller

Repeat the last procedure, to test access to the AKS2 Cluster and pods.

Change the `# comments for proxy_pass` in the `location /` block in the `/etc/nginx/conf.d/cafe.example.com.conf` file, to disable the proxy_pass to aks1_ingress, and enable the proxy_pass to `aks2_ingress`, as shown:

```nginx
...

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";
         
        # proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        # proxy_pass http://vm1:32779;          # Proxy to another server
        #proxy_pass http://aks1_ingress;       # Proxy to AKS1 Nginx Ingress Controller NodePort

        proxy_pass http://aks2_ingress;       # Proxy to AKS2 Nginx Ingress Controller NodePort
        add_header X-Proxy-Pass aks2_ingress;  # Custom Header
        
        # proxy_pass http://aks1_nic_direct;       # Proxy to AKS Nginx Ingress Controller Direct
        # proxy_pass http://$upstream;          # Use Split Clients config

    }
...

```

This again changes where Nginx will `proxy_pass` the requests.  Nginx will now forward and load balance requests to your AKS2 Ingress Controller, also listening on port 32080 on each AKS2 Node.

Submit your change.

Test your change with curl.  Do you see the X-Proxy-Pass Header that you added, so you know which Upstream block is being used ?

```bash
HTTP/1.1 200 OK
Server: N4A-1.25.1-cakker
Date: Fri, 05 Apr 2024 20:08:24 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Expires: Fri, 05 Apr 2024 20:08:23 GMT
Cache-Control: no-cache
X-Proxy-Pass: aks2_ingress

```

Test your change in Upstreams with Chrome, hitting Refresh several times - what do you see ?

The Server Name and IP address should now match PODS running in your AKS2 cluster!  (they were AKS1 names before) But how do you verify this ?  Observe again, the Server name is a K8s assigned POD name, and the Server IP address is the POD IP address, also assiged by K8s.  

Verify this with `kubectl`.  Set your Kubectl Config Context to aks2:

```bash
kubectl config use-context aks2

```

Then list the Pods:

```bash
kubectl get pods

```

Notice the names of the coffee and tea pods.  Check the `coffee-svc` Endpoints:

```bash
kubectl describe svc coffee-svc

```

You should see a list of the POD IPs for the Service.

You can also see this list, using the Nginx Plus Dashboard for the Ingress Controller, check the HTTP Upstreams, you should see the Pod IPs for both the coffee-svc and tea-svc.

### Summary

During this Lab exercise, you created and tested THREE different Upstream configurations to use with Nginx.  This demonstrates how easy it is to have different platforms for your backend applications, and Nginx can easily be configured to change where it sends the Requests coming in.  You can use Azure VMs, Docker, Containers, or even AKS clusters for your apps.  You also added a customer HTTP Header, to help you track which upstream block is being used.



### << more exercises/steps>>

<numbered steps are here>

<br/>

## Nginx for Azure Split Clients for Blue/Green, A/B, Canary Testing

This concept of using `Live Traffic`, to test a new version or release of an application has several names, like Blue/Green, or A/B, or Canary testing.  We will use the term Blue/Green for this exercise, and show you how to control 0-100% of your incoming requests, and route/split them to different Upstreams with Nginx for Azure.  You will use the Nginx `http_split_clients` feature, to support these common application software Dev/Test/Pre-Prod/Prod patterns.  

You will start with the Nginx Cafe Demo, and your Docker VMs, as the current running Version of your application.  As your team is working towards all applications being developed and tested, and hosted in Kubernetes, you could use a process to make that migration easier!

Also using Cafe Demo, you decide that AKS Cluster1 is your Pre-Production test environment, where final QA checks of software releases are `signed-off` before being rolled out into Production.  
- As the software QA tests in your pipeline continue to pass, you will incrementally `increase the split ratio to AKS1`, and eventually migrate ALL 100% of your Live Traffic to the AKS1 Cluster - `with NO DOWNTIME, lost packets, connections, or user disruption.`  No WAY - it can't be that EASY?
- Just as importantly, if you do encounter any serious application bugs or even infrastructure problems, you can just as quickly `roll-back` to 100% to the Docker VMs.  *You will be an NGINXpert HERO.*

Your first CI/CD test case, is taking just 1% of your Live incoming traffic, and send it to AKS Cluster 1, where you likely have enabled debug level logging and monitoring of your containers, so you can see how the new Version is running.  (You do run these types of pre-release tests, right?)

To accomplist the Split Client functionality with Nginx, you only need 3 things.  
- The `split_clients directive`
- A Map block to configure the incoming request object of interest (a cookie name, cookie value, Header, or URL, etc)
- The destination Upstream Blocks, with percentages declared for the split ratios, with a new `$upstream` variable
-- As you want 99% for Docker, and 1% for AKS1, that is the configuration you will start with
-- The other ratios are provided, but commented out, you will use them as more of the QA tests pass

1. Inspect the `/lab5/split-clients.conf` file.  This is the Map Block you will use, configured to look at the `$request_id` Nginx variable.  As you should already know, the $request_id is a unique 64-bit number assigned to every incoming request by Nginx.  So you are telling Nginx to look at `every single request` when performing the Split hash algorithm.  You can use any Nginx Request $variable that you choose, and combinations of $variables is supported as well.  You can find more details on the http_split_clients module in the References section.

1.  Create a new Nginx config file for the Split Clients directive and Map Block, called `/etc/nginx/includes/split-clients.conf`.  You can use the example provided, just Copy/Paste:

```nginx
# Nginx 4 Azure to AKS1/2 NICs and/or UbuntuVMs for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
# HTTP Split Clients Configuration for AKS Cluster1/Cluster2 or UbuntuVM ratios
#
split_clients $request_id $upstream {

   # Uncomment the percent wanted for AKS Cluster #1, #2, or UbuntuVM
   #0.1% aks1_ingress;
   1.0% aks1_ingress;
   #5.0% aks1_ingress;
   #30% aks1_ingress; 
   #50% aks1_ingress;
   #80% aks1_ingress;
   #95% aks1_ingress;
   #99% aks1_ingress;
   #* aks1_ingress;
   #* aks2_ingress;
   #30% aks2_ingress;
   * cafe_nginx;          # Ubuntu VM containers
   #* aks1_nic_headless;   # Direct to NIC pods - headless/no nodeport

}

```

1. In your `/etc/nginx/conf.d/cafe.example.com.conf` file, modify the `proxy_pass` directive in your `location /` block, to use the `$upstream variable`.  This tells Nginx to use the Map Block where Split Clients is configured.

```nginx
...
    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";

        proxy_pass http://$upstream;          # Use Split Clients config

        add_header X-Proxy-Pass $upstream;    # Custom Header
         
        #proxy_pass http://cafe_nginx;        # Proxy AND load balance to Docker VM
        #add_header X-Proxy-Pass cafe_nginx;  # Custom Header

        #proxy_pass http://aks1_ingress;        # Proxy AND load balance to AKS1 Nginx Ingress
        #add_header X-Proxy-Pass aks1_ingress;  # Custom Header

        #proxy_pass http://aks2_ingress;        # Proxy AND load balance to AKS2 Nginx Ingress
        #add_header X-Proxy-Pass aks1_ingress;  # Custom Header

    }

...

```

Submit your Nginx Configuration.

1. Test with Chrome, hit Refresh several times, and Inspect the page, look at your custom Header.  It should say `cafe_nginx` or `aks1_ingress` depending on which Upstream was chosen by Split Client.

Unfortunately, Refreshing about 100 times, and trying to catch the 1% send to AKS1 will be difficult with a browser.  So you will use an HTTP Loadtest tool called `WRK`, which runs as a local Docker container, sending HTTP requests to your Nginx for Azure's Cafe Demo.

1. Open a separate Terminal, and start the WRK load tool.  Use the example here, but change the IP address to your Nginx for Azure Public IP:

```bash
docker run --name wrk --rm williamyeh/wrk -t4 -c200 -d15m -H 'Host: cafe.example.com' --timeout 2s http://20.3.16.67/coffee

```

This will open 200 Connections, and run for 15 minutes while we try different Split Ratios.  The Host Header `cafe.example.com` is required, to match your Server Block in your N4A configuration.

1. Scale your `nginx-ingress` deployment Replicas=1, so there is only one NIC running.  Then open your AKS1 NIC Dashboard (the one you bookmarded earlier), the HTTP Upstreams Tab, coffee upstreams.  These are the Pods running the latest version of your Application.  You should see about 1% of your Requests trickling into the AKS1 Ingress Controller, and it is load balancing those requests to a couple Pods.  If you can check your Azure Monitor, you would find the 99% going to the cafe_nginx upstreams, the three Docker containers running on Ubuntu.

*Great news* - the QA Lead has signed off on the 1% test and your code, and you are `good to go` for the next test.  Turn down your logging level, as now you will try `30% Live traffic to AKS1`, you are confident and bold, *make it or break it* is your motto.  

1. Again modify your `/etc/nginx/includes/split-clients.conf` file, this time setting `aks1_ingress` to 30%:

```nginx
# Nginx 4 Azure to AKS1/2 NICs and/or UbuntuVMs for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
# HTTP Split Clients Configuration for AKS Cluster1/Cluster2 or UbuntuVM ratios
#
split_clients $request_id $upstream {

   # Uncomment the percent wanted for AKS Cluster #1, #2, or UbuntuVM
   #0.1% aks1_ingress;
   #1.0% aks1_ingress;
   #5.0% aks1_ingress;
   30% aks1_ingress; 
   #50% aks1_ingress;
   #80% aks1_ingress;
   #95% aks1_ingress;
   #99% aks1_ingress;
   #* aks1_ingress;
   #30% aks2_ingress;
   * cafe_nginx;          # Ubuntu VM containers
   #* aks1_nic_direct;    # Direct to NIC pods - headless/no nodeport

}

```

Submit your Nginx Configuration, while watching the AKS1 NIC Dashboard.  In a few seconds, traffic stats should jump now to 30%!  Hang on to your debugger ...

After a couple hours of 30%, all the logs are clean, the dev and test tools are happy, there are NO support tickets, and all is looky peachy.

1. Next up is the 50% test.  You know what to do.  Modify your `split-clients.conf` file, setting AKS1 Ingress to 50% Live traffic.  Watch the NIC Dashboard, and your Monitoring tools closely.

```nginx
# Nginx 4 Azure to AKS1/2 NICs and/or UbuntuVMs for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
# HTTP Split Clients Configuration for AKS Cluster1/Cluster2 or UbuntuVM ratios
#
split_clients $request_id $upstream {

   # Uncomment the percent wanted for AKS Cluster #1, #2, or UbuntuVM
   #0.1% aks1_ingress;
   #1.0% aks1_ingress;
   #5.0% aks1_ingress;
   #30% aks1_ingress; 
   50% aks1_ingress;
   #80% aks1_ingress;
   #95% aks1_ingress;
   #99% aks1_ingress;
   #* aks1_ingress;
   #* aks2_ingress;
   #30% aks2_ingress;
   * cafe_nginx;          # Ubuntu VM containers
   #* aks1_nic_headless;   # Direct to NIC pods - headless/no nodeport

}

```

Submit your 50% configuration and cross your fingers.  HERO or ZERO, what will it be today?  If the WRK load test has stopped, start it again.

>Now that you get the concept and the configuration steps, you can see how EASY it is with Nginx Split Clients to route traffic to different backend applications, including different versions of apps - it's as easy as creating a new Upstream block, and determining the Split Ratio.  And consider this not so subtle point - you did not have to create ONE ticket, change a DNS record, change a firewall rules, update cloudXYZ device - nothing!  All you did was tell Nginx to split existing traffic, accelerating your app development velocity into Warp Drive.

>>The Director of Development has heard about your success with Nginx for Azure Split Clients, and now also wants a small percentage of Live Traffic for the next App version, running in AKS Cluster2.  Oh NO!!  - Success usually does mean more work.  But lucky for you, Split clients can work with many Upstreams.  So after several beers and intense discussions, your QA team decides on the following Split:

- AKS1 will get 80% traffic - for new version
- Docker VM will get 19% traffic - for legacy/current version
- AKS2 will get 1% traffic - for the Dev Director's request

1. Once again, modify the `split-clients.conf` file, with the percentages needed.  Open your Dashboards and Monitoring so you can watch in real time.  You tell the Director, here it comes:

```nginx
# Nginx 4 Azure to AKS1/2 NICs and/or UbuntuVMs for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
# HTTP Split Clients Configuration for AKS Cluster1/Cluster2 or UbuntuVM ratios
#
split_clients $request_id $upstream {

   # Uncomment the percent wanted for AKS Cluster #1, #2, or UbuntuVM
   #0.1% aks1_ingress;
   1.0% aks2_ingress;      # For the Dev Director
   #5.0% aks1_ingress;
   #30% aks1_ingress; 
   #50% aks1_ingress;
   80% aks1_ingress;
   #95% aks1_ingress;
   #99% aks1_ingress;
   #* aks1_ingress;
   #* aks2_ingress;
   #30% aks2_ingress;
   * cafe_nginx;           # Ubuntu VM containers
   #* aks1_nic_headless;   # Direct to NIC pods - headless/no nodeport

}

```

Submit your Nginx Configuration.

Voila!!  You are now splitting Live traffic to THREE separate backend platforms, simulating multiple versions of your application code.  To be far, in this lab exercise we used the same Cafe Demo image, but you get the idea.  Just as quick and easy, you can fire up another Upstream target, and add it to the Splits configuration.

**NOTE:** Several words of caution with Split Clients.  
- The ratios must add up to 100%, or Nginx will not apply the configuration.  
- .01% is the smallest split ratio available, that = 1/10,000th.  
- The * asterick means either 100%, or the remainder after other ratios.   
- If all the servers in an Upstream Block are DOWN, you will get that ratio of 502 errors, so always test your Upstreams prior to adding them to Split configurations.  There is no elegant way to "re-try" when using Splits.  Changing Splits under HIGH load is not recommended, there is always a chance something could go wrong and you will drop clients/traffic.  A maintenance window for changes is always a Best Practice.
- Split Clients is also available for TCP traffic, like your Redis Cluster.  It splits traffic based on new incoming TCP connections.  Every heard of Active/Active Redis Clusters?  Yes, you can do that and control the ratios, just like shown here for HTTP traffic.

>*HIT a nasty bug! - Director of Dev says the new code can't handle that 1% load, and several other backend systems have crashed!*  - not quite ready for testing like his devs told him...

>>No worries, you comment out the `aks2_ingress` in the Split Config, and his 1% Live traffic is now going somewhere safe, as soon as you Submit your Nginx Configuration!

But don't be surprised - in a few days he will ask again to send traffic to AKS2, and you can begin the Split migration process, this time from AKS1 to AKS2.  Now you've reached the Ultimate Kubernetes Application Solution, `Mutli Cluster Load Balancing, Active/Active, with Dynamic Split Ratios.`  No one else can do this for your team this easily, it's just Nginx!  

Cherry on top - not only can you do Split Client `outside` the Cluster with Nginx for Azure, Nginx Ingress Controller can also do Split Clients `inside` the cluster, ratios between different Services.  You can find that example in Lab10 in the Nginx Plus Ingress Workshop :-)

### Nginx HTTP Split Clients Solutions

Using the HTTP Split Clients module from Nginx can provide multiple traffic management Solutions.  Consider some of these that might be applicable to your environment:

- MultiCluster Active/Active Load Balancing
- Horizontal Cluster Scaling
- HTTP Split Clients - for A/B, Blue/Green, and Canary test and production traffic steering. Allows Cluster operations/maintainence like:
- - Node upgrades / additions
- - Software upgrades/security patches
- - Cluster resource expansions - memory, compute, storage, network, nodes
- - QA and Troubleshooting, using Live Traffic if needed
- - ^^ With NO downtime or reloads
- API Gateway testing/upgrades/migrations

## Wrap Up

As you have seen, using Nginx for Azure is quite easy, to create various backend Systems, Services, even platforms of different types; and have Nginx Load Balance them through a single entry point. Using Advanced Nginx directives/configs with Resolver, Nginx Ingress Controllers, Headless, and even Split Clients help you control and manage dev/test/pre-prod and even Production workloads with ease.  Dashboards and Monitoring give you insight with over 240 useful metrics, providing data needed for decisions based on both real time and historal metadata about your Apps and Traffic.

**This completes Lab5.**

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

Navigate to ([Lab6](../lab6/readme.md) | [LabX](../labX/readme.md))
