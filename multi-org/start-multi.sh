#!/usr/bin/env bash
set -e

CRYPTO_CONFIG_DIR=fabric-samples/first-network/crypto-config
ORG1_DIR=${CRYPTO_CONFIG_DIR}/peerOrganizations/org1.example.com
ORG1_CA_DIR=${ORG1_DIR}/peers/peer0.org1.example.com
ORG1_USER_DIR=${ORG1_DIR}/users/Admin@org1.example.com/msp

ORG2_DIR=${CRYPTO_CONFIG_DIR}/peerOrganizations/org2.example.com
ORG2_CA_DIR=${ORG2_DIR}/peers/peer0.org2.example.com
ORG2_USER_DIR=${ORG2_DIR}/users/Admin@org2.example.com/msp

ORDERER_DIR=${CRYPTO_CONFIG_DIR}/ordererOrganizations/example.com
ORDERER_MSP_DIR=${ORDERER_DIR}/orderers/orderer.example.com

CA_FILE=tls/ca.crt
ORG1_CA_FILE=${ORG1_CA_DIR}/${CA_FILE}
ORG2_CA_FILE=${ORG2_CA_DIR}/${CA_FILE}
ORDERER_CA_FILE=${ORDERER_MSP_DIR}/${CA_FILE}

NETWORK_FILE=byfn-network.json

ORG1_NETWORK_DIR=org1
ORG1_NETWORK_FILE=${ORG1_NETWORK_DIR}/byfn-network-org1.json
ORG1_JSON=org1.json

ORG2_NETWORK_DIR=org2
ORG2_NETWORK_FILE=${ORG2_NETWORK_DIR}/byfn-network-org2.json
ORG2_JSON=org2.json

USER_NAME=PeerAdmin
ORG1_ADMIN=alice
ORG2_ADMIN=bob

ORG1_PARTICIPANT=jdoe
ORG2_PARTICIPANT=dlowe

BNA_FILE=trade-network@0.2.4-deploy.0.bna
BNA_NETWORK=$(echo ${BNA_FILE} | sed 's/\(.*\)@.*/\1/g')
#echo ${BNA_NETWORK}
BNA_VERSION=$(echo ${BNA_FILE} | sed 's/.*@\(.*\).bna/\1/g')
#echo ${BNA_VERSION}
#
ENDORSEMENT_POLICY_FILE=endorsement-policy.json

function make_network_file(){
    cp ${NETWORK_FILE}.template ${NETWORK_FILE}
    ORG1_KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}' ${ORG1_CA_FILE})
    ORG2_KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}' ${ORG2_CA_FILE}) 
    ORDERER_KEY=$(awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}' ${ORDERER_CA_FILE})
    
    
    #echo "key of org1:  ${ORG1_KEY}"
    #echo "key of org2:  ${ORG2_KEY}"
    #echo "key of orderer:  ${ORDERER_KEY}"

    jq -r --arg ORG1_KEY "${ORG1_KEY}" '.peers["peer0.org1.example.com","peer1.org1.example.com"].tlsCACerts.pem = $ORG1_KEY' ${NETWORK_FILE} |sponge ${NETWORK_FILE}
    jq -r --arg ORG2_KEY "${ORG2_KEY}" '.peers["peer0.org2.example.com","peer1.org2.example.com"].tlsCACerts.pem = $ORG2_KEY' ${NETWORK_FILE} |sponge ${NETWORK_FILE}
    jq -r --arg ORDERER_KEY "${ORDERER_KEY}" '.orderers["orderer.example.com"].tlsCACerts.pem = $ORDERER_KEY' ${NETWORK_FILE} |sponge ${NETWORK_FILE}

    cp ${NETWORK_FILE} ${ORG1_NETWORK_FILE}
    JSON=$(cat ${ORG1_JSON} | jq '.')
    jq -r --argjson client "${JSON}" '.client = $client' ${ORG1_NETWORK_FILE} |sponge ${ORG1_NETWORK_FILE}

    cp ${NETWORK_FILE} ${ORG2_NETWORK_FILE}
    JSON=$(cat ${ORG2_JSON} | jq '.')
    jq -r --argjson client "${JSON}" '.client = $client' ${ORG2_NETWORK_FILE} |sponge ${ORG2_NETWORK_FILE}
}


