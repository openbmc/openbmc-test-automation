*** Settings ***
Documentation   Module to test OS reboot functionality.

Resource    ../lib/boot_utils.robot
Resource    ../extended/obmc_boot_test_resource.robot

Suite Setup     Run Key  Start SOL Console Logging
Test Teardown   Test Teardown Execution

*** Variables ***

# User defined boot test iteration.
${BOOT_LOOP_COUNT}   ${1}

*** Test Cases ***

Host Reboot Loop
    [Documentation]  Boot OS and trigger reboot and expect
    ...              OS to boot back.
    # 1. Boot OS
    # 2. Verify OS is booted
    # 3. Issue "reboot" from OS
    # 4. Verify if OS is booted back

    # By default run test for 1 loop, else user input iteration.
    # Fails immediately if any of the execution rounds fail.

    # Note: Host Reboot is implemented by the OBMC Boot Test tool.
    # OBMC Boot Test will take the necessary steps to get the OBMC
    # to a host powered on state before attempting the Host Reboot.
    Repeat Keyword  ${BOOT_LOOP_COUNT} times  Host Reboot

*** Keywords ***

Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # 1. Capture FFDC on test failure.
    # 2. Stop SOL logging.
    # 3. Close all open SSH connections.

    FFDC On Test Case Fail

    ${keyword_buf}=  Catenate  Stop SOL Console Logging
    ...  \ targ_file_path=${EXECDIR}${/}logs${/}SOL.log
    Run Key  ${keyword_buf}

    Close All Connections
