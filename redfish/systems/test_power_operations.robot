*** Settings ***
Documentation    This suite tests Redfish Host power operations.

Resource         ../../lib/boot_utils.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/open_power_utils.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Variables ***

# Extended code to check OCC state, power metric and others.
${additional_power_check}      ${1}
${additional_occ_check}        ${1}

*** Test Cases ***

Verify Redfish Host GracefulShutdown
    [Documentation]  Verify Redfish host graceful shutdown operation.
    [Tags]  Verify_Redfish_Host_GracefulShutdown

    Redfish Power Off


Verify Redfish BMC PowerOn With OCC State
    [Documentation]  Verify Redfish host power on operation.
    [Tags]  Verify_Redfish_BMC_PowerOn_With_OCC_State

    Redfish Power On

    # TODO: Replace OCC state check with redfish property when available.
    Verify OCC State


Verify Redfish BMC PowerOn
    [Documentation]  Verify Redfish host power on operation.
    [Tags]  Verify_Redfish_Host_PowerOn

    Redfish Power On

    Run Keyword If  ${additional_occ_check} == ${1}
    ...  Wait Until Keyword Succeeds  3 mins  30 secs  Match OCC And CPU State Count

    Run Keyword If  ${additional_power_check} == ${1}  Power Check


Verify Redfish BMC GracefulRestart
    [Documentation]  Verify Redfish host graceful restart operation.
    [Tags]  Verify_Redfish_Host_GracefulRestart

    RF SYS GracefulRestart


Verify Redfish BMC PowerOff
    [Documentation]  Verify Redfish host power off operation.
    [Tags]  Verify_Redfish_Host_PowerOff

    Redfish Hard Power Off

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Start SOL Console Logging
    Redfish.Login


Test Teardown Execution
    [Documentation]  Collect FFDC and SOL log.

    FFDC On Test Case Fail
    ${sol_log}=    Stop SOL Console Logging
    Log   ${sol_log}

    Run Keyword If  ${REDFISH_SUPPORTED}
    ...    Redfish Set Auto Reboot  RetryAttempts
    ...  ELSE
    ...    Set Auto Reboot  ${1}
    Redfish.Logout


Power Check
    [Documentation]  Verify PowerConsumedWatts property.

    ${power_uri_list}=  redfish_utils.Get Members URI  /redfish/v1/Chassis/  PowerControl
    Log List  ${power_uri_list}

    # Power entries could be seen across different redfish path, remove the URI
    # where the attribute is non-existent.
    # Example:
    #     ['/redfish/v1/Chassis/chassis/Power',
    #      '/redfish/v1/Chassis/motherboard/Power']
    FOR  ${idx}  IN  @{power_uri_list}
        ${power_control}=  redfish_utils.Get Attribute  ${idx}  PowerControl
        Log Dictionary  ${power_control[0]}

        # Ensure the path does have the attribute else set to EMPTY as default to skip.
        ${value}=  Get Variable Value  ${power_control[0]['PowerConsumedWatts']}  ${EMPTY}
        Run Keyword If  "${value}" == "${EMPTY}"
        ...  Remove Values From List  ${power_uri_list}  ${idx}

        # Check the next available element in the list.
        Continue For Loop If  "${value}" == "${EMPTY}"

        Valid Dict  power_control[${0}]  ['PowerConsumedWatts']

    END

    # Double check, the validation has at least one valid path.
    Should Not Be Empty  ${power_uri_list}
    ...  msg=Should contain at least one element in the list.
