*** Settings ***

Documentation     Test file corruption on hard power cycle.

Resource          ../lib/pdu/pdu.robot
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections
Test Teardown     FFDC On Test Case Fail

*** Test Cases ***

Test OpenBMC Buster
    Validate Parameters
    ${output}=  Execute Command
    ...  find /var/lib -type f |xargs -n 1 touch
    PDU Power Cycle
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   1min

    # Need to re connect the session
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=
    ...  Execute Command     echo "hello world"
    ...  return_stderr=True  return_rc=True
    Should Be Equal As Integers    ${rc}    ${0}

*** Keywords ***

Validate Parameters
    Should Not Be Empty   ${PDU_IP}
    Should Not Be Empty   ${PDU_TYPE}
    Should Not Be Empty   ${PDU_SLOT_NO}
    Should Not Be Empty   ${PDU_USERNAME}
    Should Not Be Empty   ${PDU_PASSWORD}
