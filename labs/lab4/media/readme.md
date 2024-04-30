#  Cafe Demo / Redis Deployment 

## Introduction

In this lab, you deploy the Nginx Cafe Demo, and Redis In Memory cache applications.  You will configure Nginx for Azure to expose these applications to the Internet. Then you will test and load test them, to make sure they perform as expected.  You will use the Nginx Plus Dashboard and Azure Monitoring to watch the metrics about your traffic.

NGINX aaS | Cafe | Redis
:-------------------:|:-------------------:|:-------------------:
![NGINX aaS](media/nginx-azure-icon.png)  |![Cafe](media/cafe-icon.png) |![Redis](media/redis-icon.png)
  
## Learning Objectives

By the end of the lab you will be able to:

- Deploying the Cafe Demo application
- Deploying the Redis In Memory cache
- Expose the Cafe Demo app with Nginx for Azure
- Expose the Redis Cache with Nginx for Azure


## Pre-Requisites

- You must have both AKS clusters up and running
- You must have both Nginx Ingress Controllers running
- You must have the NIC Dashboard available
- See `Lab0` for instructions on setting up your system for this Workshop
- Familiarity with basic Linux commands and commandline tools
- Familiarity with basic Kubernetes concepts and commands
- Familiarity with basic HTTP protocol

<br/>

## Deploy the Nginx CAFE Demo app

In this section, you will deploy the "Cafe Nginx" Ingress Demo, which represents a Coffee Shop website with Coffee and Tea applications. You will be adding the following components to your Kubernetes Cluster: Coffee and Tea pods, matching coffee and tea services, and a Cafe VirtualServer.

The Cafe application that you will deploy looks like the following diagram below. Coffee and Tea pods and services, with NGINX Ingress routing the traffic for /coffee and /tea routes, using the `cafe.example.com` Hostname.  There is also a hidden third service - more on that later!

< cafe diagram here >

1. Inspect the `lab4/cafe.yaml` manifest.  You will see we are deploying 3 replicas of each the coffee and tea Pods, and create a matching Service for each.  

1. Inspect the `lab4/cafe-vs.yaml` manifest.  This is the VirtualServer CRD used by Nginx Ingress to expose these apps, using the `cafe.example.com` Hostname.

1. Deploy the Cafe application by applying these two manifests:

```bash
kubectl apply -f lab4/cafe.yaml
kubectl apply -f lab4/cafe-vs.yaml

```

```bash
###Sample output###
deployment.apps/coffee created
service/coffee-svc created
deployment.apps/tea created
service/tea-svc created
virtualserver.k8s.nginx.org/cafe-vs created

```

1. Check that all pods and services are running, you should see three Coffee and three Tea pods:

```bash
kubectl get pods,svc
###Sample output###
NAME                      READY   STATUS    RESTARTS   AGE
coffee-56b7b9b46f-9ks7w   1/1     Running   0             28s
coffee-56b7b9b46f-mp9gs   1/1     Running   0             28s
coffee-56b7b9b46f-v7xxp   1/1     Running   0             28s
tea-568647dfc7-54r7k      1/1     Running   0             27s
tea-568647dfc7-9h75w      1/1     Running   0             27s
tea-568647dfc7-zqtzq      1/1     Running   0          27s

NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/kubernetes       ClusterIP   10.0.0.1      <none>        443/TCP    34d
service/coffee-svc       ClusterIP   None          <none>        80/TCP     34d
service/tea-svc          ClusterIP   None          <none>        80/TCP     34d

```

```bash
#Sample output
NAME      STATE   HOST                    IP    PORTS   AGE
cafe-vs   Valid   cafe.example.com                 3m
```

1. In your AKS1 cluster, you will run only 2 Replicas of the coffee and tea pods, so Scale down both deployments:

```bash
kubectl scale deployment coffee --replicas=2
kubectl scale deployment tea --replicas=2

```

Now there should be only 2 of each running:

