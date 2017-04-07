*** Settings ***

Documentation  This test suite verifies pgood state.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/state_manager.robot

Library  OperatingSystem

Suite Setup     Open Connection And Log In
Suite Teardown  Close All Connections

*** Variables ***

${POWER_URI}  /org/openbmc/control/power0/

*** Test Cases ***

Verify On Good Power Supply
    [Documentation]  Verify pgood state on good power supply.

    ${stdout}  ${stderr}=  Execute Command  /usr/sbin/obmcutil poweron
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 1

Verify On Bad Power Supply
    [Documentation]  Verify pgood state on bad power supply.

    ${status}  ${stderr}=  Execute Command  /usr/sbin/obmcutil poweroff
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 0
