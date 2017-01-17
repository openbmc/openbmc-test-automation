*** Settings ***
Resource                ../lib/utils.robot

*** Variables ***

# Once the State Manager support is ready remove this variables block
# and use appropriate resource or variable file imports

# State Manager States
${BMC_READY_STATE}           Ready
${BMC_NOT_READY_STATE}       NotReady

${HOST_POWEROFF_TRANS}       xyz.openbmc_project.State.Host.Transition.Off
${HOST_POWERON_TRANS}        xyz.openbmc_project.State.Host.Transition.On
${HOST_POWEROFF_STATE}       xyz.openbmc_project.State.Host.HostState.Off
${HOST_POWERON_STATE}        xyz.openbmc_project.State.Host.HostState.Running

${CHASSIS_POWEROFF_TRANS}    xyz.openbmc_project.State.Chassis.Transition.Off
${CHASSIS_POWERON_TRANS}     xyz.openbmc_project.State.Chassis.Transition.On
${CHASSIS_POWEROFF_STATE}    xyz.openbmc_project.State.Chassis.PowerState.Off
${CHASSIS_POWERON_STATE}     xyz.openbmc_project.State.Chassis.PowerState.On

# State Manager URI's
${BMC_STATE_URI}            /xyz/openbmc_project/state/BMC0/
${HOST_STATE_URI}           /xyz/openbmc_project/state/host0/
${CHASSIS_STATE_URI}        /xyz/openbmc_project/state/chassis0/

${QUIET}  ${0}

*** Keywords ***

Initiate Host Boot
    [Documentation]  Initiate host power on.
    ${args}=  Create Dictionary   data=${HOST_POWERON_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is Host Running


Initiate Host PowerOff
    [Documentation]  Initiate host power off.
    ${args}=  Create Dictionary   data=${HOST_POWEROFF_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    Wait Until Keyword Succeeds
    ...  3 min  10 sec  Is Host Off


Is Host Running
    [Documentation]  Check if Chassis and Host state is ON.
    ${power_state}=  Get Chassis Power State
    Should Be Equal  ${CHASSIS_POWERON_STATE}   ${power_state}
    ${host_state}=  Get Host State
    Should Be Equal  ${HOST_POWERON_STATE}   ${host_state}


Is Host Off
    [Documentation]  Check if Chassis and Host state is OFF.
    ${power_state}=  Get Chassis Power State
    Should Be Equal  ${CHASSIS_POWEROFF_STATE}   ${power_state}
    ${host_state}=  Get Host State
    Should Be Equal  ${HOST_POWEROFF_STATE}   ${host_state}


Get Host State
    [Documentation]  Return the state of the host as a string.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  CurrentHostState
    ...  quiet=${quiet}
    [Return]  ${state}


Get Chassis Power State
    [Documentation]  Return the power state of the Chassis
    ...              as a string.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${CHASSIS_STATE_URI}  CurrentPowerState
    ...  quiet=${quiet}
    [Return]  ${state}


Get BMC State
    [Documentation]  Return the state of the BMC.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${BMC_STATE_URI}  CurrentBMCState  quiet=${quiet}
    [Return]  ${state.rsplit('.', 1)[1]}

Put BMC State
    [Documentation]  Get BMC in given state.
    [Arguments]  ${expected_state}
    # expected_state - expected BMC state

    ${bmc_state}=  Get BMC State
    Run Keyword If  ${bmc_state} == ${expected_state}
    ...  Log BMC is already in ${expected_state} state
    ...  ELSE  Initiate BMC Reboot

    Wait for BMC state  ${expected_state}

# All below are supportive keyword for put BMC state.
# These can be reduced on need basis.

Initiate BMC Reboot
    [Documentation]  Initiate BMC reboot.
    ${resp}=  OpenBMC Post Request
    ...  ${BMC_STATE_URI}action/Reboot   data=${NIL}
    ${jsondata}=  To JSON  ${resp.content}
    Should Be Equal As Strings  ${jsondata['status']}  ok

Is BMC Ready
    [Documentation]  Check if BMC state is Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_READY_STATE}   ${bmc_state}

Is BMC Not Ready
    [Documentation]  Check if BMC state is Not Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_NOT_READY_STATE}   ${bmc_state}

Wait for BMC state
    [Documentation]  
    [Arguments]  ${expected_state}
    Run Keyword If  ${expected_state} == ${BMC_READY_STATE}
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Ready
    ...  ELSE IF  ${expected_state} == ${BMC_NOT_READY_STATE}
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Not Ready
