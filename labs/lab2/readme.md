#  UbuntuVM/Docker / Windows VM / Cafe Demo Deployment 

## Introduction

In this lab, you will be creating various application backend resources.  You will create and deploy an Ubuntu VM for hosting Docker containers.  You will install Docker, and a demo application will be deployed with Docker-compose.  You will also deploy a Windows VM.  These containers and VMs will be your backend applications running in Azure.  You will configure and test Nginx for Azure to proxy and load balance these resources.

Your completed Ubuntu and Windows VM deployment will look like this:

< Lab specific Images here, in the /media sub-folder >

<br/>

NGINX aaS | Ubuntu | Docker | Windows
:---------------------:|:---------------------:|:---------------------:
![NGINX aaS](media/nginx-azure-icon.png) |![Ubuntu](media/ubuntu-icon.png) |![Docker](media/docker-icon.png) |![Docker](media/docker-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Deploy Ubuntu VM with Azure CLI
- Install Docker and Docker Compose
- Run Nginx demo application containers
- Deploy Windows VM with Azure CLI
- Test and validate your lab environment
- Configure Nginx for Azure to load balance these resources
- Test your Nginx for Azure configs

## Pre-Requisites

- You must have Azure Networking configured for this Workshop
- You must have access to Azure VMs
- You must have Azure CLI tool installed on your local system
- You must have an SSH client software installed on your local system
- You must have your Nginx for Azure instance deployed and running
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Docker concepts and commands
- Familiarity with basic HTTP protocol
- See `Lab0` for instructions on setting up your system for this Workshop

<br/>

## Deploy UbuntuVM with Azure CLI

After logging onto your Azure tenant, set the following Environment variables needed for this lab:

```bash
export MY_RESOURCEGROUP=myResourceGroup
export REGION=CentralUS
export MY_VM_NAME=ubuntuvm
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:server-22_04-lts-gen2:latest"

```

To see a list of UbuntuVMs available to you, try:

```bash
az vm image list --location $MY_LOCATION --publisher Canonical --output table

```

```bash
#Sample output
You are viewing an offline list of images, use --all to retrieve an up-to-date list
Architecture    Offer                         Publisher    Sku             Urn                                                           UrnAlias    Version
--------------  ----------------------------  -----------  --------------  ------------------------------------------------------------  ----------  ---------
x64             0001-com-ubuntu-server-jammy  Canonical    22_04-lts-gen2  Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest  Ubuntu2204  latest

```

Create the Ubuntu VM:

```bash
az vm create \
    --resource-group $MY_RESOURCEGROUP \
    --location $MY_LOCATION \
    --tags owner=$MY_NAME \
    --name $MY_VM_NAME \
    --image $MY_VM_IMAGE \
    --admin-username $MY_USERNAME \
    --vnet-name $MY_VNET \
    --subnet $MY_SUBNET \
    --assign-identity \
    --generate-ssh-keys \
    --public-ip-sku Standard

```

```bash
#Sample output
{
  "fqdns": "",
  "id": "/subscriptions/7a0bb4ab-c5a7-46b3-b4ad-c10376166020/resourceGroups/cakker/providers/Microsoft.Compute/virtualMachines/ubuntuvm",
  "identity": {
    "systemAssignedIdentity": "39f7bca4-830b-402a-b773-b381a65de685",
    "userAssignedIdentities": {}
  },
  "location": "westus2",
  "macAddress": "00-22-48-79-32-B6",
  "powerState": "VM running",
  "privateIpAddress": "172.16.24.4",
  "publicIpAddress": "52.137.81.233",
  "resourceGroup": "cakker",
  "zones": ""
}

```

Make a Note of the `publicIpAddress`, this is how you will access your VM remotely, with SSH.

**SECURITY Warning** This new VM has SSH/port22 open to the entire Internet, and is not using an SSH Key file or NSG for security.  Take appropriate steps to secure your VM if you will be using it for more than a couple hours!

**Note:** If you cannot connect, you likely have a networking issue.  Most often, you need to add your local public IP address to the Network Security Group for SSH access to the VM.  You will find the NSG in the Azure Portal, under your Resource Group, called `ubuntuvm-nsg`.  Use `whatsmyip.org` or other tool to display what your local public IP is using across the Internet.  Update the NSG rule, to allow your Public IP inbound SSH access to the Ubuntu VM.

Verify you have SSH access to the Ubuntu VM that was deployed previously.  Open a Terminal, and using your `ubuntuvm.pem` SSH key file, connect to the public `ubuntuvm-ip`, and log in.  For example:

```bash
ssh -i ubuntuvm_key.pem azureuser@52.247.231.156
```

Where:
`ssh` - is the local command to start an SSH session, or use another applcation of your choosing.
`-i ~/ubuntuvm.key.pem` -  is your local ssh key file in your Home directory, it must be in a path where the SSH program can read it.  You should have saved this file when you created the VM earlier.  If you don't have it, you will find it in the Azure Portal, under your Resource Group, called `unbuntuvm_key`.
`azureuser` is the default user for Azure hosted Linux VMs
`@52.247.231.156` is the Public IP Addresses assinged to your Ubuntu VM.  You will find this in Azure Portal, under your Resource Group, `ubuntuvm-ip`.

<< OPTIONAL >>
Using your local system's SSH program, connect to your `ubuntuvm`, and login with `azureuser`:

```bash
ssh azureuser@52.137.81.233

```
<< END OPTIOINAL >>

Install some Linux Networking Tools, needed for lab exercises:

```bash
sudo apt install net-tools

```

Install Docker Community Edition, run these commands:

```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce

```

Install Docker Compose, run these commands:

```bash
sudo apt install docker-compose
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

```

After installation, check the versions:

```bash
sudo docker version
sudo docker compose version

```

```bash
#Sample output
Client: Docker Engine - Community
 Version:           26.0.0
 API version:       1.45
 Go version:        go1.21.8
 Git commit:        2ae903e
 Built:             Wed Mar 20 15:17:48 2024
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          26.0.0
  API version:      1.45 (minimum version 1.24)
  Go version:       go1.21.8
  Git commit:       8b79278
  Built:            Wed Mar 20 15:17:48 2024
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.28
  GitCommit:        ae07eda36dd25f8a1b98dfbf587313b99c0190bb
 runc:
  Version:          1.1.12
  GitCommit:        v1.1.12-0-g51d5e94
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
azureuser@ubuntuvm:~$ sudo docker compose version
Docker Compose version v2.25.0

```

Test and see if Docker will run the `Hello-World` container:

```bash
sudo docker run hello-world

```

```bash
#Sample output
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c1ec31eb5944: Pull complete
Digest: sha256:53641cd209a4fecfc68e21a99871ce8c6920b2e7502df0a20671c6fccc73a7c6
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

```

Checkout a few Docker things:

```bash
sudo docker image list
sudo docker ps -a

```

You should find the hello-world image was pulled, and that the container ran and exited.

Success!  You have an Ubuntu VM with Docker that can run various containers needed for future Lab exercises.   Reminder: Don't forget to shutdown this VM when you are finished with it later, or set an Auto Shutdown policy using Azure Portal.

Leave your SSH Terminal running, you will use it in the next Exercise.

### Deploy Nginx Demo containers

You will now use Docker Compose to create and deploy three Nginx `ingress-demo` containers.  These will be your first group of `backends` that will be used for load balancing with Nginx for Azure.

On the Ubuntu VM, create a new folder in the `/home/azureuser` directory, call it `cafe`.

```bash
azureuser@ubuntuvm: cd $HOME
azureuser@ubuntuvm: sudo mkdir cafe
azureuser@ubuntuvm: cd cafe
azureuser@ubuntuvm: sudo vi docker-compose.yml

```

Inspect the `lab2/docker-compose.yml` file.  Notice you are pulling the `nginxinc/ingress-demo` image, and starting three containers.  The three containers are configured as follows:

Container Name | Name:port
:-------------:|:------------:
docker-web1 | ubuntuvm:81
docker-web2 | ubuntuvm:82
docker-web3 | ubuntuvm:83


Copy the contents from the `lab2/docker-compose.yml` file, into the same filename on the Ubuntu VM.  Save the file and exit VI.

Start up the three Nginx demo containers.  This tells Docker to read the compose file and start the three containers:

```bash
sudo docker-compose up -d

```

Check the containers are running:

```bash
sudo docker ps -a

```

It should look similar to this.  Notice that each container is listening on a unique TCP port on the Docker host - Ports 81, 82, and 83 for web1, web2 and web3, respectively.

```bash
#Sample output
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS                      PORTS                                                                        NAMES
33ca8329cece   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 minutes ago    Up 2 minutes                0.0.0.0:82->80/tcp, :::82->80/tcp, 0.0.0.0:4432->443/tcp, :::4432->443/tcp   docker-web2
d3bf38f7b575   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 minutes ago    Up 2 minutes                0.0.0.0:83->80/tcp, :::83->80/tcp, 0.0.0.0:4433->443/tcp, :::4433->443/tcp   docker-web3
1982b1a4356d   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 minutes ago    Up 2 minutes                0.0.0.0:81->80/tcp, :::81->80/tcp, 0.0.0.0:4431->443/tcp, :::4431->443/tcp   docker-web1

```

Verify that all THREE containers have their TCP ports exposed on the Ubuntu VM host:

```bash
azureuser@ubuntuvm:~/cafe$ netstat -tnl

```

```bash
#Sample output
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:81              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:83              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:82              0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:4433            0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:4432            0.0.0.0:*               LISTEN
tcp        0      0 0.0.0.0:4431            0.0.0.0:*               LISTEN
tcp6       0      0 :::22                   :::*                    LISTEN
tcp6       0      0 :::81                   :::*                    LISTEN
tcp6       0      0 :::83                   :::*                    LISTEN
tcp6       0      0 :::82                   :::*                    LISTEN
tcp6       0      0 :::4433                 :::*                    LISTEN
tcp6       0      0 :::4432                 :::*                    LISTEN
tcp6       0      0 :::4431                 :::*                    LISTEN

```

Yes, looks like ports 81, 82, and 83 are Listening.  Note:  If you used a different VM, you may need some host Firewall rules to allow traffic to the containers.

Test all three containers with curl:

```bash
azureuser@ubuntuvm:~/cafe$ curl -s localhost:81 |grep Server

```

Gives you the 1st Container Name as `Server Name`, and Container's IP address as `Server Address`:

```bash
#Sample output
      <p class="smaller"><span>Server Name:</span> <span>docker-web1</span></p>
      <p class="smaller"><span>Server Address:</span> <span><font color="green">172.18.0.2:80</font></span></p>

```

```bash
azureuser@ubuntuvm:~/cafe$ curl -s localhost:82 |grep Server

```

Gives you the 2nd Container Name as `Server Name`, and Container's IP address as `Server Address`:

```bash
#Sample output
      <p class="smaller"><span>Server Name:</span> <span>docker-web2</span></p>
      <p class="smaller"><span>Server Address:</span> <span><font color="green">172.18.0.3:80</font></span></p>

```

```bash
azureuser@ubuntuvm:~/cafe$ curl -s localhost:83 |grep Server

```

Gives you the 3rd Container Name as `Server Name`, and Container's IP address as `Server Address`:

```bash
#Sample output
      <p class="smaller"><span>Server Name:</span> <span>docker-web3</span></p>
      <p class="smaller"><span>Server Address:</span> <span><font color="green">172.18.0.4:80</font></span></p>

```

If you able to see Responses from all THREE containers, you can continue.

## Configure Nginx for Azure to Load Balance Docker containers

In this exercise, you will create your first Nginx config files, for the Nginx Server, Location, and Upstream blocks, to load balance your three Docker containers running on the Ubuntu VM.

< diagram here >

NGINX aaS | Docker | Cafe Demo
:-------------------------:|:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Docker](media/docker-icon.png)  |![Nginx Cafe](media/cafe-icon.png)

