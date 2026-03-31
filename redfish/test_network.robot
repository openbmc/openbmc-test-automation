*** Settings ***
Documentation   This suite is to run some test at the end of execution.

Library      ../lib/network_utils.py

*** Test Cases ***

Test Network Subnet
    [Documentation]  Test network subnet.

    Log To Console  \n
    ${resp}=  are_in_same_network  balco10.aus.stglabs.ibm.com  lcb-one-rch-def06.onecloud.stglabs.ibm.com
    Log To Console  Response Same Network ?: ${resp}

    ${resp}=  are_in_same_network  balco10.aus.stglabs.ibm.com  balco10.aus.stglabs.ibm.com
    Log To Console  Response Same Network ?: ${resp}

