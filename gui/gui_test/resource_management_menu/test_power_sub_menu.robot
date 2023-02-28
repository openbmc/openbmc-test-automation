*** Settings ***

Documentation  Test OpenBMC GUI "Power" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution


*** Variables ***

${xpath_power_heading}                //h1[text()="Power"]
${xpath_power_ops_checkbox}           //*[@data-test-id='power-checkbox-togglePowerCapField']
${xpath_cap_input_button}             //*[@data-test-id='power-input-powerCap']
${xpath_submit_button}                //*[@data-test-id='power-button-savePowerCapValue']
${xpath_select_static}                //input[@value='Static']
${xpath_select_powersaving}           //input[@value='PowerSaving']
${xpath_select_maximum_performance}   //input[@value='MaximumPerformance']
${xpath_update_power_save_mode}       //button[contains(text(),'Update power saver mode')]
${xpath_page_loading_progress_bar}    //*[@aria-label='Page loading progress bar']
${xpath_success_message}              //*[contains(text(),"Success")]


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
    Page Should Contain Element  ${xpath_select_static}
    Page Should Contain Element  ${xpath_select_powersaving}
    Page Should Contain Element  ${xpath_select_maximum_performance}
    Page Should Contain Element  ${xpath_update_power_save_mode}


Verify Server Power Cap Setting Is On
    [Documentation]  Verify server power cap setting is on.
    [Tags]  Verify_Server_Power_Cap_Setting_Is_On
    [Setup]  Save Initial Power Cap State
    [Teardown]  Restore Initial Power Cap State

    Run Keyword If  '${checkbox_initial_state}' == 'False'
    ...  Click Element At Coordinates  ${xpath_power_ops_checkbox}  0  0

    # Now input a cap value and submit.
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10

    # Get maximum and minimum values of power cap.
    ${resp}=  Redfish.Get Properties  /redfish/v1/Chassis/${CHASSIS_ID}/EnvironmentMetrics

    ${power_cap_value}=  Evaluate
    ...  random.randint(${resp['PowerLimitWatts']['AllowableMin']},${resp['PowerLimitWatts']['AllowableMax']})
    ...  modules=random

    Input Text  ${xpath_cap_input_button}  ${power_cap_value}
    Click Element  ${xpath_submit_button}
    Wait Until Keyword Succeeds  1 min  15 sec  Is Power Cap Value Set  ${power_cap_value}


Verify Server Power Cap Setting With Power Cap Disabled
    [Documentation]  Verify that valid server power cap value can be set
    ...  in GUI with power cap is in disabled state.
    [Tags]  Verify_Server_Power_Cap_Setting_With_Power_Cap_Disabled
    [Setup]  Save Initial Power Cap State
    [Teardown]  Restore Initial Power Cap State

    Run Keyword If  '${checkbox_initial_state}' == 'True'
    ...  Click Element At Coordinates  ${xpath_power_ops_checkbox}  0  0

    # Now input a cap value and submit.
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10

    # Get maximum and minimum values of power cap.
    ${resp}=  Redfish.Get Properties  /redfish/v1/Chassis/${CHASSIS_ID}/EnvironmentMetrics

    ${power_cap_value}=  Evaluate
    ...  random.randint(${resp['PowerLimitWatts']['AllowableMin']},${resp['PowerLimitWatts']['AllowableMax']})
    ...  modules=random

    Input Text  ${xpath_cap_input_button}  ${power_cap_value}
    Click Element  ${xpath_submit_button}
    Wait Until Keyword Succeeds  1 min  15 sec  Is Power Cap Value Set  ${power_cap_value}


*** Keywords ***

Is Power Cap Value Set
    [Documentation]  Check if power cap value is set to the given value.
    [Arguments]  ${expected_value}

    ${cap}=  Get Power Cap Value
    Should Be Equal  ${cap}  ${expected_value}


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

    ${redfish_power}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/EnvironmentMetrics

    # In Redfish version, LimitInWatts is for power cap. However, its stored NOT exactly in json
    # format so with additional steps in consequent steps string is converted to json formatted
    # so that a json object can be formed.
    #
    # "Id": "EnvironmentMetrics",
    #   "Name": "Chassis Environment Metrics",
    #   "PowerLimitWatts": {
    #   "AllowableMax": 2488,
    #   "AllowableMin": 1778,
    #   "ControlMode": "Disabled",
    #   "SetPoint": 2400,


    [return]  ${redfish_power['PowerLimitWatts']['SetPoint']}


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_resource_management_menu}
    Click Element  ${xpath_power_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  power
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Redfish.Login

Suite Teardown Execution
    [Documentation]  Do suite teardown tasks.

    Wait Until Element Is Not Visible   ${xpath_success_message}  timeout=30
    Logout GUI
    Close Browser
    Redfish.Logout