Open the Azure Portal, your Resource Group, then Nginx for Azure, Settings, and then the NGINX Configuration panel.

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
    status_zone cafe.example.com;   # Metrics zone name

    access_log  /var/log/nginx/cafe.example.com.log main;
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";
         
        proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        add_header X-Proxy-Pass cafe_nginx;  # Custom Header

    }

}

```

Click the `Submit` Button above the Editor.  Nginx will validate your configuration, and if successfull, will reload Nginx with your new configuration.  If you receive an error, you will need to fix it before you proceed.

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

<< out of stock ss here >>

Click Refresh serveral times.  You will notice the `Server Name` and `Server Ip` fields changing, as N4A is round-robin load balancing the three Docker containers - docker-web1, 2, and 3 respectively.  If you open Chrome Developer Tools, and look at the Response Headers, you should be able to see the Server and X-Proxy-Pass Headers set respectively.

Congratulations!!  You have just completed launching a simple web application with Nginx for Azure, running on the Internet, with just a VM, Docker, and 2 config files for Nginx for Azure.  That wasn't so hard now, was it?

<br/>

## Deploy Windows VM with Azure CLI

After logging onto your Azure tenant, set the following Environment variables needed for this lab:

```bash
export MY_RESOURCEGROUP=myResourceGroup
export REGION=CentralUS
export MY_VM_NAME=windowsvm
export MY_USERNAME=azureuser
export MY_VM_IMAGE="Windows Server 20xx"

