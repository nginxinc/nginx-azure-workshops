# N4A Feedback / Issues, feedback, suggestions

Nginx Default config `nginx.conf` should have two status_zone directives included.  One for server{} block, one for / location block.  **This will allow metrics to show up immediately, without the user having to find, understand, and configure status_zones in their nginx.conf file.**

```nginx

user nginx;
worker_processes auto;
worker_rlimit_nofile 8192;
pid /run/nginx/nginx.pid;

events {
    worker_connections 4000;
}

error_log /var/log/nginx/error.log error;

http {
    access_log off;
    server_tokens "";
    server {
        listen 80 default_server;
        status_zone default;         # Add something here
        server_name localhost;
        location / {
            status_zone /;           # Add something here
            # Points to a directory with a basic html index file with
            # a "Welcome to NGINX as a Service for Azure!" page
            root /var/www;
            index index.html;
        }
    }
}

```

There should be a step by step config guide for getting the Metrics to show up, and create a basic Dashboard for Nginx, including the Prerequisites.



## Nginx Standards and Best Practice Violations/Issues

The Nginx default HTML folder/files are missing.  This should be included, `/usr/share/nginx/html`, with all the Nginx Error Pages, and other Nginx primitives.  Consult a new installation of NginxPlus-R3x to match files.

The usage of the `/var/www` folder is an Apache/Microsoft standard, not an Nginx standard.  It should be replaced with `/usr/share/nginx/` for Nginx users.

The usage of the `/var/cache` folder for caching content is inconsistent with Nginx standards and docs.  Most Nginx documentation for caching refers to the `/data/nginx/cache` folder location, and should be changed for Nginx users.

## NGINX configuration issues

Upload Config Package overwrites the existing nginx.conf, this is terrible.  Config package upload should be modified to only allow uploads to the /etc/nginx/conf.d folder, the Nginx standard location for http config files.  Perhaps also allow uploads to `/etc/nginx/stream`, the Nginx standard for L4 config files.

## Caching

From the docs: NGINXaaS for Azure only supports caching to /var/cache/nginx. This is because data at /var/cache/nginx will be stored in a separate Temporary Disk. The size of the temporary disk is 4GB.

This is too small, and there should be an option to use other Azure storage options besides a Temporary disk.

Caching Configuration example is incomplete.  It only set up the cache_path location:

http {
    # ...
    proxy_cache_path /var/cache/nginx keys_zone=mycache:10m;
}

It is `missing` all the other parameters needed for caching to work.  A link to Nginx Content Caching is provided, but that is not very helpful.

A complete Caching config example should be provided, perhaps with an include file.

```nginx

http {
    ...

    proxy_cache_path /data/nginx/cache levels=1:2 keys_zone=mycache:10m max_size=500m use_temp_path=off;

    ...

    server {
        ...
        server_name localhost;
        location /images {
            ...
            proxy_cache mycache;                              # Use the cache
            proxy_cache_key "$host$request_uri$cookie_user";  # Cache Key
            proxy_cache_min_uses 2;                           # Cache after 2 reqs
            proxy_cache_valid 200 30m;                        # Cache for 30m
            proxy_cache_valid 404 1m;
            
            # Required caching headers
            proxy_ignore_headers X-Accel-Expires Expires Cache-Control Set-Cookie;
            add_header Cache-Control "public";
            add_header X-Cache-Status $upstream_cache_status;  # Add Cache status header


        }
    }
}

```

## Default 'includes' Directive is missing

Missing standard NGINX config for including files in /etc/nginx/conf.d folder.

## Can't see the Nginx Upstreams

Without the Plus realtime dash board, there is no way to know if the Upstreams defined are correct or working, because

## No access to Nginx Access or Error logs

There is no realtime access to either the Error or Access Logs from Nginx.  It makes it virtually impossible to "see what's going on" with Nginx without these logs.

Using the Azure Logging services does not work, you can't see the original Access or Error logs.  The lack of this feature will eliminate a large number of Nginx users.


## Nginx Keepalive for HTTP1.1 settings should be included.

```nginx
# Default is HTTP/1, keepalive is only enabled in HTTP/1.1
proxy_http_version 1.1;

# Remove the Connection header if the client sends it,
# it could be "close" to close a keepalive connection
proxy_set_header Connection "";

# Host request header field, or the server name matching a request
proxy_set_header Host $host;

```

## Nginx Azure Monitor - can't used Saved Dashboards.

If you create and save a dashboard, it does not work.

I can see the name in the list, but Azure Monitor does not let me "load it and use it".  It starts with a new, blank dashboard instead.  If you refresh the browser page, all customizations are lost and you start at the beginning.

nginx requests and responses, plus.http.status.4xx are reporting incorrectly.  looks like 2xx and 4xx metrics are swapped!

Unique Server, Location, and Upstream block metrics are not available, everything is aggregated in to a Total, no metrics with fine grain resolution.




***********

## Engineering Areas to investigate

Adam - AzureAD/DNS/Grafana
Chris - Plus LB, AZcompute, Cafe Demo, aks/nic/cafe
Shouvik - AZ monitor, KeyVault, new repo