```bash
kubectl get pods
###Sample output###
NAME                      READY   STATUS    RESTARTS   AGE
coffee-56b7b9b46f-9ks7w   1/1     Running   0             28s
coffee-56b7b9b46f-mp9gs   1/1     Running   0             28s
tea-568647dfc7-54r7k      1/1     Running   0             27s
tea-568647dfc7-9h75w      1/1     Running   0             27s

```

1. Check that the Cafe `VirtualServer`, **cafe-vs**, is running and the STATE is Valid:

```bash
kubectl get virtualserver cafe-vs

```
```bash
###Sample output###
NAME      STATE   HOST               IP    PORTS   AGE
cafe-vs   Valid   cafe.example.com                 4m6s

```

**Note:** The `STATE` should be `Valid`. If it is not, then there is an issue with your yaml manifest file (cafe-vs.yaml). You could also use `kubectl describe vs cafe-vs` to get more information about the VirtualServer you just created.

1. Check your Nginx Plus Ingress Controller Dashboard for Cluster1, http://dashboard.example.com:9000/dashboard.html.  You should now see `cafe.example.com` in the HTTP Zones tab, and 2 each of the coffee and tea Pods in the HTTP Uptreams tab.  Nginx is health checking the Pods, so they should show a Green status.

< cafe dashboard ss here >

### Deploy the Nginx CAFE Demo app in the 2nd cluster

1. Repeat the previous section to deploy the CAFE Demo app in your second AKS2 cluster, dont' forget to change your Kubectl Context first.

1.  Use the same /lab4 `cafe` and `cafe-vs` manifests.  However - do not Scale down the coffee and tea replicas, leave three of each pod running.

1. Check your Second Nginx Ingress Controller Dashboard, at http://dashboard.example.com:9002/dashboard.html.  You should find the same HTTP Zones, and 3 each of the coffee and tea pods for HTTP Upstreams.

## Configure Nginx for Azure for Cafe Demo

In this exercise, you will create the Nginx config files needed for access to the Cafe Demo application, running in both AKS clusters.  You will need an Upstream block for each cluster/nodeport, and you will use the existing `cafe.example.com.conf` file, just change the `proxy_pass` directive, to tell Nginx to send requests to the AKS cluster Ingress, instead of the Docker containers.

1. Using the Nginx for Azure Configuration Console, create a new file called `/etc/nginx/conf.d/aks1-upstreams.conf`.  You will again need your AKS Node Names for the server names in this config file.  Add `:32080` for your port number - this matches your previous NodePort-Static manifest.  

Use the example provided, just update the names as before:

```nginx
# Nginx 4 Azure to NIC, AKS Nodes for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# AKS1 nginx ingress upstreams
#
upstream aks1_ingress {
  zone aks1_ingress 256k;

  least_time last_byte;
  
  # to nginx-ingress NodePort Service / aks Node IPs
  server aks-userpool-76919110-vmss000001:32080;    #aks1 node1:
  server aks-userpool-76919110-vmss000002:32080;    #aks1 node2:

  keepalive 32;

}

```

Submit your Nginx Configuration.

> Important:  You are creating an Upstream to send all traffic to the Nginx Ingress Controller, not to the Cafe Pods!  That is why the Upstream is named `aks1-ingress` or `aks2-ingress`.  It will then be the Ingress Controllers responsibility to then route/load balance traffic to the correct Pods inside the cluster. 

>>There are TWO layers of Nginx load balancing here, one outside the Cluster using N4A, one inside the Cluster using Nginx Ingress. You must configure both for traffic to be routed and flow correctly.

1. Create another Nginx conf file for your second AKS2 cluster, named `/etc/nginx/conf.d/aks2-upstreams.conf`.  Change the server names to the AKS2 Node names, add port :32080. 

Use the example provided, just update the server names as before:

```nginx
# Nginx 4 Azure to NIC, AKS Node for Upstreams
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
# nginx ingress upstreams
#
upstream aks2_ingress {
  zone aks2_ingress 256k;

  least_time last_byte;
  
  # to nginx-ingress NodePort Service / aks Node IPs
  server aks-nodepool1-19485366-vmss000003:32080;    #aks2 node1:
  server aks-nodepool1-19485366-vmss000004:32080;    #aks2 node2:
  server aks-nodepool1-19485366-vmss000005:32080;    #aks2 node3: 

  keepalive 32;

}

```

