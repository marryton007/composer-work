#!/usr/bin/env bash

FABRIC_TOOL_DIR=~/fabric-tools/fabric-scripts/hlfv11/composer
ORG1_MSP_DIR=${FABRIC_TOOL_DIR}/crypto-config/peerOrganizations/org1.example.com/
ORG1_ADMIN_USER_DIR=${ORG1_MSP_DIR}/users/Admin@org1.example.com/msp

USER_NAME=PeerAdmin
NETWORK_NAME=$(cat connection.json|jq '.name'|tr -d '"')
CARD_NAME=${USER_NAME}@${NETWORK_NAME}
BNA_FILE=tutorial-network@0.0.1.bna

BNA_NETWORK=$(echo ${BNA_FILE} | sed 's/\(.*\)@.*/\1/g')
echo ${BNA_NETWORK}
BNA_VERSION=$(echo ${BNA_FILE} | sed 's/.*@\(.*\).bna/\1/g')
echo ${BNA_VERSION}

# create a business network card
function create_network_card() {
  CURRENT_DIR=$PWD
  PUBLIC_KEY=$(ls ${ORG1_ADMIN_USER_DIR}/signcerts/Admin@*.pem)
  # echo ${PUBLIC_KEY}
  PRIVATE_KEY=$(ls ${ORG1_ADMIN_USER_DIR}/keystore/*_sk)
  # echo ${PRIVATE_KEY}
  echo "create a business network card ..."
  composer card create -p connection.json -u ${USER_NAME} -c ${PUBLIC_KEY} -k ${PRIVATE_KEY} -r PeerAdmin -r ChannelAdmin
  composer card import -f ${CARD_NAME}.card
  composer card list
}

function install_business_network(){
  CURRENT_DIR=$PWD
  composer network install -c ${CARD_NAME} -a ${BNA_FILE}
}

function start_network(){
  composer network start --networkName ${BNA_NETWORK} --networkVersion ${BNA_VERSION} -A admin -S adminpw -c ${CARD_NAME}
}

#create_network_card
#install_business_network
start_network
