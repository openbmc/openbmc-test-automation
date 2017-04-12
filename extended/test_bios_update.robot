*** Settings ***
Documentation  Update the PNOR image on the host for hostboot CI purposes.

Library                 OperatingSystem
Library                 ../lib/gen_robot_keyword.py

Resource                ../extended/obmc_boot_test_resource.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/state_manager.robot

Test Teardown           Run Key  FFDC On Test Case Fail

*** Variables ***

${QUIET}                ${1}
# Boot failures are not acceptable so we set the threshold to 0.
${boot_fail_threshold}  ${0}
# "skip" indicates to OBMC Boot Test that it should only process boot stack
# items that would change the machine state, i.e. only if the action is
# needed.
${stack_mode}           skip

${FORCE_UPDATE}         ${0}

*** Test Cases ***

Host BIOS Update And Boot
    [Documentation]  Update PNOR image and verify.
    [Tags]  Host_BIOS_Update_And_Boot  open-power

    Validate Parameters
    Prepare BMC For Update
    Update PNOR Image

*** Keywords ***

Prepare BMC For Update
    [Documentation]  Prepare system for PNOR update.

    Run Key U  OBMC Boot Test \ REST Power Off

    Run Keyword If  '${FORCE_UPDATE}' == '${0}'  Run Keywords
    ...  Trigger Warm Reset  AND
    ...  Check If BMC is Up  20 min  10 sec  AND
    ...  Wait For BMC Ready

    Run Key  Clear BMC Record Log

Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it.

    Run Key  Copy PNOR to BMC
    ${pnor_path}  ${pnor_basename}=  Split Path  ${PNOR_IMAGE_PATH}
    Run Key  Flash PNOR \ /tmp/${pnor_basename}
    Run Key  Wait Until Keyword Succeeds \ 7 min \ 10 sec \ Is PNOR Flash Done

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