### Test access to Cafe Demo in AKS1 Cluster / Nginx Ingress.

1. Modify the `proxy_pass` directive in your `cafe.example.com.conf` file, to use `aks1-ingress` for the backend.  As shown, just comment out the current `cafe_nginx` proxy pass and Header, and add a new ones for `aks1_ingress`.  That way, if you want to go back and test Docker again, it's a quick edit.

```nginx
# Nginx 4 Azure - Cafe Nginx to AKS1 NIC
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
server {
    
    listen 80;      # Listening on port 80

    server_name cafe.example.com;   # Set hostname to match in request
    status_zone cafe.example.com;   # Metrics zone name

    access_log  /var/log/nginx/cafe.example.com.log main;
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";

## Comment out cafe_nginx ##    
        
        #proxy_pass http://cafe_nginx;        # Proxy AND load balance to Docker VM
        #add_header X-Proxy-Pass cafe_nginx;  # Custom Header

        proxy_pass http://aks1_ingress;        # Proxy AND load balance to AKS2 Nginx Ingress
        add_header X-Proxy-Pass aks1_ingress;  # Custom Header

    }
    
}

```

Submit your Nginx Configuration.

1. Test it with Chrome or other browser, http://cafe.example.com/coffee.  Refresh several times, what do you see ?

- Nginx 4 Azure is sending requests to the Ingress, and the Ingress is loadbalancing the coffee pods in Cluster1.  
- Look at the Server Name and Server IP fields in the grey box.  What do they coorelate to?
-- Those are the Pod Names and Pod Ips.
- Check your Nginx Plus Ingress NIC Dashboard, what does it show while you Refresh the browser ?
-- The Request Metrics for the Pods should be increasing, and the HTTP Zone counter should also increase.
- Right click on Chrome, and Inspect.  Refresh again ... can you find the custom HTTP Header - what does it say ?

### Test access to Cafe Demo in AKS2 Cluster / Nginx Ingress.

This is the exact same test as the previous step, but for AKS2.

1. Using the Nginx for Azure Console, again modify the `proxy_pass directive` in your `cafe.example.com.conf` file.  Just change it to the `aks2_ingress` Upstream.

```nginx
# Nginx 4 Azure - Cafe Nginx to AKS2 NIC
# Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
#
server {
    
    listen 80;      # Listening on port 80

    server_name cafe.example.com;   # Set hostname to match in request
    status_zone cafe.example.com;   # Metrics zone name

    access_log  /var/log/nginx/cafe.example.com.log main;
    error_log   /var/log/nginx/cafe.example.com_error.log info;

    location / {
        #
        # return 200 "You have reached cafe.example.com, location /\n";      
         
        #proxy_pass http://cafe_nginx;        # Proxy AND load balance to Docker VM
        #add_header X-Proxy-Pass cafe_nginx;  # Custom Header

        #proxy_pass http://aks1_ingress;        # Proxy AND load balance to AKS1 Nginx Ingress
        #add_header X-Proxy-Pass aks1_ingress;  # Custom Header

        proxy_pass http://aks2_ingress;        # Proxy AND load balance to AKS2 Nginx Ingress
        add_header X-Proxy-Pass aks1_ingress;  # Custom Header

    }
    
}

```

Submit your Nginx Configuration.

1. Try it with Chrome or other browser, http://cafe.example.com/coffee.  Refresh several times, what do you see ?

- Nginx is sending requests to the Ingress, and the Ingress is loadbalancing the coffee pods in Cluster2.  
- Look at the Server Name and Server IP fields in the grey box.  Do they coorelate to the coffee Pods in Cluster2?
-- Check your Nginx Plus Ingress NIC Dashboard in Cluster2, what does it show while you Refresh the browser ?
-- The Request Metrics for the Pods should be increasing, and the HTTP Zone counter should also increase.
- Right click on Chrome, and Inspect.  Refresh again ... can you find the custom HTTP Header - what does it say ?

> See how easy that was, to create a couple new Upstream configurations, representing your 2 new clusters, and then just change the Proxy_Pass to use the new Resources?  This is just the tip of the iceberg of what you can do with Nginx for Azure.

