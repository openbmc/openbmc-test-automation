*** Settings ***
Documentation           This suite is for testing OCC: Power capping setting

Resource                ../lib/rest_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/boot_utils.robot

Force Tags  bmcreboot

Suite Setup             Open Connection And Log In
Suite Teardown          Close All Connections
Test Teardown           FFDC On Test Case Fail

*** Variables ***
${SYSTEM_SHUTDOWN_TIME}    ${5}

*** Test Cases ***

Test BMC Reboot via REST
    [Documentation]   This testcase is to verify bmc reboot using REST.
    [Tags]  Test_BMC Reboot_via_REST

    ${test_file_path}=  Set Variable    /tmp/before_bmcreboot
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   touch ${test_file_path}
    ...   return_stderr=True  return_rc=True
    Should Be Equal   ${rc}   ${0}   Unable to create file - ${test_file_path}

    OBMC Reboot (off)
    ${max_wait_time}=
    ...   Evaluate    ${SYSTEM_SHUTDOWN_TIME}+${OPENBMC_REBOOT_TIMEOUT}

    Open Connection And Log In
    ${uptime}=
    ...   Execute Command    cut -d " " -f 1 /proc/uptime| cut -d "." -f 1
    ${uptime}=  Convert To Integer  ${uptime}
    ${uptime}=  Evaluate   ${uptime}/60
    Should Be True  ${uptime}<${max_wait_time}
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command     ls ${test_file_path}
    ...   return_stderr=True  return_rc=True
    Should Be Equal    ${rc}   ${1}
    ...    File ${test_file_path} persist after BMC rebooted

*** Keywords ***
