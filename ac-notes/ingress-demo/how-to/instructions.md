# Modernizing the ingress-demo container

We need to update the ingress-demo container to get the latest version of NGINX+ and possibly add other features.

## Pull the official demo container we have been using:

    > docker pull nginxinc/ingress-demo
    > docker run nginxinc/ingress-demo

    > docker ps
    CONTAINER ID   IMAGE                   COMMAND                  CREATED      STATUS      PORTS                                                          
                  NAMES
    73de74c84484   nginxinc/ingress-demo   "/docker-entrypoint.…"   2 days ago   Up 2 days   0.0.0.0:81->80/tcp, :::81->80/tcp, 0.0.0.0:4431->443/tcp, :::4431->443/tcp   web1

## Pull a tool to make deconstructing the container a bit easier.
    > docker pull mrhavens/dedockify
    > docker images

    REPOSITORY              TAG       IMAGE ID       CREATED       SIZE
    nginxinc/ingress-demo   latest    407f33059787   3 years ago   23MB
    mrhavens/dedockify      latest    35e3fba3dd5a   4 years ago   57.6MB

## Create an alias to create your dockerfile using that tool.
    > alias dedockify="docker run -v /var/run/docker.sock:/var/run/docker.sock --rm mrhavens/dedockify"

## Save the Dockerfile into a directory by passing the ingress-demo Image ID to the dedockify command
    > mkdir how-to
    > dedockify 73ba987f213a > how-to/ingress-demo.dockerfile

There are a few changes you need to make to the dockerfile to make it it work.  The first is the FROM command:

    FROM nginxinc/ingress-demo:latest

This command put the source as ingress-demo:latest which is the container it pulled from, but to re-create the container we would use the original base image of alpine 3.12.3.  This will be updated with a supported / newer alpine release.

Continue reviewing the dockerfile, and you will see the **Add** and **Copy** lines. These are the directories/files that you need to copy out of the container to re-create it. Add commands are typically from URLs (or tarred files). The **Copy** files are typically from a local directory.

## These are the ADD/COPY lines from our extracted dockerfile:
    ADD file:ec475c2abb2d46435286b5ae5efacf5b50b1a9e3b6293b69db3c0172b5b9658b in /
    COPY file:e7e183879c35719c18aa7f733651029fbcc55f5d8c22a877ae199b389425789e in /
    COPY file:0b866ff3fc1ef5b03c4e6c8c513ae014f691fb05d530257dfffd07035c1b75da in /docker-entrypoint.d
    COPY file:0fd5fca330dcd6a7de297435e32af634f29f7132ed0550d342cad9fd20158258 in /docker-entrypoint.d
    COPY dir:2b12785b6c5bb3bd64cae65160474ac0551e5386c0a63b8d7641690929ead46b in /etc/nginx/certs
    COPY file:18eeef63b2c049fbd6dec94ce631ce791ca3ab3483b671fb2881b58407d4d6a9 in /etc/nginx/conf.d/default.conf
    COPY file:7220b420c5a891cbe1d5b2dd693475149c929dda54267422f558c9920ce170af in /etc/nginx/nginx.conf
    COPY dir:d63e44efdbba5d80aef30b0d7405800143e6a4e92c0bc9f962be4296e0df4418 in /usr/share/nginx

The **Add** (probably a URL) will be harder to figure out. It is being placed in the root directory though, so if we compare a base alpine 3.1.2 container to this one we should see the file that was added.
    
## Make a few dirs and copy in the contents from the container using *docker cp*
    > mkdir -p docker-entrypoint.d
    > mkdir -p etc/nginx/conf.d
    > mkdir -p usr/share

    > docker cp 407f33059787:/docker-entrypoint.sh .
    > docker cp 407f33059787:/docker-entrypoint.d/10-listen-on-ipv6-by-default.sh docker-entrypoint.d/
    > docker cp 407f33059787:/docker-entrypoint.d/20-envsubst-on-templates.sh docker-entrypoint.d/

    > docker cp 407f33059787:/etc/nginx/conf.d/default.conf etc/nginx/conf.d/
    > docker cp 407f33059787:/etc/nginx/nginx.conf etc/nginx/

## Copy the whole nginx folder in /usr/share which has the web pages, images and js, etc. and the certs
    > docker cp 407f33059787:/usr/share/nginx usr/share/
    > docker cp 407f33059787:/etc/nginx/certs etc/nginx

## Go into the ingress-demo container manually and make sure we didn't miss anything:
    > docker exec -it 73de74c84484 /bin/sh

If you identify any extra files, you can copy them out.

## Update the build parameters
Now that we have extracted the files, we can modernize the dockerfile and add new best practices/features. A good resource to start with is: https://gist.github.com/nginx-gists/36e97fc87efb5cf0039978c8e41a34b5#file-dockerfile-alpine