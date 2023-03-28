*** Settings ***

Documentation  Test OpenBMC GUI "Power" sub-menu of "Resource Management".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution


*** Variables ***

${xpath_power_heading}                   //h1[text()="Power"]
${xpath_power_ops_checkbox}              //*[@data-test-id='power-checkbox-togglePowerCapField']
${xpath_cap_input_button}                //*[@data-test-id='power-input-powerCap']
${xpath_submit_button}                   //*[@data-test-id='power-button-savePowerCapValue']
${xpath_select_static}                   //input[@value='Static']
${xpath_select_powersaving}              //input[@value='PowerSaving']
${xpath_select_maximum_performance}      //input[@value='MaximumPerformance']
${xpath_update_power_save_mode}          //button[contains(text(),'Update power saver mode')]
${xpath_page_loading_progress_bar}       //*[@aria-label='Page loading progress bar']
${xpath_idle_power_saver_checkbox}       //*[@data-test-id='power-checkbox-toggleIdlePower']
${xpath_to_enter_delay_time}             //*[@data-test-id='power-input-enterDwellTimeSeconds']
${xpath_to_enter_utilization_threshold}  //*[@data-test-id='power-input-enterUtilizationPercent']
${xpath_to_exit_delay_time}              //*[@data-test-id='power-input-exitDwellTimeSeconds']
${xpath_to_exit_utilization_threshold}   //*[@data-test-id='power-input-exitUtilizationPercent']
${xpath_update_idle_power_saver_button}  //button[contains(text(),'Update idle power saver')]
${xpath_reset_to_default_button}         //button[contains(text(),'Reset to default')]

*** Test Cases ***

Verify Navigation To Power Page
    [Documentation]  Verify navigation to power page.
    [Tags]  Verify_Navigation_To_Power_Page

    Page Should Contain Element  ${xpath_power_heading}
    Click Element  ${xpath_overview_menu}
    Click Element  ${xpath_power_link}
    Location Should Contain  power
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
    Page Should Contain Element  ${xpath_idle_power_saver_checkbox}
    Page Should Contain Element  ${xpath_to_enter_delay_time}
    Page Should Contain Element  ${xpath_to_enter_utilization_threshold}
    Page Should Contain Element  ${xpath_to_exit_delay_time}
    Page Should Contain Element  ${xpath_to_exit_utilization_threshold}
    Page Should Contain Element  ${xpath_update_idle_power_saver_button}
    Page Should Contain Element  ${xpath_reset_to_default_button}


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
    Wait Until Element Is Visible   ${xpath_success_message}  timeout=60
    Wait Until Element Is Not Visible   ${xpath_success_message}  timeout=60


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
    Wait Until Element Is Visible   ${xpath_success_message}  timeout=60
    Wait Until Element Is Not Visible   ${xpath_success_message}  timeout=60


Verify And Set Idle Power Saver To New Values And Restore Back To Default

    [Documentation]  Enable checkbox,set and verify random values of idle power saver
    ...  After Verify restore values back to default.
    [Tags]  Verify_And_Set_Idle_Power_Saver_To_New_Values_And_Restore_Back_To_Default
    [Setup]  Run Keywords  Enable Idle Power Saver Value  
    ...  AND  Restore Idle Power Saver Value To Default
    [Teardown]  Restore Idle Power Saver Value To Default

    Run Keyword If  '${checkbox_initial_state}' == 'False'
    ...  Click Element At Coordinates  ${xpath_idle_power_saver_checkbox}  0  0

    # Now input a idle power saver values and submit.
    Wait Until Element Is Enabled  ${xpath_to_enter_delay_time}  timeout=10

    # Get default (or) initial values of idle power saver.
    ${initial_idle_power_saver_values}=  Get Idle Power Saver Value
    Log To Console  ${initial_idle_power_saver_values}

    # Taking random enter and exit of delaytime and utilization threshold values.
    ${enter_delaytime}=  Evaluate  random.randint(10, 600)  modules=random
    ${exit_delaytime}=  Evaluate  random.randint(10, 600)  modules=random
    ${enter_utilization_threshold}=  Evaluate  random.randint(1, 95)  modules=random
    ${exit_utilization_threshold}=  Evaluate  random.randint(${enter_utilization_threshold}, 95) 
    ...  modules=random

    # To enter delay time and utilization threshold values.
    Input Text  ${xpath_to_enter_delay_time}  ${enter_delaytime}
    Input Text  ${xpath_to_enter_utilization_threshold}  ${enter_utilization_threshold}

    # To exit delay time and utilization threshold values.
    Input Text  ${xpath_to_exit_delay_time}  ${exit_delaytime}
    Input Text  ${xpath_to_exit_utilization_threshold}  ${exit_utilization_threshold}

    # Save and update idle power saver values.
    Click Element  ${xpath_update_idle_power_saver_button}

    # Get update idle power saver values.
    ${updated_idle_power_saver_values}=  Get Idle Power Saver Value

    # Verify is idle power saver value set.
    Log To Console  ${updated_idle_power_saver_values}
    Log To Console  ${initial_idle_power_saver_values}
    Should Not Be Equal  ${updated_idle_power_saver_values}  ${initial_idle_power_saver_values}


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


Enable Idle Power Saver Value
    [Documentation]  Enable Idle Power Saver Value By Selecting The Checkbox.

    Wait Until Page Contains Element  ${xpath_idle_power_saver_checkbox}
    ${status}=  Run Keyword And Return Status  Checkbox Should Be Selected  
    ...  ${xpath_idle_power_saver_checkbox}
    Set Suite Variable  ${checkbox_initial_state}  ${status}

Restore Idle Power Saver Value To Default
    [Documentation]  Restore Idle Power Saver Values To Default.

    ${status}=  Run Keyword And Return Status  Checkbox Should Be Selected  
    ...  ${xpath_idle_power_saver_checkbox}
    Run Keyword If  ${status} != ${checkbox_initial_state}
    ...  Click Element At Coordinates  ${xpath_idle_power_saver_checkbox}  0  0
    Click Element  ${xpath_reset_to_default_button}

Get Idle Power Saver Value
    [Documentation]  Return the power cap value.

    #  "IdlePowerSaver": {
    #        "Enabled": true,
    #        "EnterDwellTimeSeconds": 240,
    #        "EnterUtilizationPercent": 10,
    #        "ExitDwellTimeSeconds": 8,
    #        "ExitUtilizationPercent": 12
    #  }

    ${power_saver}=  Redfish.Get Properties  /redfish/v1/Systems/system
    ${enter_dwell_time_seconds}=  Set Variable  ${power_saver['IdlePowerSaver']['EnterDwellTimeSeconds']}
    ${enter_utilization_percent}=  Set Variable  ${power_saver['IdlePowerSaver']['EnterUtilizationPercent']}
    ${exit_dwell_time_seconds}=  Set Variable  ${power_saver['IdlePowerSaver']['ExitDwellTimeSeconds']}
    ${exit_utilization_percent}=  Set Variable  ${power_saver['IdlePowerSaver']['ExitUtilizationPercent']}
    [Return]   ${enter_dwell_time_seconds}  ${enter_utilization_percent} 
    ...  ${exit_dwell_time_seconds}  ${exit_utilization_percent}

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

    Logout GUI
    Close Browser
    Redfish.Logout
