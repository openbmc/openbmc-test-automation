*** Settings ***
Resource    ../lib/resource.txt
Library     ../lib_redfish/redfish_client.py
...         ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

*** Test Cases ***

Test GET Request

    ${resp}=  Get Method  Systems
    Log To Console  \n ${resp}
    Logout Session
