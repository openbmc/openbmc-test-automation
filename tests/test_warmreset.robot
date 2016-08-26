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
    ${stdout}   ${stderr}   ${rc}=  Execute Command     touch ${warm_test_file}     return_stderr=True  return_rc=True
    Should Be Equal     ${rc}   ${0}    Unable to create file - ${warm_test_file}

    ${bmc_uri}=     Get BMC Link
    ${data} =   create dictionary   data=@{EMPTY}
    ${resp} =   openbmc post request    ${bmc_uri}/action/warmReset     data=${data}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    Sleep   ${SYSTEM_SHUTDOWN_TIME}min
    Wait For Host To Ping   ${OPENBMC_HOST}
    ${max_wait_time}=   Evaluate    ${SYSTEM_SHUTDOWN_TIME}+${OPENBMC_REBOOT_TIMEOUT}

    Open Connection And Log In
    ${uptime}=  Execute Command    cut -d " " -f 1 /proc/uptime| cut -d "." -f 1
    ${uptime}=  Convert To Integer  ${uptime}
    ${uptime}=  Evaluate   ${uptime}/60
    Should Be True  ${uptime}<${max_wait_time}
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=  Execute Command     ls ${warm_test_file}    return_stderr=True  return_rc=True
    Should Be Equal     ${rc}   ${1}    File ${warm_test_file} does exist even after reboot of BMC, error:${stderr}, stdput: ${stdout}

*** Keywords ***
Get BMC Link
    ${resp}=    OpenBMC Get Request     /org/openbmc/control/
    ${jsondata}=   To Json    ${resp.content}
    log     ${jsondata}
    : FOR    ${ELEMENT}    IN    @{jsondata["data"]}
    \   log     ${ELEMENT}
    \   ${found}=   Get Lines Matching Pattern      ${ELEMENT}      *control/bmc*
    \   Return From Keyword If     '${found}' != ''     ${found}
