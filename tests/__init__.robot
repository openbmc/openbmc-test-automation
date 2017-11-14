*** Settings ***
Documentation  Set metadata for test suite.

Library          SSHLibrary
Resource         ../lib/connection_client.robot
Resource         ../lib/rest_client.robot
Resource         ../lib/utils.robot
Resource         ../lib/code_update_utils.robot

Suite Setup      System Driver Data

*** Variables ***

${DRIVER_CMD}    cat /etc/os-release | grep ^VERSION_ID=

*** Keyword ***

System Driver Data
    [Documentation]  System driver information and enable defaults settings.
    Run Keyword And Ignore Error  Clear System Entry From Knownhosts
    Open Connection And Log In
    Run Keyword And Ignore Error  Log BMC Driver Details
    Run Keyword And Ignore Error  Log PNOR Driver Details
    Run Keyword And Ignore Error  Log BMC Model
    Run Keyword And Ignore Error  Enable Core Dump On BMC
    Run Keyword And Ignore Error  Set Boot Defaults
    Enable Field Mode And Verify Unmount

Set Boot Defaults
    Set Control Boot Mode  ${CONTROL_HOST_URI}/boot  ${BOOT_MODE_REGULAR}
    Set Control Boot Mode
    ...  ${CONTROL_HOST_URI}/boot/one_time  ${BOOT_MODE_REGULAR}

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
    ${software}=  Get Host Software Objects Details
    Log  ${software}

Log BMC Model
    [Documentation]  Fetch BMC Model name from system and log.
    ${bmc_model}=  Get BMC System Model
    Log  BMC Model=${bmc_model}
