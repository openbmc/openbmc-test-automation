*** Settings ***

Documentation     Test file corruption on hard power cycle.

Resource          ../lib/pdu/pdu.robot
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections
Test Teardown     FFDC On Test Case Fail

Force Tags  AC_Cycles

*** Test Cases ***

Test OpenBMC Buster
    [Documentation]  Test the OpenBMC buster.
    Validate Parameters
    ${output}=  Execute Command
    ...  find /var/lib -type f |xargs -n 1 touch
    PDU Power Cycle
    Wait For Host To Ping  ${OPENBMC_HOST}
    Sleep   1min

    # Need to re connect the session
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=  Execute Command  echo "hello world"
    ...  return_stderr=True  return_rc=True
    Should Be Equal As Integers  ${rc}    ${0}

*** Keywords ***

Validate Parameters
    [Documentation]  Validate the PDU parameters.
    Should Not Be Empty  ${PDU_IP}
    Should Not Be Empty  ${PDU_TYPE}
    Should Not Be Empty  ${PDU_SLOT_NO}
    Should Not Be Empty  ${PDU_USERNAME}
    Should Not Be Empty  ${PDU_PASSWORD}
