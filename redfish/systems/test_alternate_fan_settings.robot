*** Settings ***

Documentation  Test Suite for Suppported Fan Modules.

Resource         ../../lib/rest_client.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/resource.robot
Resource         ../../lib/boot_utils.robot
Library          ../../lib/gen_robot_valid.py
Library          ../../lib/gen_robot_keyword.py

Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown Execution
Test Setup       Printn
Test Teardown    Test Teardown Execution


*** Variables ***

@{VALID_MODE_VALUES}   DEFAULT  CUSTOM  HEAVY_IO  MAX_BASE_FAN_FLOOR


*** Test Cases ***

Verify Thermal Current Mode
    [Documentation]  Check current mode is a valid mode value.
    [Tags]  Verify_Thermal_Current_Mode

    # Example:
    #  /xyz/openbmc_project/control/thermal/0
    #
    # Response code:200, Content: {
    # "data": {
    #         "Current": "DEFAULT",
    #         "Supported": [
    #           "DEFAULT",
    #           "CUSTOM",
    #           "HEAVY_IO",
    #           "MAX_BASE_FAN_FLOOR"
    #         },
    #         },
    # "message": "200 OK",
    # "status": "ok"
    # }

    ${current}=  Read Attribute  ${THERMAL_CONTROL_URI}  Current
    Rprint Vars  current

    Valid Value  current  valid_values=${VALID_MODE_VALUES}


Verify Supported Modes Available
    [Documentation]  Check supported modes are valid mode values.
    [Tags]  Verify_Supported_Modes_Available

    ${supported}=  Read Attribute  ${THERMAL_CONTROL_URI}  Supported
    Rprint Vars  supported

    FOR  ${supported_modes}  IN  @{supported}
        Valid Value  supported_modes  valid_values=${VALID_MODE_VALUES}
    END


Verify Supported Modes Switch At Standby
    [Documentation]  Check that supported modes are set successfully at standby.
    [Tags]  Verify_Supported_Modes_Switch_At_Standby
    [Template]  Set and Verify Thermal Mode Switches

    # pre_req_state      thermal_mode_type
    Off                  "DEFAULT"
    Off                  "CUSTOM"
    Off                  "HEAVY_IO"
    Off                  "MAX_BASE_FAN_FLOOR"


Verify Supported Modes Switch At Runtime
    [Documentation]  Check that supported modes are set successfully at runtime.
    [Tags]  Verify_Supported_Modes_Switch_At_Runtime
    [Template]  Set and Verify Thermal Mode Switches

    # pre_req_state      thermal_mode
    On                   "Default"
    On                   "Custom"
    On                   "Heavy_IO"
    On                   "Max_Base_Fan_Floor"


Verify Supported Mode Remains Set After IPL
    [Documentation]  Check that supported modes remain set at runtime.
    [Tags]  Verify_Supported_Mode_Remains_Set_After_IPL
    [Template]  Set and Verify Thermal Mode After IPL

    # pre_req_state      thermal_mode_type
    Off                  "DEFAULT"
    Off                  "CUSTOM"
    Off                  "HEAVY_IO"
    Off                  "MAX_BASE_FAN_FLOOR"


*** Keywords ***

Set and Verify Thermal Mode Switches
    [Documentation]  Verify the thermal mode switches successfully at standby or runtime.
    [Arguments]  ${pre_req_state}  ${thermal_mode}

    # Description of Arguments(s):
    # thermal_mode       Read the supported thermal mode (e.g. "CUSTOM")
    # pre_req_state      Set the state of the host to Standby or Runtime (e.g. "Running")

    Run Key U  Redfish Power ${pre_req_state} \ stack_mode=skip \ quiet=1
    Redfish.Login

    ${mode}=  Redfish.Put  ${THERMAL_CONTROL_URI}/attr/Current  body={"data":${thermal_mode}}

    ${current}=  Read Attribute  ${THERMAL_CONTROL_URI}  Current
    Rprint Vars  current


Set and Verify Thermal Mode After IPL
    [Documentation]  Verify the thermal mode remains set at runtime.
    [Arguments]  ${pre_req_state}  ${thermal_mode}

    Set and Verify Thermal Mode Switches  ${pre_req_state}  ${thermal_mode}

    Run Key U  Redfish Power On \ stack_mode=skip \ quiet=1
    Redfish.Login

    ${current}=  Read Attribute  ${THERMAL_CONTROL_URI}  Current
    Rprint Vars  current


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Printn
    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
