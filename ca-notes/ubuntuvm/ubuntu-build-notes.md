# Notes for building the Ubuntu VM for N4A workshop

  206  export MY_VM_NAME=ubuntuvm
  249  export MY_VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:server-22_04-lts-gen2:latest"
  252  export MY_VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
  253  az vm create     --resource-group $MY_RESOURCEGROUP     --location=$REGION  --tags owner=$MY_NAME     --name ubuntuvm     --image $MY_VM_IMAGE     --admin-username $MY_USERNAME     --vnet-name=$MY_VNET     --subnet $MY_SUBNET --assign-identity     --generate-ssh-keys     --public-ip-sku Standard


az vm create \
    --resource-group $MY_RESOURCEGROUP \
    --name n4a-ubuntuvm \
    --image $MY_VM_IMAGE \
    --admin-username azureuser \
    --vnet-name demo1-vnet \
    --subnet aks \
    --assign-identity \
    --generate-ssh-keys \
    --public-ip-sku Standard


Create a new VM, Ubuntu 22.02, 8GB ram, 128GB disk.

Use the same Vnet Subnet as your AKS cluster for the Networking.

Modify the NSG for SSH access, to allow your IP address to SSH to the VM.

Install docker-ce

   14  sudo apt update
   15  sudo apt install apt-transport-https ca-certificates curl software-properties-common
   16  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   17  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   18  sudo apt update
   19  apt-cache policy docker-ce
   20  sudo apt install docker-ce

Install docker-compose

   39  sudo apt install docker-compose
   40  mkdir -p ~/.docker/cli-plugins/
   41  curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
   42  chmod +x ~/.docker/cli-plugins/docker-compose
   43  docker compose version


Test docker works

sudo docker run hello-world

Install net-tools

   48  sudo apt-get update
   49  sudo apt-get install net-tools

Create folder /home/azureuser/cafe

azureuser@n4avm1: mkdir cafe

Create docker-compose.yml file

Start three Cafe demo containers

docker-compose up -d
