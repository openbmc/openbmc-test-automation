*** Settings ***

Documentation  Test OpenBMC GUI "Manage power usage" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***


*** Test Cases ***

Verify Existence Of All Sections In Manage Power Usage Page
    [Documentation]  Verify existence of all sections in Manage Power Usage page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Manage_Power_Usage_Page

    Page Should Contain  Current power consumption
    Page Should Contain  Power cap setting
    Page Should Contain  Power cap value


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_manage_power_usage_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  manage-power-usage

