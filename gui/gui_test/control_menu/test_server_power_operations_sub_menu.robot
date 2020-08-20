*** Settings ***

Documentation  Test OpenBMC GUI "Server power operations" sub-menu of "Server control".

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***


${xpath_shutdown_button}                  //*[@data-test-id='serverPowerOperations-button-shutDown']
${xpath_reboot_button}                    //*[@data-test-id='serverPowerOperations-button-reboot']
${xpath_poweron_button}                   //*[@data-test-id='serverPowerOperations-button-powerOn']


*** Test Cases ***

Verify PowerOn Button Should Present At Power Off
    [Documentation]  Verify existence of poweron button at power off.
    [Tags]  Verify_PowerOn_Button_Should_Present_At_Power_Off

    Redfish Power Off  stack_mode=skip
    Page Should Contain Element  ${xpath_poweron_button}


Verify Shutdown And Reboot Buttons Presence At Power On
    [Documentation]  Verify existence of shutdown and reboot buttons at power on.
    [Tags]  Verify_Shutdown_And_Reboot_Buttons_Presence_At_Power_On

    Redfish Power On  stack_mode=skip
    Page Should Contain Element  ${xpath_shutdown_button}
    Page Should Contain Element  ${xpath_reboot_button}


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
