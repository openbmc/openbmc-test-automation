*** Settings ***

Documentation  This test suite verifies pgood state.

Resource  ../lib/rest_client.robot
Resource  ../lib/utils.robot
Resource  ../lib/state_manager.robot
Resource  ../lib/ipmi_client.robot

Variables  ../data/variables.py

*** Variables ***

${POWER_URI}  ${CONTROL_URI}/power0/

*** Test Cases ***

Verify PGood When Power On Using REST
    [Documentation]  Verify pgood state on good power supply.
    [Tags]  Verify_PGood_When_Power_On_Using_REST

    # Initiate Host poweron using rest commands.
    Initiate Chassis
    ${chassis_state}=  Read Attribute  ${CHASSIS_STATE_URI}  RequestedPowerTransition

    Should Be Equal  ${chassis_state}  ${CHASSIS_POWERON_TRANS}

Verify PGood When Power Off Using REST
    [Documentation]  Verify pgood state on bad power supply.
    [Tags]  Verify_PGood_When_Power_Off_Using_REST

    # Initiate Host poweroff using rest commands.
    Initiate Chassis Off
    ${data}=  Read Attribute  ${CHASSIS_STATE_URI}  RequestedPowerTransition

    Should Be Equal  ${data}  ${CHASSIS_POWEROFF_TRANS}

Verify PGood When Power On Using IPMI
    [Documentation]  Verify pgood state when power on using IPMI.
    [Tags]  Verify_PGood_When_Power_On_Using_IPMI

    # Initiate Host poweron using IPMI commands.
    Initiate Host Boot Via External IPMI
    ${data}=  Read Attribute  ${CHASSIS_STATE_URI}  CurrentPowerState

    Should Be Equal  ${data}  ${CHASSIS_POWERON_STATE}

Verify PGood When Power Off Using IPMI
    [Documentation]  Verify pgood state when power off using IPMI.
    [Tags]  Verify_PGood_When_Power_Off_Using_IPMI

    # Initiate Host poweroff using IPMI commands.
    Initiate Host PowerOff Via External IPMI
    ${data}=  Read Attribute  ${CHASSIS_STATE_URI}  CurrentPowerState

    Should Be Equal  ${data}  ${CHASSIS_POWEROFF_STATE}

*** Keywords ***

Initiate Chassis
    ${args}=  Create Dictionary   data=${CHASSIS_POWERON_TRANS}
    Write Attribute
    ...  ${CHASSIS_STATE_URI}  RequestedPowerTransition   data=${args}

Initiate Chassis Off
    ${args}=  Create Dictionary   data=${CHASSIS_POWEROFF_TRANS}
    Write Attribute
    ...  ${CHASSIS_STATE_URI}  RequestedPowerTransition   data=${args}
