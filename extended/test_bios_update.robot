*** Settings ***
Documentation     Update the PNOR image on the host for
...               hostboot CI purposes.

Library           OperatingSystem
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot

Test Setup        Start SOL Console Logging
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Collect SOL Log

*** Variables ***

*** Test Cases ***

Host BIOS Update And Boot
    [Tags]    open-power
    [Documentation]   Update PNOR image and verify that
    ...               host boots normally.

    Validate Parameters
    Prepare BMC For Update
    Update PNOR Image
    Validate IPL

*** Keywords ***

Prepare BMC For Update
    [Documentation]  Prepare system for PNOR update.

    Initiate Power Off

    Trigger Warm Reset
    Check If BMC is Up  20 min  10 sec

    Wait Until Keyword Succeeds
    ...  20 min  10 sec  Verify BMC State  BMC_READY

    Clear BMC Record Log


Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it.

    Copy PNOR to BMC
    ${pnor_path}  ${pnor_basename}=   Split Path    ${PNOR_IMAGE_PATH}
    Flash PNOR   /tmp/${pnor_basename}
    Wait Until Keyword Succeeds
    ...  7 min    10 sec    Is PNOR Flash Done


Validate IPL
    [Documentation]  Power the host on, and validate the IPL.

    Initiate Power On
    Wait Until Keyword Succeeds
    ...  10 min    30 sec   Is System State Host Booted


Collect SOL Log
    [Documentation]    Log FFDC if test suite fails and collect SOL log
    ...                for debugging purposes.
     ${sol_out}=    Stop SOL Console Logging
     Create File    ${EXECDIR}${/}logs${/}SOL.log    ${sol_out}


Validate Parameters
    [Documentation]   Validate parameter and file existence.
    Should Not Be Empty
    ...   ${PNOR_IMAGE_PATH}  msg=PNOR image path not set

    OperatingSystem.File Should Exist  ${PNOR_IMAGE_PATH}
    ...   msg=${PNOR_IMAGE_PATH} File not found

