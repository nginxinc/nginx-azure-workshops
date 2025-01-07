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

# Load geoip2 software into memory
load_module modules/ngx_http_geoip2_module.so;


http {
    # ...
}

```

## Create Nginx GeoIP Config

1. Using the N4A web console, create a new file, `/etc/nginx/GeoIP.conf`, copy and paste the contents from your previously downloaded file.  Note, the /path and name of the file must be exact.

1. Submit your changes, and Nginx for Azure will confirm that the configuration is valid.  If you see any errors, you must fix them before proceeding.

## Create Nginx GeoIP Test Configurations

In this exercise, you will create a simple Nginx configuration that you can use for testing the metadata from the MaxMind database.

1. Create a file that includes all the Nginx $variables that will contain GeoIP2 metadata.  You will create these in the `/etc/nginx/includes/geoip2_variables.conf` file.  As a shared resource in the /includes folder, this can then be used by any server block in your Nginx config files.  (Create it once, use it many times - an Nginx best practice).

Using the N4A web console, create a new file, `/etc/nginx/includes/geoip2_variables.conf`, copy and paste this example:

```nginx
# Nginx 4 Azure - geoip2_variables.conf
# Chris Akker, Shouvik Dutta, Adam Currier - Jan 2025
#
# Using "GeoLite2-Country" as one of the EditionIDs in /etc/nginx/GeoIP.conf
# Using "GeoLite2-City" as one of the EditionIDs in /etc/nginx/GeoIP.conf
#
# Set geoip2_ variables from City Database
geoip2 /usr/local/share/GeoIP/GeoLite2-City.mmdb {
    $geoip2_data_city_name   city names en;
    $geoip2_data_postal_code postal code;
    $geoip2_data_latitude    location latitude;
    $geoip2_data_longitude   location longitude;
    $geoip2_data_state_name  subdivisions 0 names en;
    $geoip2_data_state_code  subdivisions 0 iso_code;
}

# Set geoip2_ variables from Country Database
geoip2 /usr/local/share/GeoIP/GeoLite2-Country.mmdb {
    $geoip2_data_continent_code   continent code;
    $geoip2_data_country_iso_code country iso_code;
}

```

Take *NOTE* that you are creating these Nginx variables that reference different tables and values from both the GeoLite2 database files.

1. Using the N4A web console, create a new file for your new Host, http://geo.example.com, `/etc/nginx/conf.d/geo.example.com.conf`, copy and paste this example:

```nginx
# Nginx 4 Azure - geo.example.com.conf
# Chris Akker, Shouvik Dutta, Adam Currier - Jan 2025
#
server {
    listen 80;
    server_name geo.example.com;
    location / {

        return 200 "Welcome to N4A Workshop, GeoIP tracked your IP: $remote_addr from\nContinent: $geoip2_data_continent_code\nCountryISO: $geoip2_data_country_iso_code\nCity: $geoip2_data_city_name\nPostal: $geoip2_data_postal_code\nLat-Long: $geoip2_data_latitude $geoip2_data_longitude\nState: $geoip2_data_state_name\nStateISO: $geoip2_data_state_code\n";
    }
}

```

1. Update your local DNS hosts file, to use your Nginx for Azure public IP address for `geo.example.com`.

```bash
cat /etc/hosts

```

```
## Sample output ##
20.29.28.3 geo.example.com

```

1. Test with curl:

```bash
curl http://geo.example.com

```

```
## Sample output ##
Welcome to N4A Workshop, GeoIP tracked your IP:73.24.193.234 from
Continent: NA
CountryISO: US
City: Tucson
Postal: 85718
Lat-Long: 32.30980 -110.91500
State: Arizona
StateISO: AZ

```

>Nice!!  The geoip2 module is working, as it delivered metadata via Nginx variables to your Curl command.

1. Inspect the Nginx `return 200 Directive` in `geo.example.com.conf`, you will see that your IP address ($remote_addr), as well as 7 different GeoIP fields were sent back to you.

1. Using your browser, go to `http://geo.example.com`, and you should see something similar to this.  You will notice that we are using both the Country and City MaxMind data to populate the Nginx $variables used for this HTTP Response from Nginx.

< geoip tracker page >

## Use Case:  Choosing the Nearest Data Center, without GSLB/DNS

As you are likely an Nginx Admin with Global responisbilities, you have multiple Data Centers spread around the world.  When you have users also around the world, you are forced to use traditional `Global Server Load Balancing` and "SmartDNS" tools, to respond to DNS queries for your FQDNs.  However, there is likely an entirely different team responsible for DNS administration/managment, right?  Oh groan, more tickets and waiting.  *What if there was an easier way, to find a user's location, and route the users' requests correctly to the closest data center?*

You can easily do that with Nginx and the MaxMind GeoIP2 module, without any changes from your DNS admins.

< three data center diagram here >

In this example, you will control traffic to three Data Centers spread around the world, without using DNS.  One in North America, one in Europe, and one in Asia.  You will use the Nginx `$geoip2_data_continent_code variable` to redirect users to the Data Center in those three regions.  You will use the Nginx `map directive` to associate the MaxMind Continent Code to a 2-character identifier, as shown.   

```nginx
map $geoip2_data_continent_code $nearest_data_center {  
    EU      eu;
    NA      na;
    AS      as;
    default all;

}

```

1. Using the N4A web console, create a new config file called

## Test GeoIP2 lookups with a Header

