*** Settings ***
Documentation     Update the PNOR image on the host for
...               hostboot CI purposes.

Library           OperatingSystem
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/state_manager.robot

Test Teardown     Collect SOL Log

*** Variables ***
# User inout OS parameter.
${OS_HOST}    ${EMPTY}

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
Validate IPL
    [Documentation]  Power the host on, and validate the IPL.

    Start SOL Console Logging

    Initiate Power On
    Wait Until Keyword Succeeds
    ...  10 min    30 sec   Is System State Host Booted

    # Skip validating OS if not given.
    Run Keyword If  '${OS_HOST}' != '${EMPTY}'
    ...  Wait For Host To Ping  ${OS_HOST}

Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it.

    Copy PNOR to BMC
    ${pnor_path}  ${pnor_basename}=   Split Path    ${PNOR_IMAGE_PATH}
    Flash PNOR   /tmp/${pnor_basename}
    Wait Until Keyword Succeeds
    ...  7 min    10 sec    Is PNOR Flash Done

Prepare BMC For Update
    [Documentation]  Prepare system for PNOR update.

    Initiate Power Off

    Trigger Warm Reset
    Check If BMC is Up  20 min  10 sec

    Wait For BMC Ready

    Clear BMC Record Log


Validate Parameters
    [Documentation]   Validate parameter and file existence.
    Should Not Be Empty
    ...   ${PNOR_IMAGE_PATH}  msg=PNOR image path not set

    OperatingSystem.File Should Exist  ${PNOR_IMAGE_PATH}
    ...   msg=${PNOR_IMAGE_PATH} File not found

