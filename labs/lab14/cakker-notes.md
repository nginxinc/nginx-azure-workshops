## N4A Dynamic Upstreams with Azure Private DNS SRV records

<overview>

##Agenda

- AZ Login and Setup
- Create Azure Private DNS
- Create VMSS with 2 VMs
- Add SRV Records
- Create N4A Upstream with Resolver
- Update proxy_pass

1. Set environment variables
```bash
export NAME=$(whoami)
export MY_PUBLICIP=$(curl -s ipinfo.io/ip)
export MY_SUBSCRIPTIONID=$(az account show --query id -o tsv)
export MY_RESOURCEGROUP=${MY_NAME}-n4a-workshop
export MY_LOCATION=centralus

```

### Build VMSS

1. Set environment variables

```bash
export MY_USERNAME=azureuser
export MY_VMSS=vmsstest
export MY_VM_IMAGE=Ubuntu2204
export MY_VNET=n4a-vnet
export MY_SUBNET=vm-subnet

```

1. Create a VMSS set
```bash
az vmss create --name $MY_VMSS --resource-group $MY_RESOURCEGROUP --image $MY_VM_IMAGE --admin-username $MY_USERNAME --generate-ssh-keys --public-ip-per-vm --orchestration-mode Uniform --instance-count 2 --zones 1 2 3 --vnet-name $MY_VNET --subnet $MY_SUBNET --vm-sku Standard_DS2_v2 --upgrade-policy-mode Automatic -o JSON

```

1. Get the number if instances and IDs
```bash
az vmss list-instances -n $MY_VMSS -g $MY_RESOURCEGROUP |grep instanceId
```

1. Get the VMSS instance names
```bash
az vmss list-instances -n $MY_VMSS -g $MY_RESOURCEGROUP |grep name
```


### Set up Azure DNS

1. Create a Private DNS Zone
```bash
az network private-dns zone create -g $MY_RESOURCEGROUP -n example.com
```

1. Create Virtual Network Link of Private-DNS to Vnet with AutoReg enabled

```bash
az network private-dns link vnet create -g $MY_RESOURCEGROUP -n dns1 -z example.com -v $MY_VNET -e True
```


### Adding SRV records
1. Create and empty SRV record-set
```bash
az network private-dns record-set srv create -g $MY_RESOURCEGROUP -z example.com -n vmss01

```                                            

1. Add an SRV record
```bash
az network private-dns record-set srv add-record -g $MY_RESOURCEGROUP -z example.com -n vmss01 -t vmss01.example.com -r 443 -p 10 -w 10
```


1. Check Private DNS record-set
```bash
az network private-dns record-set list -g akker-n4a-workshop -z example.com
```

