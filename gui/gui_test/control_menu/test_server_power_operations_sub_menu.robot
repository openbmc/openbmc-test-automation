*** Settings ***

Documentation  Test OpenBMC GUI "Server power operations" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_tpm_policy_button}    //input[@id='tpm-required-policy']
${xpath_save_button}          //button[contains(text(),'Save')]

*** Test Cases ***

Verify Existence Of All Sections In Server Power Operations Page
    [Documentation]  Verify existence of all sections in Server Power Operations page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Server_Power_Operations_Page

    Page Should Contain  Current status
    Page Should Contain  Host OS boot settings
    Page Should Contain  Operations


Verify Existence Of Buttons In Host Os Boot Settings
    [Documentation]  Verify existence of buttons in Host OS boot settings.
    [Tags]  Verify_Existence_Of_Buttons_In_Host_Os_Boot_Settings

    Page Should Contain Element  ${xpath_tpm_policy_button}
    Page Should Contain Element  ${xpath_save_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_server_power_operations_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  server-power-operations