## Deploy Redis In Memory Caching in AKS#2

In this exercise, you will deploy Redis in your Second AKS2 Cluster, and use both Nginx Ingress and Nginx for Azure to expose this Redis Cache to the Internet.  Similar to the Cafe Demo deployment, we start with AKS pods and services, add Nginx Ingress Transport Server for TCP, expose with NodePort, create Upstreams, and then finally add new Server block for `redis.example.com`.  As Redis operates at the TCP level, you will be using the `Nginx stream` context for your configurations, not the HTTP context.

1. Inspect the Redis Leader and Follower manifest.  `Thank You to our friends at Google` for this sample Redis Kubernetes configuration, it seems to work well.

1. Deploy Redis Leader and Follower to your AKS2 Cluster.

    ```bash
    kubectl config use-context n4a-aks2
    kubectl apply -f lab4/redis-leader.yaml
    kubectl apply -f lab4/redis-follower.yaml

    ```

1. Check they are running:

    ```bash
    kubectl get pods,svc

    ```

    ```bash
    #Sample Output / Coffee and Tea removed for clarity
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/redis-follower-847b67dd4f-f8ct5   1/1     Running   0          22h
    pod/redis-follower-847b67dd4f-rt5hg   1/1     Running   0          22h
    pod/redis-leader-58b566dc8b-8q55p     1/1     Running   0          22h

    NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
    service/redis-follower   ClusterIP   10.0.222.46   <none>        6379/TCP   24m
    service/redis-leader     ClusterIP   10.0.125.35   <none>        6379/TCP   24m

    ```

1. Configure Nginx Ingress Controller to enable traffic to Redis.  Use the following manifests to Open the Redis TCP Ports, and create a Transport Server for TCP traffic.

    Inspect the `lab4/global-configuration-redis.yaml` manifest.  This configures Nginx Ingress for new Stream Server blocks and listen on two more ports:

    ```yaml
    # NIC Global Config manifest for custom TCP ports for Redis
    # Chris Akker Jan 2024
    #
    apiVersion: k8s.nginx.org/v1alpha1
    kind: GlobalConfiguration 
    metadata:
    name: nginx-configuration
    namespace: nginx-ingress
    spec:
    listeners:
    - name: redis-leader-listener
        port: 6379
        protocol: TCP
    - name: redis-follower-listener
        port: 6380
        protocol: TCP

    ```    

1. Create the Global Configuration:

    ```bash
    kubectl apply -f lab4/global-configuration-redis.yaml

    ```

    ```bash
    #Sample output
    globalconfiguration.k8s.nginx.org/nginx-configuration created

    ```

1. Check and inspect the Global Configuration:

    ```bash
    kubectl describe gc nginx-configuration -n nginx-ingress

    ```
    ```bash
    #Sample output
    Name:         nginx-configuration
    Namespace:    nginx-ingress
    Labels:       <none>
    Annotations:  <none>
    API Version:  k8s.nginx.org/v1alpha1
    Kind:         GlobalConfiguration
    Metadata:
    Creation Timestamp:  2024-03-25T21:12:27Z
    Generation:          1
    Resource Version:    980829
    UID:                 7afbed08-364c-43bc-acc4-dcbeab3afee8
    Spec:
    Listeners:
        Name:      redis-leader-listener
        Port:      6379
        Protocol:  TCP
        Name:      redis-follower-listener
        Port:      6380
        Protocol:  TCP
    Events:        <none>

    ```

1. Create the Nginx Ingress Transport Servers, for Redis Leader and Follow traffic:

    ```bash
    kubectl apply -f lab4/redis-leader-ts.yaml
    kubectl apply -f lab4/redis-follower-ts.yaml

    ```

1. Verify the Nginx Ingress Controller is now running 2 Transport Servers for Redis traffic, the STATE should be Valid:

    ```bash
    kubectl get transportserver

    ```

    ```bash
    #Sample output
    NAME                STATE   REASON           AGE
    redis-follower-ts   Valid   AddedOrUpdated   24m
    redis-leader-ts     Valid   AddedOrUpdated   24m

    ```