```

Create the Windows VM:

```bash
az vm create \
    --resource-group $MY_RESOURCEGROUP \
    --location $MY_LOCATION \
    --tags owner=$MY_NAME \
    --name $MY_VM_NAME \
    --image $MY_VM_IMAGE \
    --admin-username $MY_USERNAME \
    --vnet-name $MY_VNET \
    --subnet $MY_SUBNET \
    --assign-identity \
    --generate-ssh-keys \
    --public-ip-sku Standard

```

```bash
#Sample output


```

## Configure Nginx for Azure to proxy the Windows VM

In this exercise, you will create your second Nginx config file, for the Nginx Server, Location, and Upstream blocks, to proxy your IIS Server running on the Windows VM.

< diagram here >

NGINX aaS | Windows | ? Which Demo Pages
:-------------------------:|:-------------------------:|:-------------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Windows](media/windows-icon.png)  |![Which Demo](media/unknown-icon.png)

Open the Azure Portal, your Resource Group, then Nginx for Azure, Settings, and then the NGINX Configuration panel.

Click on `+ New File`, to create a new Nginx config file.

Name the new file `/etc/nginx/conf.d/windows-upstreams.conf`.

**Important:** You must use the full Linux /folder/filename path for every Nginx config file, for it to be properly created and placed in the correct folder.  If you forget, you can delete it and must re-create it.  The Azure Portal Text Edit panels do not let you move, or drag-n-drop files or folders.  You can `rename` a file by clicking the Pencil icon, and `delete` a file by clicking the Trashcan icon at the top.

Copy and paste the contents from the matching file from Github, into the Configuration Edit window, shown here:

```nginx
# Nginx 4 Azure, Windows IIS Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# windows IIS server
#
upstream windowsvm {
  zone windowsvm 256k;
  
  server windowsvm:80;      # IIS Server

  keepalive 32;

}

