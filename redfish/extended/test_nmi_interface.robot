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
    [Documentation]  Verify return error code from Redfish
    ...  while injecting NMI when HOST OS is not up.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Not_Up

    Redfish Power Off
    Trigger NMI


Trigger NMI When OPAL/Host OS Is Running And Secureboot Is Disable
    [Documentation]  Verify valid return status code from Redfish
    ...  while injecting NMI, when HOST OS is running and
    ...  secureboot is disabled.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Running_And_Secureboot_Is_Disable
    [Setup]  Test Setup Execution  ${0}

    Trigger NMI  status_codes=${HTTP_OK}
    # NMI Post Crash Dump Verification
    Wait Until Keyword Succeeds  10 min  1 min  Is Host Rebooted
    Is OS Booted
    Wait Until Keyword Succeeds  30 sec  5 sec
    ...  Crash Dump Directory Verification


*** Keywords ***

Test Setup Execution
    [Documentation]  Test setup execution.
    [Arguments]  ${secure_boot_mode}=${1}

    # Description of argument(s):
    # secure_boot_mode  Secure boot -> Enable-1 or Disable-0.

    Redfish Power Off  stack_mode=skip
    Set Auto Reboot  ${1}
    # Set and verify secure boot policy as disabled.
    Set And Verify TPM Policy  ${secure_boot_mode}
    Redfish Power On
    # Delete any pre-existing dump files.
    OS Execute Command  rm -rf /var/crash/*
    OS Execute Command  ls -ltr /var/crash/
    ${os_type}  ${stderr}  ${rc}=  OS Execute Command
    ...  . /etc/os-release; echo $ID
    # Start crash dump utility on OS.
    Run Keyword If  '${os_type}' == 'ubuntu'
    ...    Ubuntu Os Pre Test Setup
    ...  ELSE IF  '${os_type}' == 'rhel'
    ...    RHEL Os Pre Test Setup


RHEL Os Pre Test Setup
    [Documentation]  Pre test setup for RHEL os.

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  kdumpctl start
    Should Contain  ${output}  Kdump already running


Ubuntu Os Pre Test Setup
    [Documentation]  Pre test setup for Ubuntu os.

    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  kdump-config show
    Should Contain  ${output}  ready to kdump


Trigger NMI
    [Documentation]  Inject non-maskable interrupt Redfish URI.
    [Arguments]  ${status_codes}=${HTTP_INTERNAL_SERVER_ERROR}

    # Description of argument(s):
    # valid_status_codes  Return response code from redfis server

    Redfish.Login
    Redfish.Post  ${SYSTEM_BASE_URI}Actions/ComputerSystem.Reset
    ...  body={"ResetType": "Nmi"}  valid_status_codes=[${status_codes}]


Crash Dump Directory Verification
    [Documentation]  Checking of dump directory.

    # Debuging purpose, if test case fail.
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ls -ltr /var/crash/
    ${output}  ${stderr}  ${rc}=  OS Execute Command
    ...  if [ ! "$(ls -A /var/crash)" ]; then echo "'/var/crash' is empty directory."; else echo "'/var/crash' is not empty directory."; fi
    Should Contain  ${output}  is not empty directory
