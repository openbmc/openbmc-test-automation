*** Settings ***
Documentation           This suite is for testing OCC: Power capping setting

Resource                ../lib/rest_client.robot
Resource                ../lib/utils.robot
Resource                ../lib/connection_client.robot
Resource                ../lib/openbmc_ffdc.robot

Force Tags  bmcreboot

Suite Setup             Open Connection And Log In
Suite Teardown          Close All Connections
Test Teardown           Log FFDC

*** Variables ***
${SYSTEM_SHUTDOWN_TIME}    ${5}

*** Test Cases ***

Test WarmReset via REST
    ${warm_test_file}=  Set Variable    /tmp/before_warmreset
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   touch ${warm_test_file}
    ...   return_stderr=True  return_rc=True
    Should Be Equal   ${rc}   ${0}   Unable to create file - ${warm_test_file}

    Trigger Warm Reset
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
    ...   Execute Command     ls ${warm_test_file}
    ...   return_stderr=True  return_rc=True
    Should Be Equal    ${rc}   ${1}
    ...    File ${warm_test_file} persist after BMC rebooted

*** Keywords ***
