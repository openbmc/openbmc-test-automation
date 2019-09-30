*** Settings ***
Documentation   Test Non-maskable interrupt functionality.

Resource        ../../lib/bmc_redfish_resource.robot
Resource        ../../lib/boot_utils.robot
Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/secureboot/secureboot.robot
Resource        ../../lib/state_manager.robot
Library         ../../lib/bmc_ssh_utils.py

Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout

*** Test Cases ***

Trigger NMI When OPAL/Host OS Is Not Up
    [Documentation]  Verify error while injecting NMI when HOST OS is not up.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Not_Up

    Redfish Power Off  stack_mode=skip
    Trigger NMI

Trigger NMI When OPAL/Host OS Is Running And Secureboot Is Disable
    [Documentation]  Verify error while injecting NMI when HOST OS is not up.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Running_And_Secureboot_Is_Disable
    [Setup]  Test Setup Execution

    Trigger NMI
    Is Host Rebooted
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ls -1 /var/crash/ | wc -l
    Should Be Equal  ${output}  ${1}
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  find "/var/crash/" -type f -exec echo Found file {} \;

*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.

    Redfish Power Off  stack_mode=skip
    # Make sure that auto reboot should be in true mode.
    Set Auto Reboot  ${1}
    # Set the secure boot policy as disable.
    Set And Verify TPM Policy  ${0}
    Redfish Power On
    # Make sure that there is no previous existing any dump file.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  rm -rf /var/crash/*.*
    # Make sure that crash dump utility should be up and running in Os
    ${output}  ${stderr}  ${rc}=  OS Execute Command  kdumpctl start

Trigger NMI
    [Documentation]  Inject NMI Redfish URI

    Redfish.Login
    Redfish.Post  ${SYSTEM_BASE_URI}Actions/ComputerSystem.Reset
    ...  body={"ResetType": "Nmi"}  valid_status_codes=[${HTTP_INTERNAL_SERVER_ERROR}]

