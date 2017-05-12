*** Settings ***
Documentation   Module to test OS reboot functionality.

Resource    ../lib/boot_utils.robot

Test Teardown   FFDC On Test Case Fail

*** Variables ***

# User defined boot test iteration.
${BOOT_LOOP_COUNT}   ${50}

*** Test Cases ***

Host Reboot Loop
    [Documentation]  Boot OS and trigger reboot and expect
    ...              OS to boot back.
    # 1. Boot OS
    # 2. Verify OS is booted
    # 3. Issue "reboot" from OS
    # 4. Verify if OS is booted back

    # By default run test for 50 loops, else user input iteration.
    # Fails immediately if any of the execution rounds fail and
    # check if BMC is still pinging and FFDC is collected.
    Repeat Keyword  ${BOOT_LOOP_COUNT} times  Boot OS And Reboot

*** Keywords ***

Host Reboot and Validate
    [Documentation]  Boot OS and trigger reboot.

    # Note: Host Reboot is implemented by the OBMC Boot Test tool.
    # OBMC Boot Test will take the necessary steps to get the OBMC
    # to a host powered on state before attempting the Host Reboot.
    Host Reboot