Yes, that's right!  You can use Nginx with GeoIP2 to perform MaxMind Database lookups.  You will add the following to your Nginx configs:
- Create new GeoIP2 `test` variables
- Create a new `/testip` location block
- Update the current `return Directive` to use the new test_geoip2 variables.

1. Update your `/etc/nginx/includes/geoip2_variables.conf` to include 8 new `test_` variables, with the `SOURCE = X-Forward-For Header`, as shown.  Remember, Nginx converts all HTTP Headers to lower case, changes dashes to underscores, and adds the `http_` prefix.

```nginx
# Nginx 4 Azure - geoip2_variables.conf
# Chris Akker, Shouvik Dutta, Adam Currier - Jan 2025
#
# Using "GeoLite2-Country" as one of the EditionIDs in /etc/nginx/GeoIP.conf
# Using "GeoLite2-City" as one of the EditionIDs in /etc/nginx/GeoIP.conf
#
# Set geoip2_ variables from City Database
geoip2 /usr/local/share/GeoIP/GeoLite2-City.mmdb {
    $geoip2_data_city_name   city names en;
    $geoip2_data_postal_code postal code;
    $geoip2_data_latitude    location latitude;
    $geoip2_data_longitude   location longitude;
    $geoip2_data_state_name  subdivisions 0 names en;
    $geoip2_data_state_code  subdivisions 0 iso_code;

# Test IP Address from XFF Header
    $test_geoip2_data_city_name   source=$http_x_forwarded_for city names en;
    $test_geoip2_data_postal_code source=$http_x_forwarded_for postal code;
    $test_geoip2_data_latitude    source=$http_x_forwarded_for location latitude;
    $test_geoip2_data_longitude   source=$http_x_forwarded_for location longitude;
    $test_geoip2_data_state_name  source=$http_x_forwarded_for subdivisions 0 names en;
    $test_geoip2_data_state_code  source=$http_x_forwarded_for subdivisions 0 iso_code;
}

# Set geoip2_ variables from Country Database
geoip2 /usr/local/share/GeoIP/GeoLite2-Country.mmdb {
    $geoip2_data_continent_code   continent code;
    $geoip2_data_country_iso_code country iso_code;
    
# Test IP address using XFF Header value
    $test_geoip2_data_continent_code   source=$http_x_forwarded_for continent code;
    $test_geoip2_data_country_iso_code source=$http_x_forwarded_for country iso_code;
}

```

1. Edit your `/etc/nginx/conf.d/geo.example.com.conf` file to add a new location block for `/testip`, as shown.  Notice the geoip2 $variables are using the new one with a `source = x-forward-for`:

```nginx
...

        location /testip {

        return 200 "Welcome to N4A Workshop, GeoIP tested IP: $http_x_forwarded_for from\nContinent: $test_geoip2_data_continent_code\nCountryISO: $test_geoip2_data_country_iso_code\nCity: $test_geoip2_data_city_name\nPostal: $test_geoip2_data_postal_code\nLat-Long: $test_geoip2_data_latitude $test_geoip2_data_longitude\nState: $test_geoip2_data_state_name\nStateISO: $test_geoip2_data_state_code\n";

    }

...

```

Submit your Nginx Configuration.

1. Try an IP Address from Switzerland with curl, add the XFF Header with an IP Address to lookup:

```bash
curl http://geo.example.com/testip -H "X-Forwarded-For: 109.202.192.1"

```

```bash
## Sample output ##
Welcome to N4A Workshop, GeoIP tested IP: 109.202.192.1 from
Continent: EU
CountryISO: CH
City: Bern
Postal: 3012
Lat-Long: 46.96330 7.42270
State: Bern
StateISO: BE

```

1. Try one from Australia with curl, adding the XFF Header with an IP Address to lookup:

```bash
curl http://geo.example.com/testip -H "X-Forwarded-For: 49.255.14.118"

```

```bash
## Sample output ##
Welcome to N4A Workshop, GeoIP tested IP: 49.255.14.118 from
Continent: OC
CountryISO: AU
City: Sydney
Postal: 2000
Lat-Long: -33.87150 151.20060
State: New South Wales
StateISO: NSW

```

1. Try one from AWS in Japan with curl, adding the XFF Header with an IP Address to lookup:

```bash
curl http://geo.example.com/testip -H "X-Forwarded-For: 43.206.101.204"

```

```bash
## Sample output ##
Welcome to N4A Workshop, GeoIP tested IP: 43.206.101.204 from
Continent: AS
CountryISO: JP
City: Tokyo
Postal: 151-0053
Lat-Long: 35.68930 139.68990
State: Tokyo
StateISO: 13

```

As you can see, passing the IP Address to query in the XFF Header lets Nginx perform lookups easily without the MaxMind Database utility.

Kudos:  Credit to Echorand for the example: https://echorand.me/posts/nginx-geoip2-mmdblookup/

<br/>

## Explore additional GeoIP2 use cases

<br/>

## References:

- [NGINX As A Service for Azure](https://docs.nginx.com/nginxaas/azure/)
- [NGINX As A Service for Azure GeoIP2](https://docs.nginx.com/nginxaas/azure/quickstart/geoip2/)
- [NGINX GeoIP2 Module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/geoip2/)
- [NGINX GeoIP2 Admin Guide](https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-by-geoip/)
- [NGINX GeoIP2 Examples](https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-by-geoip/)
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