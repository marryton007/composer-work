## deploy hyperledger fabric by composer

It has some scripts for deploy [Hyperledger Fabric][Fabric] by [composer tools][Composer]

1. Introduce 
    1. single-org
    
        it deploy fabric with a single org, you could found [the link][Deploy_single_org] about this.     
        
    2. multi-org
    
        it deploy fabric with multi orgs, please see [the link][Deploy_multi_orgs]   
        
    3. multi-server
    
        it deploy fabric on k8s environment, please see [the github repository][Fabric_k8s]

2. Usage

    If you are in *single-org* or *multi-org*, first please follow the link to start fabric network and then run the *start-xx.sh* script. The *multi-server* it likes *multi-org*, but first you should run the fabric network on k8s envrioment, please reference  [the github repository][Fabric_k8s] 



[Fabric]:https://github.com/hyperledger/fabric
[Composer]:https://hyperledger.github.io/composer/latest/index.html
[Deploy_multi_orgs]:https://hyperledger.github.io/composer/latest/tutorials/deploy-to-fabric-multi-org
[Deploy_single_org]:https://hyperledger.github.io/composer/latest/tutorials/deploy-to-fabric-single-org
[Fabric_k8s]:https://github.com/marryton007/hyperledger-fabric-k8s


