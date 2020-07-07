*** Settings ***

Documentation  Test OpenBMC GUI "Server power operations" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***


*** Test Cases ***

Verify Existence Of All Sections In Server Power Operations Page
    [Documentation]  Verify existence of all sections in Server Power Operations page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Server_Power_Operations_Page

    Page Should Contain  Current status
    Page Should Contain  Host OS boot settings
    Page Should Contain  Operations


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_server_power_operations_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  server-power-operations
