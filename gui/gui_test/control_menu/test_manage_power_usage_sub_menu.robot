*** Settings ***

Documentation  Test OpenBMC GUI "Manage power usage" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_manage_power_heading}      //h1[text()="Manage power usage"]
${xpath_power_ops_checkbox}        //*[@data-test-id='managePowerUsage-checkbox-togglePowerCapField']
${xpath_cap_input_button}          //*[@data-test-id='managePowerUsage-input-powerCapValue']

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

    Page Should Contain Element  ${xpath_power_ops_chcekbox}
    Click Elemet  ${xpath_power_ops_checkbox}
    ${Is_Checkbox_Selected}=  Run Keyword And Return Status  Checkbox Should Be Selected  ${xpath_power_ops_checkbox}
    Run Keyword If  False == ${Is_Checkbox_Selected}  Click Elemet  ${xpath_power_ops_checkbox}
    Checkbox Should Be Selected  ${xpath_power_ops_checkbox}

    # With chcekbox selected, apply cap text successfully.
    Wait Until Element Is Enabled  ${xpath_cap_input_button}  timeout=10

*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_manage_power_usage_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  manage-power-usage
