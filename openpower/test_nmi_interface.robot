*** Settings ***
Documentation   Test Non-maskable interrupt functionality.

Resource        ../lib/bmc_redfish_resource.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/secureboot/secureboot.robot
Resource        ../lib/state_manager.robot
Library         ../lib/bmc_ssh_utils.py
Library         ../syslib/utils_os.py

Test Teardown   FFDC On Test Case Fail
Suite Teardown  Redfish.Logout


*** Test Cases ***

Trigger NMI When OPAL/Host OS Is Not Up
    [Documentation]  Verify return error code from Redfish
    ...  while injecting NMI when HOST OS is not up.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Not_Up

    Redfish Power Off
    Trigger NMI


Trigger NMI When OPAL/Host OS Is Running And Secureboot Is Disabled
    [Documentation]  Verify valid return status code from Redfish
    ...  while injecting NMI, when HOST OS is running and
    ...  secureboot is disabled.
    [Tags]  Trigger_NMI_When_OPAL/Host_OS_Is_Running_And_Secureboot_Is_Disabled
    [Setup]  Test Setup Execution  ${0}

    Trigger NMI  valid_status_codes=[${HTTP_OK}]
    Verify Crash Dump Directory After NMI Inject


*** Keywords ***

Verify Crash Dump Directory After NMI Inject
    [Documentation]  Verification of crash dump directory after NMI inject.

    Wait Until Keyword Succeeds  10 min  1 min  Is Host Rebooted
    Is OS Booted
    Wait Until Keyword Succeeds  1 min  10 sec  Verify Crash Dump Directory


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
    ${os_release_info}=  Get OS Release Info
    # Start crash dump utility on OS.
    ${cmd}=  Set Variable If
    ...  '${os_release_info['id']}' == 'ubuntu'  kdump-config show  kdumpctl start
    OS Execute Command  ${cmd}  print_out=1


Trigger NMI
    [Documentation]  Inject non-maskable interrupt Redfish URI.
    [Arguments]  ${valid_status_codes}=[${HTTP_INTERNAL_SERVER_ERROR}]

    # Description of argument(s):
    # valid_status_codes  A list of status codes that the
    #                     caller considers acceptable.
    #                     See lib/redfish_plus.py for details.

    Redfish.Login
    Redfish.Post  ${SYSTEM_BASE_URI}Actions/ComputerSystem.Reset
    ...  body={"ResetType": "Nmi"}  valid_status_codes=${valid_status_codes}


Verify Crash Dump Directory
    [Documentation]  Verify that the crash dump directory is not empty.

    # As per the requirement, there should be a crash dump file
    # after successful NMI injection.

    ${output}  ${stderr}  ${rc}=
    ...  OS Execute Command  ls -ltr /var/crash/*  print_out=1