function make_network_card(){
    echo "generate and import network card for ORG$1..."
    CARD_NAME=${USER_NAME}@byfn-network-org$1
    echo "card name: ${CARD_NAME}"
    set +e
    composer card list | grep ${CARD_NAME}
    if [ $? -eq 0 ]; then
        composer card delete -c ${CARD_NAME}
    fi 
    set -e
    composer card create -p `eval echo '$'{"ORG$1_NETWORK_FILE"}` -u ${USER_NAME} -c `eval echo '$'{"ORG$1_USER_DIR"}`/signcerts/Admin@org$1.example.com-cert.pem -k `eval echo '$'{"ORG$1_USER_DIR"}`/keystore/*_sk -r PeerAdmin -r ChannelAdmin -f ${CARD_NAME}.card
    composer card import -f ${CARD_NAME}.card --card ${CARD_NAME}
}

function install_network() {
    echo "install network ${BNA_NETWORK}-${BNA_VERSION} from ORG$1 ..."
    composer network install --card ${USER_NAME}@byfn-network-org$1 --archiveFile ${BNA_FILE}
}


function identity_request() {
    echo "send identity request for ORG$1 ..."
    composer identity request -c ${USER_NAME}@byfn-network-org$1 -u admin -s adminpw -d $2
}


function start_network() {
    composer network start -c ${USER_NAME}@byfn-network-org1 -n ${BNA_NETWORK} -V ${BNA_VERSION} -o endorsementPolicyFile=${ENDORSEMENT_POLICY_FILE} -A ${ORG1_ADMIN} -C ${ORG1_ADMIN}/admin-pub.pem -A ${ORG2_ADMIN} -C ${ORG2_ADMIN}/admin-pub.pem 
}


function create_network_admin_participant() {
    USER=`eval echo '$'{"ORG$1_ADMIN"}`
    PARTICIPANT=`eval echo '$'{"ORG$1_PARTICIPANT"}`
    NET_FILE=`eval echo '$'{"ORG$1_NETWORK_FILE"}`
    CARD_ADMIN=${USER}@${BNA_NETWORK}
    CARD_PARTICIPANT=${PARTICIPANT}@${BNA_NETWORK}
    set +e
    composer card list | grep ${CARD_ADMIN}
    if [ $? -eq 0 ]; then
        composer card delete -c ${CARD_ADMIN}
    fi
    set -e
    echo "start create network card"
    composer card create -p ${NET_FILE} -u ${USER}  -n ${BNA_NETWORK} -c ${USER}/admin-pub.pem -k ${USER}/admin-priv.pem
    composer card import -f ${CARD_ADMIN}.card
    composer network ping -c ${CARD_ADMIN}
    composer participant add -c ${CARD_ADMIN} -d `echo '{"$class":"org.acme.trading.Trader", "firstName":"Jo"}' | jq -r --arg tradeId "trader1-org$1" --arg lastName "${PARTICIPANT}" '.tradeId = $tradeId | .lastName = $lastName |tostring' `
    set +e
    composer card list | grep ${CARD_PARTICIPANT}
    if [ $? -eq 0 ]; then
        composer card delete -c ${CARD_PARTICIPANT}
    fi
    composer identity issue -c ${CARD_ADMIN} -f ${PARTICIPANT}.card -u ${PARTICIPANT} -a "resource:org.acme.trading.Trader#trader1-org$1"
    set -e
    composer card import -f ${PARTICIPANT}.card
    composer network ping -c ${CARD_PARTICIPANT}
}

function submit_transaction() {
    PARTICIPANT=`eval echo '$'{"ORG$1_PARTICIPANT"}`
    CARD_PARTICIPANT=${PARTICIPANT}@${BNA_NETWORK}
    if [ $1 == "1" ]; then
        DATA=`echo '{"$class": "org.hyperledger.composer.system.AddAsset","registryType": "Asset","registryId": "org.acme.trading.Commodity", "targetRegistry" : "resource:org.hyperledger.composer.system.AssetRegistry#org.acme.trading.Commodity", "resources": [{"$class": "org.acme.trading.Commodity","tradingSymbol":"EMA", "description":"Corn commodity","mainExchange":"EURONEXT", "quantity":"10"}]}' | jq  --arg owner resource:org.acme.trading.Trader#trader1-org$1 '.resources[0].owner = $owner'`
        echo "transaction data : ${DATA}"
        composer transaction submit --card ${CARD_PARTICIPANT} -d "${DATA}"
    else
        composer transaction submit --card ${CARD_PARTICIPANT} -d `echo '{"$class":"org.acme.trading.Trade","commodity":"resource:org.acme.trading.Commodity#EMA"}' | jq -r --arg newOwner resource:org.acme.trading.Trader#trader2-org$1 '.newOwner = $newOwner | tostring'`
    fi
    composer network list -c ${CARD_PARTICIPANT}
}

if false; then
    # generate connection file
    make_network_file

    # generate network card
    make_network_card 1
    make_network_card 2

    # show all network card
    composer card list

    # install network 
    set +e
    install_network 1
    install_network 2
    set -e

    # identity request
    identity_request 1 ${ORG1_ADMIN}
    identity_request 2 ${ORG2_ADMIN}

# start network
start_network


# create network admin and paritipant
create_network_admin_participant 1
create_network_admin_participant 2
fi

submit_transaction 1
submit_transaction 2
