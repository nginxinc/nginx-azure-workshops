#  Nginx Caching / Rate Limits / Juiceshop / My Garage

## Introduction

In this lab, you will deploy an image rich application, and use Nginx Caching to cache images to improve performance and provide a better user experience.  This will offload the image delivery workload from your applications, saving resources.  You will also explore, configure, and test Rate Limits with Nginx for Azure, allowing you to control incoming request levels for different applications.

< Lab specific Images here, in the /media sub-folder >

NGINX aaS | Cache | Juiceshop | My Garage
:-----------------:|:-----------------:|:-----------------:|:-----------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Nginx Cache](media/cache-icon.png) |![Juiceshop](media/juiceshop-icon.png) |![Mygarage](media/mygarage-icon.png) 
  
## Learning Objectives

- Deploy JuiceShop in AKS cluster.
- Expose JuiceShop with Nginx Ingress Controller.
- Configure Nginx for Azure for load balancing JuiceShop.
- Configure Nginx for Azure for load balancing Mygarage.
- Add Nginx Caching to improve delivery of images.


## Pre-Requisites

- You must have your Nginx for Azure instance running
- You must have your AKS Cluster running
- You must have your Docker VM running

- See `Lab0` for instructions on setting up your system for this Workshop
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Docker concepts and commands
- Familiarity with basic HTTP protocol
- Familiarity with HTTP Caching parameters, directives, headers

<br/>

## Deploy Juiceshop to AKS Cluster #1

In this exercise, you will deploy the demo Juiceshop application to AKS1.  Juiceshop is a demo application example of a Retail store, selling different juices, smoothies, and snacks.  The images used on the various web pages make ideal candidates for image caching. You will configure Nginx Ingress Controller for this application.    

1. Inspect the `lab9/juiceshop.yaml` and then `lab9/juiceshop-vs.yaml` manifests.  You will see definitions for three Juiceshop application pods being deployed, and a new VirtualServer being added to Nginx Ingress to expose the app outside the Cluster.

1. Using your Terminal, create a new namespace `juice` and deploy the Juiceshop application to AKS1.  Also deploy the Nginx Ingress VirtualServer, to create the Service and VirtualServer for `juiceshop.example.com`.  Use the Manifests provided in the `lab9` folder:

    ```bash
    kubectl config use-context n4a-aks1
    kubectl create namespace juice
    kubectl apply -f lab9/juiceshop.yaml
    kubectl apply -f lab9/juiceshop-vs.yaml

    ```

    ```bash
    #Sample output
    namespace/juice created
    deployment.apps/juiceshop created
    service/juiceshop-svc created
    secret/juice-secret created
    virtualserver.k8s.nginx.org "juiceshop-vs" deleted

    ```

1. Check your Nginx Ingress Dashboard for AKS1, you should now find `juiceshop.example.com` in the HTTP Zones, and a new `vs_juice_juiceshop-vs_juiceshop` Upstream block in the HTTP Upstreams tab, with 3 Pods running on port 3000. (You can safely ignore the 400 errors you see for this lab - those are from socket.io polling not properly configured).

## Add Caching to Nginx for Azure

In this exercise, you will creata an Nginx for Azure configuration, to add Caching for the images of the Juiceshop application. You will also configure Nginx for Azure to expose your Juiceshop application to the Internet. You will test it, and use various tools to verify that caching is working as expected. 

1. Inspect the `lab9/juiceshop.example.com.conf` configuration file.  Make note of the following items, which enable `Nginx Proxy Caching` for images:

- Line #7 - create the Cache - /path on disk, cache name=image_cache, :memory zone and size, max image size, disable temp files.
- Line #13 - set the hostname
- Line #14 - create a status zone for metrics
- Line #17,18 - set the logging filenames
- Line #30 - send requests to Nginx Ingress in AKS1
- Line #31 - set the Header for tracking
- Lines #37-62 - A new `location block`, with the following parameters
- - Line #39 - Use a Regular Expression (regex) to identify image types.
- - Line #42 - new status zone for image metrics
- - - Lines #44-46 - use the `image_cache` created earlier on Line #7 
- - - cache 200 responses for 60 seconds
- - - use a cache key, made up of three Nginx request $variables
- - Lines #49-51 - Set and Control Caching Headers
- - Line #55 - Set a Custom Header for Cache Status = HIT, MISS, EXPIRED
- - Line #57 - Send requests to Nginx Ingress in AKS1
- - Line #58 - Set another Custom Header for tracking

As you can see, there are quite a few Caching directives and parameters that must be set properly.  There are Advanced Nginx Caching classes available from Nginx University that cover architectures and many more details and use cases if you would like to learn more.  You will also find quite a few blogs and an E-book on Nginx Caching, it is a popular topic.  See the References Section.

But for this exercise, you will just enable it with the minimal configuration and test it out with Chrome.

1. Create the Nginx for Azure configuration needed for `juiceshop.example.com.`

Using the Nginx for Azure Console, create a new config file, `/etc/nginx/conf.d/juiceshop.example.com.conf`.  You can use the example file provided, just Copy/Paste.

