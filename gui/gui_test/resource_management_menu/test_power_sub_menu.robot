*** Settings ***

Documentation  Test OpenBMC GUI "Power" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***

${xpath_power_heading}                //h1[text()="Power"]
${xpath_power_ops_checkbox}           //*[@data-test-id='power-checkbox-togglePowerCapField']
${xpath_cap_input_button}             //*[@data-test-id='power-input-powerCap']
${xpath_submit_button}                //*[@data-test-id='power-button-savePowerCapValue']
${xpath_ideal_power_saver_heading}    //h2[text()="Idle power saver"]
${xpath_power_and_performance_mode}   //h2[text()="Power and performance mode"]

*** Test Cases ***

Verify Navigation To Power Page
    [Documentation]  Verify navigation to power page.
    [Tags]  Verify_Navigation_To_Power_Page

    Page Should Contain Element  ${xpath_power_heading}


Verify Existence Of All Sections In Power Page
    [Documentation]  Verify existence of all sections in power page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Power_Page

    Page Should Contain  Current power consumption
    Page Should Contain  Power cap setting
    Page Should Contain  Power cap value
    Page Should Contain  Power and performance mode
    Page Should Contain  Idle power saver

Verify Existence Of All Buttons In Power Page
    [Documentation]  Verify existence of all buttons in power page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Power_Page

    Page Should Contain Element  ${xpath_power_ops_checkbox}
    Page Should Contain Element  ${xpath_cap_input_button}
    Page Should Contain Element  ${xpath_submit_button}


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
    [Documentation]   Verify power cap cannot be set or modified when power cap check box is off.
    [Tags]  Verify_Server_Power_Cap_Setting_Is_Off

    Page Should Contain Element  ${xpath_power_ops_checkbox}

    # Set a value in check box.
    ${checkbox_Selected}=  Run Keyword And Return Status
    ...  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Run Keyword If  False == ${checkbox_Selected}  Click Element  ${xpath_power_ops_checkbox}
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10
    Input Text  ${xpath_cap_input_button}  ${499}

    # Now disable input box by deselecting the check box
    Click Element  ${xpath_power_ops_checkbox}
    Checkbox Should Not Be Selected  ${xpath_power_ops_checkbox}
    Element Should Be Disabled  ${xpath_cap_input_button}

    # Click submit.
    Click Element  ${xpath_submit_button}
    ${power_cap}=  Get Power Cap Value
    Should Not Be True  ${power_cap} == 499


Verify Navigation To Ideal Power Saver
    [Documentation]  Verify navigation to ideal power saver page.
    [Tags]  Verify_Navigation_To_Ideal_Power_Saver

    Page Should Contain Element  ${xpath_ideal_power_saver_heading}


Verify Navigation To Power And Powerformance Mode
    [Documentation]  Verify navigation to power and performance mode
    [Tags]  Verify_Navigation_To_Power_And_Powerformance_Mode

    Page Should Contain Element  ${xpath_power_and_performance_mode}


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


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_resource_management_menu}
    Click Element  ${xpath_power_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  power
