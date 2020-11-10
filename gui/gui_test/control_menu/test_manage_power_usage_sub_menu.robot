*** Settings ***

Documentation  Test OpenBMC GUI "Manage power usage" sub-menu of "Server control".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_manage_power_heading}      //h1[text()="Manage power usage"]
${xpath_power_ops_checkbox}        //*[@data-test-id='managePowerUsage-checkbox-togglePowerCapField']
${xpath_cap_input_button}          //*[@data-test-id='managePowerUsage-input-powerCapValue']
${xpath_submit_button}             //*[@data-test-id='managePowerUsage-button-savePowerCapValue']

*** Test Cases ***

Verify Navigation To Manage Power Usage Page
    [Documentation]  Verify navigation to manage power usage page.
    [Tags]  Verify_Navigation_To_Manage_Power_Usage_Page

    Page Should Contain Element  ${xpath_manage_power_heading}


Verify Existence Of All Sections In Manage Power Usage Page
    [Documentation]  Verify existence of all sections in Manage Power Usage page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Manage_Power_Usage_Page

    Page Should Contain  Current power consumption
    Page Should Contain  Power cap setting
    Page Should Contain  Power cap value


Verify Server Power Cap Setting Is On
    [Documentation]  Verify server power cap setting is on.
    [Tags]  Verify_Server_Power_Cap_Setting_Is_On
    [Setup]  Save Initial Power Cap State
    [Teardown]  Restore Initial Power Cap State

    Run Keyword If  '${checkbox_initial_state}' == 'False'
    ...  Click Element At Coordinates  ${xpath_power_ops_checkbox}  0  0

    # Now input a cap value and submit.
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10
    Input Text  ${xpath_cap_input_button}  ${600}
    Click Element  ${xpath_submit_button}
    Wait Until Keyword Succeeds  1 min  15 sec  Is Power Cap Value Set  600


Verify Server Power Cap Setting Is Off
    [Documentation]  Verify power cap cannot be set when it is off.
    [Tags]  Verify_Server_Power_Cap_Setting_Is_Off

    Page Should Contain Element  ${xpath_power_ops_checkbox}

    # Set a value in check box.
    ${checkbox_Selected}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Run Keyword If  False == ${checkbox_Selected}  Click Element  ${xpath_power_ops_checkbox}
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10
    Input Text  ${xpath_cap_input_button}  ${499}

    # Now disable input box by deselecting the check box
    Click Element  ${xpath_power_ops_checkbox}
    Checkbox Should Not Be Selected  ${xpath_power_ops_checkbox}
    Element Should Be Disabled  ${xpath_cap_input_button}

    # Click submit.
    Click Element  ${xpath_submit_button}
    ${cap}=  Get Power Cap Value
    Should Not Be True  ${cap} == 499


*** Keywords ***

Is Power Cap Value Set
    [Documentation]  Check if power cap value is set to the given value.
    [Arguments]  ${expected_value}

    ${cap}=  Get Power Cap Value
    Should Be Equal  ${current_cap}  ${expected_value}


Save Initial Power Cap State
    [Documentation]  Save the initial power cap state.

    Wait Until Page Contains Element  ${xpath_power_ops_checkbox}
    ${status}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Set Suite Variable  ${checkbox_initial_state}  ${status}


Restore Initial Power Cap State
    [Documentation]  Restore the initial power cap state.

    ${status}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Run Keyword If  ${status} != ${checkbox_initial_state}
    ...  Click Element At Coordinates  ${xpath_power_ops_checkbox}  0  0


Get Power Cap Value
    [Documentation]  Return the power cap value.

    ${redfish_power}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Power

    # In Redfish version, LimitInWatts is for power cap. However, its stored NOT exactly in json
    # format so with additional steps in consequent steps string is converted to json formatted
    # so that a json object can be formed.
    #
    # "PowerControl": [
    #    {
    #        "@odata.id": "/redfish/v1/Chassis/chassis/Power#/PowerControl/0",
    #        "@odata.type": "#Power.v1_0_0.PowerControl",
    #        "MemberId": "0",
    #        "Name": "Chassis Power Control",
    #        "PowerLimit": {
    #            "LimitInWatts": 3000.0
    #        },
    #        "PowerMetrics": {
    #            "AverageConsumedWatts": 16,
    #            "IntervalInMin": 10,
    #            "MaxConsumedWatts": 22
    #        }
    #    }
    # ],

    [return]  ${redfish_power['PowerControl'][0]['PowerLimit']['LimitInWatts']}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_manage_power_usage_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  manage-power-usage
