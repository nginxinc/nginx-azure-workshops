#  NGINX Load Balancing / Reverse Proxy 

## Introduction

In this lab, you will configure Nginx4Azure to Proxy and Load Balance Docker containers running on an Ubuntu VM, created previously.  You will create and configure the needed Nginx config files, and then test access to these containers.  These Docker containers are running a simple website that represent the typical web applications that can run in Docker.

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Docker
:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Login and configure your Ubuntu VM.
- Configure Nginx4Azure to Proxy and Load balance Docker containers
- Test access to your N4A configuration with Curl and Chrome
- Inspect the HTTP content coming from the Docker Containers


## Pre-Requisites

- You must have the Ubuntu VM up and running
- you must have SSH access to the Ubuntu VM
- You have have your Nginx4Azure instance up and running
- You must access to the N4A Configuration Panel in Azure Portal
- You must have curl and a modern Browser installed on your system
- See `Lab0` for instructions on setting up your system for this Workshop

<br/>

### Lab exercise 1

Verify you have SSH access to the Ubuntu VM, and that was deployed previously.  Open a Terminal, and using your `.pem` SSH key file, connect to the ubuntuvm-ip, and log in.  For example:

```bash
ssh -i ubuntuvm_key.pem azureuser@52.247.231.156
```

Where:
`ssh` - is the local command to start an SSH session, or use another applcation of your choosing.
`-i ubuntuvm.key.pem` -  is your local ssh key file, it must be in a path where the ssh binary can read it.  You should have saved this file when you created the VM earlier.  If you don't have it, you will find it in the Azure Portal, under your Resource Group, called `unbuntuvm_key`.
`azureuser` is the default user for Azure hosted Linux VMs
`@52.247.231.156` is the Public IP Addresses assinged to your Ubuntu VM.  You will find this in Azure Portal, under your Resource Group, `ubuntuvm-ip`.

If you cannot connect, you likely have a networking issue.  Most often, you need to add your local SourceIP address to the Network Security Group for access to the VM.  You will find the NSG in the Azure Portal, under your Resource Group, called `ubuntuvm-nsg`.  Use `whatsmyip.org` to display what your local Public IP is using across the Internet.  Update the NSG rule, to allow your Public IP inbound SSH access to the Ubuntu VM.

After connecting with SSH, change to the `/cafe` folder.  Inspect the `docker-compose.yml` file.  You see three ingress-demo containers defined to start up.

Container name | IP address:port
docker-web1 | ubuntuvm:81
docker-web2 | ubuntuvm:82
docker-web3 | ubuntuvm:83

Leave the SSH Terminal open, you will use it again in a few minutes.

Open the Azure Portal, your Resource Group, then Nginx for Azure, Settings, NGINX Configuration panel.

Click on `+ New File`, to create a new Nginx config file.

Name the new file `/etc/nginx/conf.d/cafe-docker-upstreams.conf`.

Copy, then paste the contents of the matching file from Github, into the Configuration Edit window, shown here:

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

This creates the Nginx Upstream Block, which defines the backend server group that Nginx will load balance traffic to.

Click the ` + New File` again, and create a second Nginx config file, using the same Nginx for Azure configuration editor panel.

Name the second file `/etc/nginx/conf.d/cafe.example.com.conf`.

Copy, then paste the contents of the matching file from Github, into the Configuration Edit window, shown here:

```nginx
# Nginx 4 Azure - Cafe Nginx HTTP
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
server {
    
    listen 80;      # Listening on port 80 on all IP addresses on this machine

    server_name cafe.exmaple.com;   # Set hostname to match in request
    status_zone cafe.example.com;

    access_log  /var/log/nginx/cafe.example.com.log main;
    # access_log  /var/log/nginx/cafe.example.com.log main_ext;   Extended Logging
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        
        # return 200 "You have reached cafe.example.com, location /\n";
         
        proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        # proxy_pass http://n4avm1:32779;          # Proxy to another server
        # proxy_pass http://nginx.org;       # Proxy to another website
        # proxy_pass http://aks1_ingress;       # Proxy to AKS Nginx Ingress Controllers NodePort
        # proxy_pass http://aks1_nic_direct;       # Proxy to AKS Nginx Ingress Controllers Direct
        # proxy_pass http://$upstream;          # Use Split Clients config

    }

}

```

### Update your local DNS /etc/host file

For easy access your new website, you will need to add the hostname `cafe.example.com` and the Nginx4Azure Public IP address, to your local system DNS hosts file.  You N4A Public IP address can be found in your Azure Portal, under `nginx1-ip`.  Use VI or other text editor to add the entry for hostname resolution:

```
cat /etc/hosts

127.0.0.1 localhost
...
# Nginx for Azure testing
20.3.16.67 cafe.example.com

...

```

Save your /etc/hosts file, and quit VI.

### Update your Azure Network Security Group

You likely have one, or more, Network Security Groups that need to updated to allow port 80 HTTP traffic inbound to your Resources.  Check and verify that your Source IP is allowed access to both your VNet, and your `nginx1` instance.

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

```

You should see a 200 OK Response.  Did you notice the `Server` header?  This is the Nginx Server Token.  Change the Server token to your name, and Submit your configuration.  The server_tokens directive is found in the `nginx.conf` file.  Change it from `N4A-$nginx_version`, to `N4A-$nginx_version-myname`.

Try the curl again.  See the change ?  Set it back if you like, the Server token is usually hidden for Security reasons, but you can use it as an identity tool temporarily.  (Which server did I hit?)

```bash
#Sample output
HTTP/1.1 200 OK
Server: N4A-1.25.1-cakker                # appended a name
Date: Thu, 04 Apr 2024 21:41:04 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Expires: Thu, 04 Apr 2024 21:41:03 GMT
Cache-Control: no-cache

```

Try access your website with a Browser.  Open Chrome, and nagivate to `http://cafe.example.com`.  You should see `Out of Stock` image, with a gray metadata panel, filled with names, IP addresses, URLs, etc.  This panel is created by the Docker container, using Nginx Variables to populate the gray panel fields.

Click Refresh serveral times.  You will notice the `Server Name` and `Server Ip` fields changing, as N4A is round-robin load balancing the three Docker containers - docker-web1, 2, and 3 respectively.

Congrats!!  You have just completed launching a simple web application, running on the Internet, with just a VM, Docker, and 2 config files for Nginx for Azure.


### Lab exercise 3

<numbered steps are here>

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