```nginx
# Nginx 4 Azure - Juiceshop Nginx HTTP
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# Image Caching for Juiceshop
# Rate Limits testing
#
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=image_cache:10m max_size=100m use_temp_path=off;
#
server {
    
    listen 80;      # Listening on port 80 on all IP addresses on this machine

    server_name juiceshop.example.com;   # Set hostname to match in request
    status_zone juiceshop;

    # access_log  /var/log/nginx/juiceshop.log main;
    access_log  /var/log/nginx/juiceshop.example.com.log main_ext;   # Extended Logging
    error_log   /var/log/nginx/juiceshop.example.com_error.log info;

    location / {
        
        # return 200 "You have reached juiceshop server block, location /\n";

        # Set Rate Limit, uncomment below
        # limit_req zone=limit100;  #burst=110;       # Set  Limit and burst here
        # limit_req_status 429;           # Set HTTP Return Code, better than 503s
        # limit_req_dry_run on;           # Test the Rate limit, logged, but not enforced
        # add_header X-Ratelimit-Status $limit_req_status;   # Add a custom status header

        proxy_pass http://aks1_ingress;       # Proxy to AKS1 Nginx Ingress Controllers
        add_header X-Proxy-Pass aks1_ingress_juiceshop;  # Custom Header

    }

    # Cache Proxy example for static images / page components
    # Match common files with Regex
    location ~* \.(?:ico|jpg|png)$ {
        
        ### Uncomment for new status_zone in dashboard
        status_zone images;

        proxy_cache image_cache;
        proxy_cache_valid 200 60s;
        proxy_cache_key $scheme$proxy_host$request_uri;

        # Override cache control headers
        proxy_ignore_headers X-Accel-Expires Expires Cache-Control Set-Cookie;
        expires 365d;
        add_header Cache-Control "public";

        # Add a Cache status header - MISS, HIT, EXPIRED
        
        add_header X-Cache-Status $upstream_cache_status;
        
        proxy_pass http://aks1_ingress;    # Proxy AND load balance to AKS1 NIC
        add_header X-Proxy-Pass nginxazure_imagecache;  # Custom Header

    }  

} 

```

Submit your Nginx Configuration.

1. Update your local DNS `/etc/hosts` file, add `juiceshop.example.com` to your list of FQDNs for this Workshop, using the Public IP of your Nginx for Azure instance.  This now makes it FOUR hostnames active on 1 IP Address.

```bash
cat /etc/hosts
# Nginx for Azure Workshop
13.86.100.10 cafe.example.com dashboard.example.com redis.example.com juiceshop.example.com

```

### Test out Nginx for Azure Caching with Juiceshop

1. Open Chrome and go to `http://juiceshop.example.com`.  You should see them main Juiceshop page, explore around a bit if you like.

1. Right+Click, and choose `Inspect` on the Chrome menu to open Developer tools.  On the top Nav bar, click the Network Tab, and make sure the `Disable cache` is checked, you don't want Chrome caching our images for this exercise.

1. Click Refresh, and you will see a long list of items being sent from the application.

1. In the second Nav Bar, where you see `Name Status Type Size, etc`, Right+Click again, then `Response Headers`, then `Manage Header Columns`.  You will be adding your THREE custom Nginx headers to the display.  Click on `Add custom header...` , input these names one at a time:

- X-Cache-Status 
- X-Proxy-Pass 
- X-RateLimit-Status

This add these Headers to the display, making it easy to see the Header Values.

Now your second Nav Bar should have these three columns you can watch.

1. Click Refresh again, what do you see?  `The X-Cache-Status` header will display `HIT, MISS, EXPIRED`, depending on how Nginx is caching, or not caching, each object. A MISS means the object was not in the cache at all, of course. Clear the Dev tool display, and Click Refresh a couple more times - see if you can find some HITS?   If you wait more than 60 seconds, Refresh, and these same objects will show EXPIRED.  Click on one of the objects of interest, and check the Response Headers.

What does X-Proxy-Pass show?  Does it show 2 different Values?
- one for `aks1_ingress_juiceshop` for your first `location / block` 
- and `nginxazure_imagecache` for your `REGEX location block` for the image types?  

>Does Nginx for Azure actually proxy_pass to the aks1_ingress?  That is a trick question!!

- YES, for Cache MISS and EXPIRED, right?
- YES, for items not in the REGEX, right?
- NO, for Cache HITS, they are served from cache and do not need to be sent to the origin server.

**Optional Exercise:**  If you are comfortable with Regex, modify it to ADD `.js` and `.css` objects, Javascript and Cascading Style Sheet files, and re-test.  What were your observations? 

< Click for a hint: >

```nginx
location ~* \.(?:ico|jpg|png|js|css)$

```

*Knowledge Test*

Find the `carrot_juice` and `melon_bike` objects.  What are different about them?  Can you figure out what's going on?

>Provide your Answer via Private Zoom Chat if you figure it out and fix it!

## Add Caching for My Garage images

In this exercise, you will add Caching to Nginx for Azure for the My Garage images, just like you did for Juiceshop.

1.

<br/>

## Nginx for Azure Caching Wrap Up

Notice that is was pretty easy to define, and enable Nginx Caching for images and even other static page objects.  Also notice that you set the Valid time = 60 seconds.  This was intentional so you cand see object Expire quickly.  However, in Production, you will coordinate with your app team to determine the proper Age timer for different object types.  You can create multiple caches, with different names and Regex's, to have granular control over type, time, and size.  It's EASY with Nginx for Azure!

<br/>

**This completes Lab9.**

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX Caching](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_cache)
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

Navigate to ([Lab10](../lab10/readme.md) | [LabX](../labX/readme.md))