```

<< ss here >>

This creates a new Nginx Upstream Block, which defines the Windows IIS backend server group that Nginx will load balance traffic to.

Edit the comment characters in `/etc/nginx/conf.d/cafe.example.com.conf`, to enable the `proxy_pass` to the `windowsvm`, and disable it for the `cafe-nginx`, as follows:

```nginx
# Nginx 4 Azure - Cafe Nginx and Windows IIS HTTP
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
server {
    
    listen 80;      # Listening on port 80 on all IP addresses on this machine

    server_name cafe.example.com;   # Set hostname to match in request
    status_zone cafe.example.com;   # Metrics zone name

    access_log  /var/log/nginx/cafe.example.com.log main;
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";
         
        # proxy_pass http://cafe_nginx;        # Proxy AND load balance to a list of servers
        # add_header X-Proxy-Pass cafe_nginx;  # Custom Header

        proxy_pass http://windowsvm;        # Proxy AND load balance to a list of servers
        add_header X-Proxy-Pass windowsvm;  # Custom Header

    }

}

```

Click the `Submit` Button above the Editor.  Nginx will validate your configuration, and if successfull, will reload Nginx with your new configuration.  If you receive an error, you will need to fix it before you proceed.

Test access again to http://cafe.example.com.  You will now see the IIS default server page, instead of the Out of Stock page.  If you check Chrome Dev Tools, the X-Proxy-Pass header should now show `windowsvm`.

Notice how easy it was, to create a new backend server, and then tell Nginx to proxy_pass to a different Upstream ?  You used the same Hostname, DNS record, and Nginx Server block, but you just told Nginx to switch backends.

Edit the `cafe.example.com.conf` file again, and change the comments to enable the `proxy_pass` for `cafe_nginx`, as you will use it again in a future lab exercise.

Submit your changes, and re-test to verify that http://cafe.example.com works again for Cafe Nginx.  Don't forget to change the custom header as well.

**This completes Lab2.**

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX Plus Product Page](https://docs.nginx.com/nginx/)
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