1. Do a quick check your Nginx Ingress Dashboard for AKS2, you should now see TCP Zones and TCP Upstreams.  These are the Transport Servers and Pods that NIC will use for Redis traffic.

    << NIC Redis SS here >>

1. Inspect the `lab4/nodeport-static-redis.yaml` manifest.  This will update the NodePort definitions to include ports for Redis Leader and Follower.  Once again, these are static NodePorts.

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
    name: nginx-ingress
    namespace: nginx-ingress
    spec:
    type: NodePort
    ports:
    - port: 80
        nodePort: 32080
        protocol: TCP
        name: http
    - port: 443
        nodePort: 32443
        protocol: TCP
        name: https
    - port: 6379
        nodePort: 32379
        protocol: TCP
        name: redis-leader
    - port: 6380
        nodePort: 32380
        protocol: TCP
        name: redis-follower
    - port: 9000
        nodePort: 32090
        protocol: TCP
        name: dashboard    
    selector:
        app: nginx-ingress

    ```

1. Apply the new NodePort manifest:

    ```bash
    kubectl apply -f lab4/nodeport-static-redis.yaml

    ```

1. Verify there are now 5 Open Nginx Ingress NodePorts on your AKS2 cluster:

    ```bash
    kubectl get svc -n nginx-ingress

    ```

    ```bash
    #Sample output
    NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                                                                   AGE
    dashboard-svc   ClusterIP   10.0.226.36   <none>        9000/TCP                                                                  28d
    nginx-ingress   NodePort    10.0.84.8     <none>        80:32080/TCP,443:32443/TCP,6379:32379/TCP,6380:32380/TCP,9000:32090/TCP   28m

    ```

### Configure Nginx for Azure for Redis traffic

Following Nginx Best Practices, and standard Nginx disk folder/files layout, the `TCP Stream context` configuration files will be created in a new folder, called `/etc/nginx/stream/`.

1. Using the Nginx for Azure Console, modify the `nginx.conf` file, to enable the Stream Context, and to include the config files.  Place this stanza at the bottom of your nginx.conf file:

    ```nginx

    stream {
        
        include /etc/nginx/stream/*.conf;      # Stream Context nginx files

    }
    ```

    Submit your Nginx Config.

1. Using the Nginx for Azure Console, create a new Nginx conf file called `/etc/nginx/stream/redis-leader-upstreams.conf`.  Use your AKS2 Node names for server names, and add `:32379` for your port number, matching the NodePort for Redis Leader.  Use the example provided, just change the server names:

    ```nginx
    # Nginx 4 Azure to NIC, AKS Node for Upstreams
    # Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
    #
    # nginx ingress upstreams for Redis Leader
    #
    upstream aks2_redis_leader {
    zone aks2_redis_leader 256k;

    least_time last_byte;
    
    # from nginx-ingress NodePort Service / aks Node IPs
    server aks-nodepool1-19485366-vmss000003:32379;    #aks2 node1:
    server aks-nodepool1-19485366-vmss000004:32379;    #aks2 node2:
    server aks-nodepool1-19485366-vmss000005:32379;    #aks2 node3: 

    }

    ```

    Submit your Nginx Config.

1. Using the Nginx for Azure Console, create a new Nginx conf file called `/etc/nginx/stream/redis.example.com.conf`. Use the example provided:

    ```nginx
    # Nginx 4 Azure to NIC, AKS Node for Upstreams
    # Stream for Redis Leader
    # Chris Akker, Shouvik Dutta, Adam Currier - Mar 2024
    #
    server {
        
        listen 6379;
        status_zone redis-leader;

        proxy_pass aks2_redis_leader;

    }

    ```

    Submit your Nginx Config.

1. Update your Nginx for Azure NSG to allow port 6379 inbound, so you can connect to the Redis Leader:

<< TODO - add NSG update here >>

## Update local DNS

You will be using FQDN hostnames for the labs, and you will need to update your local computer's `/etc/hosts` file, to use these names with Nginx for Azure.

Edit your local hosts file, adding the FQDNs as shown below.  Use the `External-IP` Address of your Nginx for Azure instance:

    ```bash
    cat /etc/hosts

    # Added for N4A Workshop
    13.86.100.10 cafe.example.com dashboard.example.com redis.example.com
    
    ```
    >**Note:** All hostnames are mapped to the same N4A External-IP. Your N4A External-IP address will be different than the example.

### Test Access to the Redis Leader with Redis Tools

1. Using the `Redis-cli` tool, see if you can connect/ping to the Redis Leader:

    ```bash
    redis-cli -h redis.example.com PING

    ```
    ```bash
    #Response
    PONG
    ```
    ```bash
    redis-cli -h redis.example.com HELLO 2

    ```
    ```bash
    #Response
    1) "server"
    2) "redis"
    3) "version"
    4) "6.0.5"
    5) "proto"
    6) (integer) 2
    7) "id"
    8) (integer) 7590
    9) "mode"
    10) "standalone"
    11) "role"
    12) "master"
    13) "modules"
    14) (empty array)
    ```

Now how cool is that?  A Redis Cluster running in AKS, exposed with NIC and NodePort, and access provided by Nginx for Azure on the Internet, using a standard hostname and port to connect to.

**Optional:** Run Redis-benchmark on your new Leader, see what performance you can get.  Watch your Nginx Ingress Dashboard to see the traffic inside the cluster.  Watch your Nginx for Azure with Azure Monitoring as well.  

    ```bash
    redis-benchmark -h redis.nginxazure.build -c 100 -q

    ```
    ```bash
    #Sample output
    PING_INLINE: 1585.84 requests per second, p50=61.855 msec
    PING_MBULK: 1604.57 requests per second, p50=61.343 msec
    SET: 1596.37 requests per second, p50=61.759 msec
    GET: 1596.12 requests per second, p50=61.567 msec
    INCR: 1594.44 requests per second, p50=61.663 msec
    LPUSH: 1592.66 requests per second, p50=61.855 msec
    RPUSH: 1577.39 requests per second, p50=62.111 msec
    LPOP: 1603.69 requests per second, p50=61.503 msec
    RPOP: 1610.72 requests per second, p50=61.279 msec
    SADD: 1596.63 requests per second, p50=61.567 msec
    HSET: 1522.12 requests per second, p50=61.951 msec
    SPOP: 1414.31 requests per second, p50=61.791 msec
    ZADD: 1587.96 requests per second, p50=61.759 msec
    ZPOPMIN: 1578.38 requests per second, p50=61.887 msec
    LPUSH (needed to benchmark LRANGE): 1581.40 requests per second, p50=62.207 msec
    LRANGE_100 (first 100 elements): 1552.14 requests per second, p50=62.175 msec
    LRANGE_300 (first 300 elements): 1380.80 requests per second, p50=68.991 msec
    LRANGE_500 (first 500 elements): 1047.39 requests per second, p50=90.175 msec
    LRANGE_600 (first 600 elements): 1014.97 requests per second, p50=91.903 msec
    MSET (10 keys): 1559.36 requests per second, p50=62.783 msec
    XADD: 1581.40 requests per second, p50=61.983 msec

    ```

    Some screenshots for you:

    << Redis Benchmark SS here >>

You will likely find that the Redis performance is dimished by the Round trip latency of your Internet and Cloud network path. Redis performance/latency is directly related to network performance. However, the value of running a Redis cluster, in any Kubernetes cluster you like, and have access to it anywhere in the world could be a possible Solution for you.

>**Security Warning!**  There is no Redis Authentication, or other protections in this Redis configuration, just your Azure NSG IP/port filters.  Do NOT use this configuration for Production workloads.  The example provided in the Workshop is to show that running Redis is easy, and Nginx makes it easy to access.  Take appropriate measures to secure Redis data as needed.

<br/>

**This completes Lab4.**

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX Plus Product Page](https://docs.nginx.com/nginx/)
- [NGINX Ingress Controller](https://docs.nginx.com//nginx-ingress-controller/)
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

Navigate to ([Lab5](../lab5/readme.md) | [LabX](../labX/readme.md))
