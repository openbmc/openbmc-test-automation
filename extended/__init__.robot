*** Settings ***
Documentation  Set metadata for test suite.

Library          SSHLibrary
Resource         ../lib/connection_client.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Resource         ../lib/code_update_utils.robot

Suite Setup      System Driver Data

*** Keyword ***

System Driver Data
    [Documentation]  System driver information.
    Open Connection And Log In
    Log BMC Driver Details
    ${software}=  Get Host Software Objects Details
    Log  ${software}
    ${bmc_model}=  Get BMC System Model
    Log  BMC Model=${bmc_model}

Log BMC Driver Details
    [Documentation]  Get BMC driver details and log.

    ${output}  ${stderr}=  Execute Command  grep ^VERSION_ID= /etc/os-release
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${output}

