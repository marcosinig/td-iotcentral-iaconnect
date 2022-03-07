#!/bin/bash

echo $(date) " - ### Starting Script ###"

AZURE_TENANT_ID=$1
AZURE_SUBSCRIPTION_ID=$2
ADMIN_USER=$3
AZURE_CLIENT_ID=$4
AZURE_CLIENT_SECRET=$5
USER_EMAIL=$6
USER_OBJECT_ID=$7
IOT_CENTRAL_NAME=$8
IOT_CENTRAL_LOCATION=$9
IOT_CENTRAL_SKU=${10}
IOT_CENTRAL_SUBDOMAIN=${11}
IOT_CENTRAL_TEMPLATE=${12}
RESOURCE_GROUP_NAME=${13}
DOCKER_HUB_USERNAME=${14}
DOCKER_HUB_PASSWORD=${15}
GIT_TOKEN=${16}
VM_DOMAIN_NAME=${17}

sudo apt-get -y update 
sudo apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg 

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

az extension add --name azure-iot

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

az iot central app create -n $IOT_CENTRAL_NAME -g $RESOURCE_GROUP_NAME -s $IOT_CENTRAL_SUBDOMAIN -l $IOT_CENTRAL_LOCATION -p $IOT_CENTRAL_SKU -t $IOT_CENTRAL_TEMPLATE

APP_ID=$(az iot central app list -g $RESOURCE_GROUP_NAME | grep application | awk '{print $2}'| sed 's/^"\(.*\)".*/\1/')

az iot central user create --user-id $USER_OBJECT_ID --app-id $APP_ID --email $USER_EMAIL --role admin

echo "Setting up nginix..."
git clone https://$GIT_TOKEN@github.com/marcosinig/td-iaconnect.git


echo "Setting up your mobiusflow cloud instance..."
echo ""

echo "Running setup-docker"

echo "Installing docker-compose"
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Installing Docker"
apt-get install -y docker.io zip > /dev/null
echo "Starting Docker"
systemctl start docker
systemctl enable docker

docker login --username $DOCKER_HUB_USERNAME --password $DOCKER_HUB_PASSWORD

cat > ~/docker-compose.yml <<EOF
version: '3.8'
volumes:
  mobius-data:
services:
  mobius:
    image: mobiusflow/mobiusflow-cloud-demo:latest
    container_name: mobiusflow-public
    privileged: false
    restart: always
    environment:
      - MOBIUS_HUB_RESET_PSKS=true
      - MOBIUS_ENABLE_CONFIG_UI=true
    #      - MOBIUS_HUB_ID=000001
    ports:
      - 8080:8080
      - 1883:1883
      - 30815:30815
      - 30817:30817
    volumes:
      - mobius-data:/data
EOF

rm -rf ~/mobius-cloud-install

echo "Starting mobiusflow"
cd ~ && docker-compose up &


