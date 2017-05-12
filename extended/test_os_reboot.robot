*** Settings ***
Documentation   Module to test OS reboot functionality.

Resource    ../lib/boot_utils.robot

*** Test Cases ***

OS Reboot Test
    [Documentation]  Boot OS and trigger reboot and expect
    ...              OS to boot back.
    # 1. Boot OS
    # 2. Verify OS is booted
    # 3. Issue "reboot" from OS
    # 4. Verify if OS is booted back

    REST Power On
    # Set auto reboot here...
    Host Reboot
