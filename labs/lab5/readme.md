#  NGINX Load Balancing / Reverse Proxy 

## Introduction

In this lab, you will configure Nginx4Azure to Proxy and Load Balance different backend system, including Docker containers running on an Ubuntu VM, AKS Ingress Controllers, and Windows VM.  You will create and configure the needed Nginx config files, and then test access to these systems.  The Docker containers are running a simple website that represent simple static web applications that can run in Docker.  The AKS Clusters and Nginx Ingress Controllers provide access to various K8s workloads.

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Docker
:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Configure Nginx4Azure to Proxy and Load balance Docker containers
- Configure Nginx4Azure to Proxy and Load balance AKS workloads
- Configure Nginx4Azure to Proxy a Windows Server VM
- Test access to your N4A configurations with Curl and Chrome
- Inspect the HTTP content coming from these systems
- Enable some advanced Nginx features and test them


## Pre-Requisites

- You have have your Nginx4Azure instance up and running
- You must access to the N4A Configuration Panel in Azure Portal
- You must have both AKS Cluster with Nginx Ingress Controllers running
- You must have the sample application running in both clusters
- You must have curl and a modern Browser installed on your system
- See `Lab0` for instructions on setting up your system for this Workshop

<br/>

### Nginx 4 Azure Proxy to Docker

Verify you have SSH access to the Ubuntu VM that was deployed previously.  Open a Terminal, and using your `ubuntuvm.pem` SSH key file, connect to the public `ubuntuvm-ip`, and log in.  For example:

```bash
ssh -i ubuntuvm_key.pem azureuser@52.247.231.156
```

Where:
`ssh` - is the local command to start an SSH session, or use another applcation of your choosing.
`-i ~/ubuntuvm.key.pem` -  is your local ssh key file in your Home directory, it must be in a path where the SSH program can read it.  You should have saved this file when you created the VM earlier.  If you don't have it, you will find it in the Azure Portal, under your Resource Group, called `unbuntuvm_key`.
`azureuser` is the default user for Azure hosted Linux VMs
`@52.247.231.156` is the Public IP Addresses assinged to your Ubuntu VM.  You will find this in Azure Portal, under your Resource Group, `ubuntuvm-ip`.

**Note:** If you cannot connect, you likely have a networking issue.  Most often, you need to add your local public IP address to the Network Security Group for SSH access to the VM.  You will find the NSG in the Azure Portal, under your Resource Group, called `ubuntuvm-nsg`.  Use `whatsmyip.org` or other tool to display what your local public IP is using across the Internet.  Update the NSG rule, to allow your Public IP inbound SSH access to the Ubuntu VM.

After connecting with SSH, change to the `/home/azureuser/cafe` folder.  Inspect the `docker-compose.yml` file.  You see three ingress-demo containers defined to start up.

Container name | IP address:port
|------------|-------------|
docker-web1 | ubuntuvm:81
docker-web2 | ubuntuvm:82
docker-web3 | ubuntuvm:83

Check and verify the three containers are running:

```bash
azureuser@ubuntuvm: docker ps -a

```

You should see something similar to:

```bash
#Sample output
CONTAINER ID   IMAGE                   COMMAND                  CREATED       STATUS         PORTS                                                                        NAMES
5f9d003f298e   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 weeks ago   Up 2 minutes   0.0.0.0:81->80/tcp, :::81->80/tcp, 0.0.0.0:4431->443/tcp, :::4431->443/tcp   docker-web1
f724cfa47479   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 weeks ago   Up 2 minutes   0.0.0.0:82->80/tcp, :::82->80/tcp, 0.0.0.0:4432->443/tcp, :::4432->443/tcp   docker-web2
8b263fab24be   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 weeks ago   Up 2 minutes   0.0.0.0:83->80/tcp, :::83->80/tcp, 0.0.0.0:4433->443/tcp, :::4433->443/tcp   docker-web3

```

Notice that the three containers are exposed on the Ubuntu host on ports `81, 82, and 83` for HTTP traffic.

Leave the SSH Terminal open, you will use it again in a few minutes.

Open the Azure Portal, your Resource Group, then Nginx for Azure, Settings, NGINX Configuration panel.

Click on `+ New File`, to create a new Nginx config file.

Name the new file `/etc/nginx/conf.d/cafe-docker-upstreams.conf`.

**Important:** You must use the full Linux /folder/filename path for every Nginx config file, for it to be properly created and placed in the correct folder.  If you forget, you can delete it and must re-create it.  The Azure Portal Text Edit panels do not let you move, or drag-n-drop files or folders.  You can `rename` a file by clicking the Pencil icon, and `delete` a file by clicking the Trashcan icon at the top.

Copy and paste the contents from the matching file from Github, into the Configuration Edit window, shown here:

```nginx
# Nginx 4 Azure, Cafe Nginx Demo Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# cafe-nginx servers
#
upstream cafe_nginx {
  zone cafe_nginx 256k;
  
  # from docker compose
  server ubuntuvm:81;
  server ubuntuvm:82;
  server ubuntuvm:83;

  keepalive 32;

}

```

<< ss here >>

This creates an Nginx Upstream Block, which defines the backend server group that Nginx will load balance traffic to.

Click the ` + New File` again, and create a second Nginx config file, using the same Nginx for Azure Configuration editor tool.

Name the second file `/etc/nginx/conf.d/cafe.example.com.conf`.

Copy, then paste the contents of the matching file from Github, into the Configuration Edit window, shown here:

```nginx
# Nginx 4 Azure - Cafe Nginx HTTP
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
server {
    
    listen 80;      # Listening on port 80 on all IP addresses on this machine

    server_name cafe.example.com;   # Set hostname to match in request
    status_zone cafe.example.com;

    access_log  /var/log/nginx/cafe.example.com.log main;
    # access_log  /var/log/nginx/cafe.example.com.log main_ext;   Extended Logging
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";
         
        proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        add_header X-Proxy-Pass cafe-nginx;  # Custom Header

        # proxy_pass http://vm1:32779;          # Proxy to another server
        # proxy_pass http://nginx.org;       # Proxy to another website
        # proxy_pass http://aks1_ingress;       # Proxy to AKS1 Nginx Ingress Controller NodePort
        # proxy_pass http://aks2_ingress;       # Proxy to AKS2 Nginx Ingress Controller NodePort
        # proxy_pass http://aks1_nic_direct;       # Proxy to AKS Nginx Ingress Controller Direct
        # proxy_pass http://$upstream;          # Use Split Clients config

    }

}

```

Click the `Submit` Button above the Editor.  Nginx will validate your configuration, if successfull, will reload Nginx with your new configuration.  If you receive an error, you will need to fix it before you proceed.

### Update your local system's DNS /etc/host file

For easy access your new website, you will need to add the hostname `cafe.example.com` and the Nginx4Azure Public IP address, to your local system DNS hosts file for name resolution.  Your N4A Public IP address can be found in your Azure Portal, under `nginx1-ip`.  Use VI or other text editor to add the entry to `/etc/hosts`:

```bash
cat /etc/hosts

127.0.0.1 localhost
...
# Nginx for Azure testing
20.3.16.67 cafe.example.com
...

```

Save your /etc/hosts file, and quit VI.

### Update your Azure Network Security Group

You likely have one, or more, Azure Network Security Groups that need to updated to allow port 80 HTTP traffic inbound to your Resources.  Check and verify that your Source IP is allowed access to both your VNet, and your `nginx1` instance.

### Test your Nginx4Azure configuration

Using a new Terminal, send a curl command to `http://cafe.example.com`, what do you see ?

```bash
curl -I http://cafe.example.com
```

```bash
#Sample output
HTTP/1.1 200 OK
Server: N4A-1.25.1
Date: Thu, 04 Apr 2024 21:36:30 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Expires: Thu, 04 Apr 2024 21:36:29 GMT
Cache-Control: no-cache
X-Proxy-Pass: cafe-nginx

```

Try the coffee and tea URLs, at http://cafe.example.com/coffee and /tea.

You should see a 200 OK Response.  Did you see the `X-Proxy-Pass` header - set to the Upstream block name.  

Did you notice the `Server` header?  This is the Nginx Server Token. Optional - Change the Server token to your name, and Submit your configuration.  The server_tokens directive is found in the `nginx.conf` file.  Change it from `N4A-$nginx_version`, to `N4A-$nginx_version-myname`, and click Submit.

Try the curl again.  See the change ?  Set it back if you like, the Server token is usually hidden for Security reasons, but you can use it as a quick identity tool temporarily.  (Which server did I hit?)

```bash
#Sample output
HTTP/1.1 200 OK
Server: N4A-1.25.1-cakker                # appended a name
Date: Thu, 04 Apr 2024 21:41:04 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Expires: Thu, 04 Apr 2024 21:41:03 GMT
Cache-Control: no-cache
X-Proxy-Pass: cafe-nginx

```

### Test Nginx 4 Azure to Docker

Try access to your website with a Browser.  Open Chrome, and nagivate to `http://cafe.example.com`.  You should see an `Out of Stock` image, with a gray metadata panel, filled with names, IP addresses, URLs, etc.  This panel comes from the Docker container, using Nginx $variables to populate the gray panel fields.  If you open Chrome Developer Tools, and look at the Response Headers, you should be able to see the Server and X-Proxy-Pass Headers set respectively.

Click Refresh serveral times.  You will notice the `Server Name` and `Server Ip` fields changing, as N4A is round-robin load balancing the three Docker containers - docker-web1, 2, and 3 respectively.  If you open Chrome Developer Tools, and look at the Response Headers, you should be able to see the Server and X-Proxy-Pass Headers set respectively.

Congratulations!!  You have just completed launching a simple web application with Nginx for Azure, running on the Internet, with just a VM, Docker, and 2 config files for Nginx for Azure.  That wasn't so hard, was it?

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

**Warning:**  If you stop and start your AKS cluster, or add/remove Nodes in the Pools, this Upstream list `WILL` have to be updated to match.  It is a static configuration that must match the Worker Nodes:NodePort definition in your AKS cluster.  If you change the static nginx-ingress NodePort Service, you will have to match it here as well.

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

Note, there are 3 upstreams, matching the 3 workers in AKS2 cluster.

Submit your Changes.  If you have the Server names:port correct, Nginx4Azure will validate and return a Success message.

**Warning:**  If you stop and start your AKS cluster, or add/remove Nodes in the Pools, this Upstream list `WILL` have to be updated to match.  It is a static configuration that must match the Worker Nodes:NodePort definition in your AKS cluster. If you change the static nginx-ingress NodePort Service, you will have to match it here as well.

### Test Nginx 4 Azure to AKS1 Cluster Ingress Controller

Now that you have these new Nginx Upstream blocks created, you can test them.

Change the `# comments for proxy_pass` in the `location /` block in the `/etc/nginx/conf.d/cafe.example.com.conf` file, to disable the proxy_pass to docker, and enable the proxy_pass to `aks1_ingress`, as shown:

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
        # proxy_pass http://nginx.org;       # Proxy to another website
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
