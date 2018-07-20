*** Settings ***
Resource          ../lib/utils.robot
Variables         ../data/variables.py

*** Variables ***

${BMC_READY_STATE}           Ready
${BMC_NOT_READY_STATE}       NotReady
${QUIET}  ${0}

# "1" indicates that the new "xyz" interface should be used.
${OBMC_STATES_VERSION}    ${1}

*** Keywords ***

Initiate Host Boot
    [Documentation]  Initiate host power on.
    [Arguments]  ${wait}=${1}

    # Description of arguments:
    # wait  Indicates that this keyword should wait for host running state.

    ${args}=  Create Dictionary   data=${HOST_POWERON_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    # Does caller want to wait for status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword

    Wait Until Keyword Succeeds
    ...  10 min  10 sec  Is Host Running


Initiate Host PowerOff
    [Documentation]  Initiate host power off.
    # 1. Request soft power off
    # 2. Hard power off, if failed.
    [Arguments]  ${wait}=${1}

    # Description of arguments:
    # wait  Indicates that this keyword should wait for host off state.

    ${args}=  Create Dictionary   data=${HOST_POWEROFF_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition   data=${args}

    # Does caller want to wait for status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword

    ${status}=  Run Keyword And Return Status  Wait For PowerOff

    Run Keyword if  '${status}' == '${False}'  Hard Power Off


Wait For PowerOff
    [Documentation]  Wait for power off state.

    # TODO: Reference to open-power/skiboot#81.
    # Revert to 3 minutes once fixed.
    Wait Until Keyword Succeeds  6 min  10 sec  Is Host Off


Hard Power Off
    [Documentation]  Do a hard power off.
    [Arguments]  ${wait}=${1}

    # Description of argument(s):
    # wait  Indicates that this keyword should wait for host off state.

    ${args}=  Create Dictionary  data=${CHASSIS_POWEROFF_TRANS}
    Write Attribute
    ...  ${CHASSIS_STATE_URI}  RequestedPowerTransition  data=${args}

    # Does caller want to wait for status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword

    Wait Until Keyword Succeeds
    ...  1 min  10 sec  Run Keywords  Is Chassis Off  AND  Is Host Off


Initiate Host Reboot
    [Documentation]  Initiate host reboot via REST.
    [Arguments]  ${wait}=${1}

    # Description of arguments:
    # wait  Indicates that this keyword should wait for host reboot state.

    ${args}=  Create Dictionary  data=${HOST_REBOOT_TRANS}
    Write Attribute
    ...  ${HOST_STATE_URI}  RequestedHostTransition  data=${args}

    # Does caller want to wait for host booted status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword

    Is Host Rebooted


Is Host Running
    [Documentation]  Check if host state is "Running".
    # Chassis state should be "On" before we check the host state.
    Is Chassis On
    ${host_state}=  Get Host State
    Should Be Equal  Running  ${host_state}
    # Check to verify that the host is really booted.
    Is OS Booted


Get Host State Attribute
    [Documentation]  Return the state of the host as a string.
    [Arguments]  ${host_attribute}  ${quiet}=${QUIET}

    # Description of argument(s):
    # host_attribute   Host attribute name.
    # quiet            Suppress REST output logging to console.

    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  ${host_attribute}  quiet=${quiet}
    [Return]  ${state}


Is OS Booted
    [Documentation]  Check OS status.

    # Example:
    # "/xyz/openbmc_project/state/host0": {
    #    "AttemptsLeft": 0,
    #    "BootProgress": "xyz.openbmc_project.State.Boot.Progress.ProgressStages.OSStart",
    #    "CurrentHostState": "xyz.openbmc_project.State.Host.HostState.Running",
    #    "OperatingSystemState": "xyz.openbmc_project.State.OperatingSystem.Status.OSStatus.BootComplete",
    #    "RequestedHostTransition": "xyz.openbmc_project.State.Host.Transition.On"
    # }

    ${boot_stage}=  Get Host State Attribute  BootProgress
    Should Be Equal  ${OS_BOOT_START}  ${boot_stage}

    ${os_state}=  Get Host State Attribute  OperatingSystemState
    Should Be Equal  ${OS_BOOT_COMPLETE}  ${os_state}


Is Host Off
    [Documentation]  Check if host state is "Off".
    # Chassis state should be "Off" before we check the host state.
    Is Chassis Off
    ${host_state}=  Get Host State
    Should Be Equal  Off  ${host_state}
    # Check to verify that the host shutdown completely.
    # TODO openbmc/openbmc#2049 - boot sensor not cleared on power off
    #Is OS Off


Is Host Rebooted
    [Documentation]  Checks if host rebooted.

    ${host_trans_state}=  Get Host Trans State
    Should Be Equal  ${host_trans_state}  Reboot
    Is Host Running


Is Chassis On
    [Documentation]  Check if chassis state is "On".
    ${power_state}=  Get Chassis Power State
    Should Be Equal  On  ${power_state}


Is Chassis Off
    [Documentation]  Check if chassis state is "Off".
    ${power_state}=  Get Chassis Power State
    Should Be Equal  Off  ${power_state}

Is Host Quiesced
    [Documentation]  Check if host state is quiesced.
    ${host_state}=  Get Host State
    ${status}=  Run Keyword And Return Status  Should Be Equal
    ...  ${host_state}  Quiesced
    [Return]  ${status}


Recover Quiesced Host
    [Documentation]  Recover host from quisced state.

    ${resp}=  Run Keyword And Return Status  Is Host Quiesced
    Run Keyword If  '${resp}' == 'True'
    ...  Run Keywords  Initiate Host PowerOff  AND
    ...  Log  HOST is recovered from quiesced state


Get Host State
    [Documentation]  Return the state of the host as a string.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  CurrentHostState
    ...  quiet=${quiet}
    [Return]  ${state.rsplit('.', 1)[1]}

Get Host Trans State
    [Documentation]  Return the transition state of host as a string.
    ...              e.g. On, Off, Reboot
    [Arguments]  ${quiet}=${QUIET}
    # Description of arguments:
    # quiet  Suppress REST output logging to console.

    ${state}=
    ...  Read Attribute  ${HOST_STATE_URI}  RequestedHostTransition
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


Get BMC State
    [Documentation]  Return the state of the BMC.
    [Arguments]  ${quiet}=${QUIET}
    # quiet - Suppress REST output logging to console.
    ${state}=
    ...  Read Attribute  ${BMC_STATE_URI}  CurrentBMCState  quiet=${quiet}
    [Return]  ${state.rsplit('.', 1)[1]}


Put BMC State
    [Documentation]  Put BMC in given state.
    [Arguments]  ${expected_state}
    # expected_state - expected BMC state

    ${bmc_state}=  Get BMC State
    Run Keyword If  '${bmc_state}' == '${expected_state}'
    ...  Log  BMC is already in ${expected_state} state
    ...  ELSE  Run Keywords  Initiate BMC Reboot  AND
    ...  Wait for BMC state  ${expected_state}

Initiate BMC Reboot
    [Documentation]  Initiate BMC reboot.
    [Arguments]  ${wait}=${1}

    # Description of argument(s):
    # wait  Indicates that this keyword should wait for ending state..

    ${args}=  Create Dictionary  data=${BMC_REBOOT_TRANS}

    Run Keyword And Ignore Error  Write Attribute
    ...  ${BMC_STATE_URI}  RequestedBMCTransition  data=${args}

    # Does caller want to wait for status?
    Run Keyword If  '${wait}' == '${0}'  Return From Keyword

    ${session_active}=  Check If BMC Reboot Is Initiated
    Run Keyword If  '${session_active}' == '${True}'
    ...  Fail  msg=BMC Reboot didn't occur.

    Check If BMC is Up

Check If BMC Reboot Is Initiated
    [Documentation]  Checks whether BMC Reboot is initiated by checking
    ...              BMC connection loss.
    # Reboot adds 3 seconds delay before forcing reboot
    # To minimize race conditions, we wait for 7 seconds
    Sleep  7s
    ${alive}=   Run Keyword and Return Status
    ...    Open Connection And Log In
    Return From Keyword If   '${alive}' == '${False}'    ${False}
    [Return]    ${True}

Is BMC Ready
    [Documentation]  Check if BMC state is Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_READY_STATE}  ${bmc_state}

Is BMC Not Ready
    [Documentation]  Check if BMC state is Not Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_NOT_READY_STATE}  ${bmc_state}

Wait for BMC state
    [Documentation]  Wait until given BMC state is reached.
    [Arguments]  ${state}
    # state - BMC state to wait for
    Run Keyword If  '${state}' == '${BMC_READY_STATE}'
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Ready
    ...  ELSE IF  '${state}' == '${BMC_NOT_READY_STATE}'
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Not Ready
    ...  ELSE  Fail  msg=Invalid BMC state


Set State Interface Version
    [Documentation]  Set version to indicate which interface to use.
    ${resp}=  Openbmc Get Request  ${CHASSIS_STATE_URI}
    ${status}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Run Keyword If  '${status}' == '${True}'
    ...  Set Global Variable  ${OBMC_STATES_VERSION}  ${1}
    ...  ELSE
    ...  Set Global Variable  ${OBMC_STATES_VERSION}  ${0}


Power Off Request
    [Documentation]  Select appropriate poweroff keyword.
    Run Keyword If  '${OBMC_STATES_VERSION}' == '${0}'
    ...  Initiate Power Off
    ...  ELSE
    ...  Initiate Host PowerOff


Wait For BMC Ready
    [Documentation]  Check BMC state and wait for BMC Ready.
    Wait Until Keyword Succeeds  10 min  10 sec  Is BMC Ready
