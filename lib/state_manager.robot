*** Settings ***
Resource                ../lib/utils.robot

*** Variables ***

# Once the State Manager support is ready remove this variables block
# and use appropriate resource or variable file imports

# State Manager States
${HOST_POWEROFF_TRANS}       xyz.openbmc_project.State.Host.Transition.Off
${HOST_POWERON_TRANS}        xyz.openbmc_project.State.Host.Transition.On
${HOST_POWEROFF_STATE}       xyz.openbmc_project.State.Host.HostState.Off
${HOST_POWERON_STATE}        xyz.openbmc_project.State.Host.HostState.Running

${CHASSIS_POWEROFF_TRANS}    xyz.openbmc_project.State.Chassis.Transition.Off
${CHASSIS_POWERON_TRANS}     xyz.openbmc_project.State.Chassis.Transition.On
${CHASSIS_POWEROFF_STATE}    xyz.openbmc_project.State.Chassis.PowerState.Off
${CHASSIS_POWERON_STATE}     xyz.openbmc_project.State.Chassis.PowerState.On

# State Manager URI's
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
    Should Be Equal  On   ${power_state}
    ${host_state}=  Get Host State
    Should Be Equal  Running  ${host_state}


Is Host Off
    [Documentation]  Check if Chassis and Host state is OFF.
    ${power_state}=  Get Chassis Power State
    Should Be Equal  Off  ${power_state}
    ${host_state}=  Get Host State
    Should Be Equal  Off  ${host_state}


Get Host State
    [Documentation]  Return the state of the host as a string.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  CurrentHostState
    ...  quiet=${quiet}
    [Return]  ${state.rsplit('.', 1)[1]}


Get Chassis Power State
    [Documentation]  Return the power state of the Chassis
    ...              as a string.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${CHASSIS_STATE_URI}  CurrentPowerState
    ...  quiet=${quiet}
    [Return]  ${state.rsplit('.', 1)[1]}
