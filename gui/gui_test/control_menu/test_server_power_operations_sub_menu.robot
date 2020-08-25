*** Settings ***

Documentation  Test OpenBMC GUI "Server power operations" sub-menu of "Server control".

Resource        ../../lib/resource.robot
Resource        ../../../lib/state_manager.robot  #Manash

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_shutdown_button}             //*[@data-test-id='serverPowerOperations-button-shutDown']
${xpath_shutdown_orderly_radio}      //*[@data-test-id='serverPowerOperations-radio-shutdownOrderly']
${xpath_shutdown_immediate_radio}    //*[@data-test-id='serverPowerOperations-radio-shutdownImmediate']

*** Test Cases ***

Verify Shutdown Should Happen By Clicking Immediate Shutdown Button
    [Documentation]  Verify Shutdown Should Happen By Clicking Immediate Shutdown Button.
    [Tags]  Verify_Shutdown_Should_Happen_By_Clicking_Immediate_Shutdown_Button

    Redfish Power On  stack_mode=skip
    Click Element  ${xpath_shutdown_immediate_radio}
    Click Element  ${xpath_shutdown_button}
    Wait Until Keyword Succeeds  10 min  60 sec  Is Host Off


Verify Shutdown Should Happen By Clicking Orderly Shutdown Button
    [Documentation]  Verify Shutdown Should Happen By Clicking Orderly Shutdown Button.
    [Tags]  Verify_Shutdown_Should_Happen_By_Clicking_Orderly_Shutdown_Button

    Redfish Power On  stack_mode=skip
    Click Element  ${xpath_shutdown_orderly_radio}
    Click Element  ${xpath_shutdown_button}
    Wait Until Keyword Succeeds  10 min  60 sec  Is Host Off


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
