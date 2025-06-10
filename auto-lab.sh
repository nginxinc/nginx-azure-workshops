#!/usr/bin/env bash

##########################################################################
#                                                                        #
# Id: n4a-auto-lab.sh Release 0.9.0 2024/09/03  09:00:00 acurrier        #
# (C) Copyright F5, Inc. 2024                                            #
#                                                                        #
# n4a-auto-lab.sh - Pre-build environments for Azure labs on OS X        #
# Author:  Adam Currier <a.currier@f5.com>                               #
# Version: 0.9.0,  Date: 2024/09/03 09:00:00                             #
#                                                                        #
##########################################################################

#-------------------------------------------------------------------------
# Todo
#-------------------------------------------------------------------------
# Need to log things to track what is going on. Use tee or redirects.
# Could ask for owner and location values - add this via prompt.
#

#-------------------------------------------------------------------------
# Set Variables
#-------------------------------------------------------------------------
NAME="n4a-auto-lab.sh"
VERSION="1"
LOG_FILE="n4a-autolab.log" # not used yet, but will be soon
if [ -z "$MY_LOCATION" ]; then
  export MY_LOCATION=centralus
fi
# export MY_LOCATION=centralus # can be changed to your location

# On OS X, you can pull your username.  You can also set it yourself for use in the script:
# export OWNER=<your name>
export MY_NAME=$(whoami)

#-------------------------------------------------------------------------
# Sourced files
#-------------------------------------------------------------------------
source functions.sh

#-------------------------------------------------------------------------
# add some basic best practice settings to this script:
#-------------------------------------------------------------------------
set -o errexit
#set -o nounset
set -o pipefail

#-------------------------------------------------------------------------
# Let's add some debugging to the script.
#-------------------------------------------------------------------------
if [ "${_DEBUG:-}" == "true"  ]; then
  set -x
fi

#-------------------------------------------------------------------------
# Lab Functions:
#-------------------------------------------------------------------------

## Lab 1
function lab1(){
cleanup
create_resource_group
create_vnet
create_security_group
create_security_group_rules
create_subnets
create_public_ip
create_identity
create_n4a_deployment
create_analytics

echo 
echo "Lab1 infrastructure creation completed!"
echo 
}

## Lab 2
function lab2(){
cleanup
create_ubuntu_vm
secure_port_22
create_windows_vm
secure_port_3389

echo 
echo "Lab2 infrastructure creation completed!"
echo 
}

## Lab 3
function lab3(){
cleanup
create_aks_cluster1
clone_repo
create_nic_resources1
create_jwt1
deploy_nic1
create_aks_cluster2
create_nic_resources2
create_jwt2
deploy_nic2
kubectl_apply
create_nsg_rule_aks

echo 
echo "Lab3 infrastructure creation completed!"
echo 
}

## Lab 4
function lab4(){
cleanup
deploy_apps
get_node_ids
create_archive
upload_archive
update_hosts_file

echo 
echo "Lab4 infrastructure creation completed!"
echo 
}

function lab99(){
cleanup
create_resource_group
create_vnet
create_security_group
create_security_group_rules
create_subnets
create_public_ip
create_identity
create_n4a_deployment
create_analytics
create_ubuntu_vm
secure_port_22
create_windows_vm
secure_port_3389
create_aks_cluster1
clone_repo
create_nic_resources1
create_jwt1
deploy_nic1
create_aks_cluster2
create_nic_resources2
create_jwt2
deploy_nic2
kubectl_apply
create_nsg_rule_aks
deploy_apps
get_node_ids
create_archive
upload_archive
update_hosts_file

echo 
echo "All infrastructure creation completed!"
echo 
}

## LabTest
function labtest(){
azcli_test
nginx_ext_test
nginx_jwt_test

echo 
echo "Testing of lab conditions completed."
echo 
}

# How to use the script
DELETE=0
OPTSTRING=":adehtl:n:"

function usage {
cat <<EOT
Usage:
        $NAME [-l <number>] [-n MY_NAME][-a] [-d] [-h]
Purpose:
        In Azure, build the labs for the NGINXaaS workshop. 
        - Must have valid NGINX Plus JWT in Lab 3 folder.
        - Azure CLI must be installed and logged in.
        - Currently tested on OS X

Inputs:
      -l NUMBER
            This option allows you to choose which lab to build. Labs are built 
            on top of each other (there are dependencies), so prior labs will be 
            built.
      -a
            Build lab2, 3 or 4. All labs should be built sequentially.
      -d
            Delete the whole resource group (will ask for confirmation)
      -h
            Display this usage help text
      -t
            Test basic environment setup to be sure the script can run.

EOT
}

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    l)
      echo "Option -l was triggered, Argument: ${OPTARG}"
      LAB=${OPTARG}
      ;;
    a)
      echo "Option -a was triggered, running setup"
      LAB=4
      ;;
    d)
      echo "Option -d was triggered, running deletion"
      DELETE=1
      ;;
    e)
      echo "Option -e was triggered, building everything!"
      LAB=99
      ;;
    h)
      echo "Option -h was triggered, running usage"
      USAGE=1
      ;;
    t)
      echo "Option -t was triggered, running tests"
      TEST=1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

## Execute the functions for setup, etc.

function main() {
    if [[ $LAB == 1 ]]; then
        clear
        setup
        lab1
    elif [[ $LAB == 2 ]]; then
        clear
        setup
        lab2
    elif [[ $LAB == 3 ]]; then
        clear
        setup
        lab3
    elif [[ $LAB == 4 ]]; then
        clear
        setup
        lab4
        display
    elif [[ $LAB == 99 ]]; then
        clear
        setup
        lab99
        display
    elif [[ $DELETE == 1 ]]; then
        clear
        setup
        delete
    elif [[ $USAGE == 1 ]]; then
        clear
        usage
    elif [[ $TEST == 1 ]]; then
        clear
        labtest
    else 
        echo "Nothing to do!" 
    fi

}

main