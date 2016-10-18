*** Settings ***
Documentation   This testsuite updates the PNOR image on the host for
...             hostboot CI purposes.

Resource        ../lib/utils.robot
Resource        ../lib/connection_client.robot
Resource        ../lib/openbmc_ffdc.robot
Test Setup          Start SOL Console Logging 
Test Teardown       Log FFDC
Suite Teardown      Collect SOL Log

*** Variables ***

*** Test Cases ***

Host BIOS Update And Boot
    [Tags]    open-power
    [Documentation]   This test updates the PNOR image on the host (BIOS), and
    ...               validates that hosts boots normally.
    Reach System Steady State
    Update PNOR Image
    Validate IPL

*** Keywords ***

Reach System Steady State
    [Documentation]  Reboot the BMC, power off the Host and clear any previous
    ...              events
#TODO renable Warm Reset once open-bmc warm reset issue is fixed
#    Trigger Warm Reset
    Initiate Power Off
#TODO renable Warm Reset once open-bmc warm reset issue is fixed
#    Clear BMC Record Log

Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it.
    Copy PNOR to BMC
    ${pnor_path}    ${pnor_basename}=   Split Path    ${PNOR_IMAGE_PATH}
    Flash PNOR     /tmp/${pnor_basename}
    Wait Until Keyword Succeeds  7 min    10 sec    Is PNOR Flash Done

Validate IPL
    [Documentation]  Power the host on, and validate the IPL
    Initiate Power On
    Wait Until Keyword Succeeds  10 min    30 sec    Is System State Host Booted

Collect SOL Log
    [Documentation]    Log FFDC if test suite fails and collect SOL log
    ...                for debugging purposes.
     ${sol_out}=    Stop SOL Console Logging 
     Create File    ${EXECDIR}${/}logs${/}SOL.log    ${sol_out}

