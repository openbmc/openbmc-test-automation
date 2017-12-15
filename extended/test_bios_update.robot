*** Settings ***
Documentation  Update the PNOR image on the host for hostboot CI purposes.

Library                 OperatingSystem
Library                 ../lib/gen_robot_keyword.py

Resource                ../extended/obmc_boot_test_resource.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/state_manager.robot

Test Teardown           Test Teardown Execution

Force Tags  BIOS_Code_Update

*** Variables ***

${QUIET}                ${1}
# OBMC Boot Test failures are not acceptable so we set the threshold to 0.
${boot_fail_threshold}  ${0}
# "skip" indicates to OBMC Boot Test that it should only process boot stack
# items that would change the machine state, i.e. only if the action is
# needed.
${stack_mode}           skip
${update_status}        True


*** Test Cases ***

Host BIOS Update
    [Documentation]  Update PNOR image and verify.
    [Tags]  Host_BIOS_Update  open-power

    Validate Parameters
    Prepare BMC For Update
    Update PNOR Image
    Verify PNOR Update

Host BIOS Power On
    [Documentation]  Power On the system and wait for OS
    [Tags]  Host_BIOS_Power_On  open-power

    Run Keyword If  '${PREV_TEST_STATUS}' == 'PASS'  Validate Power On

*** Keywords ***

Prepare BMC For Update
    [Documentation]  Prepare system for PNOR update.

    # Call 'OBMC Boot Test' to do a 'REST Power Off', if needed.
    Run Key U  OBMC Boot Test \ REST Power Off
    Run Key  Delete Error logs

Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it.

    Run Key  Copy PNOR to BMC
    ${pnor_path}  ${pnor_basename}=  Split Path  ${PNOR_IMAGE_PATH}
    Run Key  Flash PNOR \ /tmp/${pnor_basename}
    Run Key  Wait Until Keyword Succeeds \ 7 min \ 10 sec \ Is PNOR Flash Done

Validate Power On
    [Documentation]  Power the host on, and validate that the system booted.
    [Teardown]  Validate Power On Teardown

    # Have to start SOL logging here.  Starting SOL in test setup closes the
    # connection when bmc reboots.
    Run Key  Start SOL Console Logging
    Run Key U  OBMC Boot Test \ REST Power On

Validate Power On Teardown
    [Documentation]  Teardown after Validate Power On.

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

Test Teardown Execution
    [Documentation]  Log FFDC if test suite fails and collect SOL log for
    ...              debugging purposes.

    Printn
    Run Key  FFDC On Test Case Fail

Validate Parameters
    [Documentation]   Validate parameter and file existence.
    Should Not Be Empty
    ...   ${PNOR_IMAGE_PATH}  msg=PNOR image path not set

    OperatingSystem.File Should Exist  ${PNOR_IMAGE_PATH}
    ...   msg=${PNOR_IMAGE_PATH} File not found

