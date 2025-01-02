# NginxAAS for Azure and GeoIP2

## Introduction

The Nginx for Azure Service now includes the MaxMind GeoIP2 Database modules for HTTP and TCP traffic processing.  The MaxMind GeoIP Location database is available as both a free service (called GeoLite) and a Subscription service (called GeoIP2).  The Paid Subscription service adds additional metadata and increased accuracy.  The Nginx for Azure modules can work with either service.  The GeoIP2 module uses the client Source IP address as the key when looking up database metadata, and the accuracy of this data varies by many factors.  The MaxMind paid Subscription service continually updates the database, and the Nginx for Azure service continually updates it's local copy of this database, providing access to the most current database available.

Knowing the client IP address can be used to create solutions and solve many different challenges for processing requests to Nginx.  This lab exercise will explore a couple use cases, and provide step by step instructions for installation, configuration and testing.

## Learning Objectives 

By the end of the lab you will be able to: 
- Enable the MaxMind GeoIP2 module for HTTP
- Create Nginx Configurations to test
- Explore additional use cases

## Prerequisites

- Nginx for Azure subscription
- MaxMind Database subscription

## Sign up for a free MaxMind Account

In order to use the MaxMind databases with the GeoIP2 module, you must have an active Account.  If you do not have an account, you must create one before proceeding with this lab.  You can create an account by going to the MaxMind website (https://www.maxmind.com/en/geolite2/signup).  This is a one page form asking just a few questions, and you will receive an email with your account details.  After logging into your account, will need the following information:

- AccountID
- LicenseKey
- EditionIDs

< Main MaxMind Login >

1. Click on `Account Information` to find your AccountID.

< Account Info >

1. Click on Manage License Keys, then Click on `Generate new license key` , give it a Description, and then `Confirm` to create one.

< New license key >

1. *Save your License Key safely* Click the `copy button` next to the License key, and paste it somewhere safe to save it.  *It is only displayed here, one time only.*  If you lose it, you can create a new one, but will then need to update your GeoIP.conf file.

1. Click the `Download Config`, and also save this file somewhere safe.  This is the `GeoIP.conf` file that will be used by Nginx to contact MaxMind and update the GeoIP database on your Nginx instance.

< download config >

```nginx
# GeoIP.conf file for `geoipupdate` program, for versions >= 3.1.1.
# Used to update GeoIP databases from https://www.maxmind.com.
# For more information about this config file, visit the docs at
# https://dev.maxmind.com/geoip/updating-databases.

# `AccountID` is from your MaxMind account.
AccountID xxxxxxx

# `LicenseKey` is from your MaxMind account.
LicenseKey xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# `EditionIDs` is from your MaxMind account.
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country

```

Notice the `EditionIDs`, these are the database metadatas available to you, the ASN ISP info, the City, and Country.

<br/>

## Enable the GeoIP2 module

In your Nginx for Azure instance, the main Nginx `nginx.conf` file must be updated to load the modules into memory so Nginx can use them.  These dynamic software modules are already installed on your Instance's disk for you. You will load both the http and stream modules, so you can explore both options, however, this lab exercise will only use HTTP. 

1. Using the N4A web console, edit the `nginx.conf` `main context` to add the load_module commands, as shown here.  Note: the main context is at the top of the file, *before* the `http {}` context:

```nginx
...

load_module modules/ngx_http_geoip2_module.so;
load_module modules/ngx_stream_geoip2_module.so;

http {
    # ...
}

```

## Create Nginx GeoIP Config

1. Using the N4A web console, create a new file, `/etc/nginx/GeoIP.conf`, copy and paste the contents from your previously downloaded file.  Note, the /path and name of the file must be exact.

1. Submit your changes, and Nginx for Azure will confirm that the configuration is valid.  If you see any errors, you must fix them befor proceeding.

## Create Nginx GeoIP Test Configurations

In this exercise, you will create a simple Nginx configuration that you can use for testing the variables from the MaxMind database.

1. Using the N4A web console, create a new file, `/etc/nginx/conf.d/geoiptest.conf`, copy and paste this example:

```nginx
# Nginx 4 Azure - geoiptest.conf
# Chris Akker, Shouvik Dutta, Adam Currier - Jan 2025
#
# Using "GeoLite2-Country" as one of the EditionIDs in /etc/nginx/GeoIP.conf
# Using "GeoLite2-City" as one of the EditionIDs in /etc/nginx/GeoIP.conf

geoip2 /usr/local/share/GeoIP/GeoLite2-City.mmdb {
    $geoip2_data_city_name   city names en;
    $geoip2_data_postal_code postal code;
    $geoip2_data_latitude    location latitude;
    $geoip2_data_longitude   location longitude;
    $geoip2_data_state_name  subdivisions 0 names en;
    $geoip2_data_state_code  subdivisions 0 iso_code;
}

geoip2 /usr/local/share/GeoIP/GeoLite2-Country.mmdb {
    $geoip2_data_continent_code   continent code;
    $geoip2_data_country_iso_code country iso_code;
}

server {
    listen 80;
    server_name geo.example.com;
    location / {
        default_type text/html;
        return 200 "Welcome to N4A Workshop, you are from\nContinent: $geoip2_data_continent_code\nCountryISO: $geoip2_data_country_iso_code\nCity: $geoip2_data_city_name\nPostal: $geoip2_data_postal_code\nLat-Long: $geoip2_data_latitude-$geoip2_data_longitude\nState: $geoip2_data_state_name\nStateISO: $geoip2_data_state_code\n";
    }
}


```

1. Update your local DNS hosts file, to use your Nginx for Azure public IP address for `geo.example.com`.

1. Using your browser, go to `http://geo.example.com`, and you should see something similar to this.  You will notice that we are using both the Country and City MaxMind data to populate the Nginx $variables used for this HTTP Response from Nginx.


## Explore additional GeoIP2 use cases

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX As A Service for Azure GeoIP2](https://docs.nginx.com/nginxaas/azure/quickstart/geoip2/)
- [NGINX GeoIP2 Module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/geoip2/)
- [NGINX GeoIP2 Admin Guide](https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-by-geoip/)
- [MaxMind GeoIP Databases](https://www.maxmind.com/en/geoip-databases)
- [NGINX Plus Product Page](https://docs.nginx.com/nginx/)
- [NGINX Directives Index](https://nginx.org/en/docs/dirindex.html)
- [NGINX Variables Index](https://nginx.org/en/docs/varindex.html)
- [NGINX Technical Specs](https://docs.nginx.com/nginx/technical-specs/)

<br/>

### Authors

- Chris Akker - Solutions Architect - Community and Alliances @ F5, Inc.
- Shouvik Dutta - Solutions Architect - Community and Alliances @ F5, Inc.
- Adam Currier - Solutions Architect - Community and Alliances @ F5, Inc.

-------------

Navigate to [LabGuide](../readme.md))