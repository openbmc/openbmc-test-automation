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

Verify PGood When Power On Using REST
    [Documentation]  Verify pgood state on good power supply.
    [Tags]  Verify_PGood_When_Power_On_Using_REST

    # Initiate Host poweron using rest commands.
    Initiate Host Boot
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 1

Verify PGood When Power Off Using REST
    [Documentation]  Verify pgood state on bad power supply.
    [Tags]  Verify_PGood_When_Power_Off_Using_REST

    # Initiate Host poweroff using rest commands.
    Initiate Host PowerOff
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 0

Verify PGood When Power On Using Obmcutil
    [Documentation]  Verify pgood state on good power supply.
    [Tags]  Verify_PGood_When_Power_On_Using_Obmcutil

    # Initiate Host poweron using obmcutil.
    ${stdout}  ${stderr}=  Execute Command  /usr/sbin/obmcutil poweron
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 1

Verify PGood When Power Off Using Obmcutil
    [Documentation]  Verify pgood state on bad power supply.
    [Tags]  Verify_PGood_When_Power_Off_Using_Obmcutil

    # Initiate Host poweroff using obmctuil.
    ${status}  ${stderr}=  Execute Command  /usr/sbin/obmcutil poweroff
    ...  return_stderr=True
    Should Be Empty  ${stderr}
    ${response}=  OpenBMC Get Request  ${POWER_URI}//attr/pgood

    Should Contain  ${response.content}  "data": 0
