*** Settings ***
Documentation  Set metadata for test suite.

Library          SSHLibrary
Resource         ../lib/connection_client.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot

Suite Setup      System Driver Data

*** Variables ***

${DRIVER_CMD}    cat /etc/os-release | grep ^VERSION_ID=
${PNOR_CMD}      /usr/sbin/pflash -r /tmp/out.txt -P VERSION; cat /tmp/out.txt

*** Keyword ***

System Driver Data
    [Documentation]  System driver information.
    Open Connection And Log In
    Run Keyword And Ignore Error  Log BMC Driver Details
    Run Keyword And Ignore Error  Log PNOR Driver Details
    Run Keyword And Ignore Error  Log BMC Model
    Run Keyword And Ignore Error  Enable Core Dump On BMC

Log BMC Driver Details
    [Documentation]   Get BMC driver details and log.

    ${output}  ${stderr}=  Execute Command  ${DRIVER_CMD}
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    Log  ${output}
    [Return]  ${output}


Log PNOR Driver Details
    [Documentation]   Get PNOR driver details and log.
    # Until the new REST interface is available using pflash to
    # capture the PNOR details.
    ${pnor_details}=  Execute Command On BMC  ${PNOR_CMD}
    Log  PNOR_INFO=${pnor_details}


Log BMC Model
    [Documentation]  Fetch BMC Model name from system and log.
    ${bmc_model}=  Get BMC System Model
    Log  BMC Model=${bmc_model}

