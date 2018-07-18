*** Settings ***
Documentation           Verify BMC reboot using REST.

Resource                ../lib/rest_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/boot_utils.robot
Library                 ../lib/bmc_ssh_utils.py

Force Tags  bmcreboot

Suite Setup             Open Connection And Log In
Suite Teardown          Close All Connections
Test Teardown           FFDC On Test Case Fail

*** Variables ***
${SYSTEM_SHUTDOWN_TIME}    ${5}

# Strings to check from journald.
${REBOOT_REGEX}    ^\-- Reboot --


*** Test Cases ***

Test BMC Reboot via REST
    [Documentation]   This test case is to verify bmc reboot using REST.
    [Tags]  Test_BMC_Reboot_via_REST

    ${test_file_path}=  Set Variable  /tmp/before_bmcreboot
    BMC Execute Command  touch ${test_file_path}

    REST OBMC Reboot (off)  stack_mode=normal

    BMC Execute Command  if [ -f ${test_file_path} ] ; then false ; fi
    Verify BMC RTC And UTC Time Drift

    # Check for journald persistency post reboot.
    Check For Regex In Journald  ${REBOOT_REGEX}  error_check=${1}

