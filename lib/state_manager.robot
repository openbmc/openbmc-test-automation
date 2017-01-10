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


*** Keywords ***

Initiate Power On XYZ
    [Documentation]  Initiate host power on.
    ${args}= Create Dictionary data=${HOST_POWERON_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is Power On XYZ


Initiate Power Off XYZ
    [Documentation]  Initiate host power off.
    ${args}= Create Dictionary data=${HOST_POWEROFF_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    Wait Until Keyword Succeeds
    ...  3 min  10 sec  Is Power Off XYZ


Is Power On XYZ
    [Documentation]  Check if Chassis and Host state is ON.
    ${power_state}=  Get Chassis Power State XYZ
    Should Be Equal  ${CHASSIS_POWERON_STATE}   ${power_state}
    ${host_state}=  Get Host State XYZ
    Should Be Equal  ${HOST_POWERON_STATE}   ${host_state}


Is Power Off XYZ
    [Documentation]  Check if Chassis and Host state is OFF.
    ${power_state}=  Get Chassis Power State XYZ
    Should Be Equal  ${CHASSIS_POWEROFF_STATE}   ${power_state}
    ${host_state}=  Get Host State XYZ
    Should Be Equal  ${HOST_POWEROFF_STATE}   ${host_state}


Get Host State XYZ
    [Documentation]  Return the state of the host as a string.
    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  CurrentHostState
    [Return]  ${state}


Get Chassis Power State XYZ
    [Documentation]  Return the  power state of the Chassis
    ...              as a string
    ${state}=
    ...  Read Attribute  ${CHASSIS_STATE_URI}  CurrentPowerState
    [Return]  ${state}
