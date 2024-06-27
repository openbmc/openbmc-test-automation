*** Settings ***
Documentation       Get the system power supply readings and power mode settings.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution


*** Variables ***
# Power Mode Settings
@{VALID_POWER_MODES}    Static    PowerSaving    MaximumPerformance


*** Test Cases ***
Verify Current Power Mode Setting
    [Documentation]    Verify the current power mode setting.
    [Tags]    verify_current_power_mode_setting

    # Example:
    # /redfish/v1/Systems/system
    #
    # "PartNumber": "",
    # "PowerMode": "MaximumPerformance",
    # "PowerMode@Redfish.AllowableValues": [
    #    "Static",
    #    "MaximumPerformance",
    #    "PowerSaving"
    # ],

    ${current_power_mode}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    PowerMode
    Rprint Vars    current_power_mode

    Valid Value    current_power_mode    valid_values=${VALID_POWER_MODES}

Verify Allowable Power Mode Settings
    [Documentation]    Verify the allowable power mode settings.
    [Tags]    verify_allowable_power_mode_settings

    ${allowed_power_modes}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    PowerMode@Redfish.AllowableValues
    Rprint Vars    allowed_power_modes

    Valid List    allowed_power_modes    valid_values=${VALID_POWER_MODES}

Verify Allowable Power Mode Settings Switch At Runtime
    [Documentation]    Check the allowable power modes are set successfully at runtime.
    [Tags]    verify_allowable_power_mode_settings_switch_at_runtime
    [Template]    Set and Verify Power Mode Switches

    # power_mode_type
    Static
    PowerSaving
    MaximumPerformance

Verify State Of PowerSubsystem PowerSupplies
    [Documentation]    Verify the state of the system's powersupplies is ok and enabled.
    [Tags]    verify_state_of_powersubsystem_powersupplies

    ${total_num_supplies}=    Get Total Number Of PowerSupplies
    Rprint Vars    total_num_supplies

    ${resp}=    Redfish.Get    ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/PowerSubsystem/PowerSupplies
    FOR    ${entry}    IN RANGE    0    ${total_num_supplies}
        ${resp_resource}=    Redfish.Get    ${resp.dict["Members"][${entry}]["@odata.id"]}
        # Example:
        # "Status": {
        #    "Health": "OK",
        #    "State": "Enabled"
        # },
        Should Be Equal As Strings    ${resp_resource.dict["Status"]["Health"]}    OK
        Should Be Equal As Strings    ${resp_resource.dict["Status"]["State"]}    Enabled
    END

Verify PowerSubsystem Efficiency Percent For All PowerSupplies
    [Documentation]    Verify the efficiency percent for all powersupplies.
    [Tags]    verify_powersubsystem_efficiency_percent_for_all_powersupplies

    ${total_num_supplies}=    Get Total Number Of PowerSupplies
    Rprint Vars    total_num_supplies

    # Example output:
    # - Executing: get('/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply0')
    # resp_resource:
    #    [0]:
    #    [EfficiencyPercent]:    90
    # - Executing: get('/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply1')
    # resp_resource:
    #    [0]:
    #    [EfficiencyPercent]:    90

    ${resp}=    Redfish.Get    ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/PowerSubsystem/PowerSupplies
    FOR    ${entry}    IN RANGE    0    ${total_num_supplies}
        ${resp_resource}=    Redfish.Get Attribute
        ...    ${resp.dict["Members"][${entry}]["@odata.id"]}    EfficiencyRatings
        Rprint Vars    resp_resource
        ${efficiency_percentages}=    Nested Get    EfficiencyPercent    ${resp_resource}
        Valid List    efficiency_percentages    [90]
    END


*** Keywords ***
Get Total Number Of PowerSupplies
    [Documentation]    Return total number of powersupplies.
    ${total_num_powersupplies}=    Redfish.Get Attribute
    ...    ${REDFISH_CHASSIS_URI}/${CHASSIS_ID}/PowerSubsystem/PowerSupplies    Members@odata.count

    # Entries "Members@odata.count": 4,
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply0'}
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply1'}
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply2'}
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply3'}
    RETURN    ${total_num_powersupplies}

Set and Verify Power Mode Switches
    [Documentation]    Verify the power mode switches successfully at standby or runtime.
    [Arguments]    ${power_mode}

    # Description of Arguments(s):
    # power_mode    Read the allowable power modes (e.g. "Static")

    Redfish.Login

    Redfish.patch    ${SYSTEM_BASE_URI}
    ...    body={"PowerMode":"${power_mode}"}    valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ${current_power_mode}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    PowerMode
    Should Be Equal As Strings    ${power_mode}    ${current_power_mode}
    ...    msg=The thermal mode does not match the current fan mode.
    Rprint Vars    current_power_mode

Suite Teardown Execution
    [Documentation]    Do the post suite teardown.

    Redfish.Logout

Suite Setup Execution
    [Documentation]    Do test case setup tasks.

    Printn
    Redfish.Login

Test Teardown Execution
    [Documentation]    Do the post test teardown.

    FFDC On Test Case Fail
