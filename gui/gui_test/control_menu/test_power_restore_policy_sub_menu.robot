*** Settings ***

Documentation  Test OpenBMC GUI "Power restore policy" sub-menu of "Server control" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/bmc_redfish_resource.robot
Resource        ../../../lib/openbmc_ffdc.robot
Resource        ../../../lib/boot_utils.robot
Resource        ../../../lib/utils.robot
Resource        ../../../lib/state_manager.robot
Library         ../../../lib/bmc_ssh_utils.py


Suite Setup      Launch Browser And Login GUI
Suite Teardown   Close Browser
Test Setup       Test Setup Execution


*** Variables ***

${xpath_power_restore_policy_heading}  //h1[text()="Power restore policy"]
${xpath_AlwaysOn_radio}                //input[@value='AlwaysOn']
${xpath_AlwaysOff_radio}               //input[@value='AlwaysOff']
${xpath_LastState_radio}               //input[@value='LastState']
${xpath_save_settings_button}          //button[contains(text(),'Save settings')]
${xpath_reboot_button}                 //*[@data-test-id='serverPowerOperations-button-reboot']
${xpath_current_power_state}           //*[@data-test-id='powerServerOps-text-hostStatus']


*** Test Cases ***

Verify Navigation To Power Restore Policy Page
    [Documentation]  Verify navigation to Power Restore Policy page.
    [Tags]  Verify_Navigation_To_Power_Restore_Policy_Page

    Page Should Contain Element  ${xpath_power_restore_policy_heading}


Verify Existence Of All Sections In Power Restore Policy Page
    [Documentation]  Verify existence of all sections in Power Restore Policy page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Power_Restore_Policy_Page

    Page Should Contain  Power restore policies


Verify Existence Of All Buttons In Power Restore Policy Page
    [Documentation]  Verify existence of All Buttons.
    [Tags]  Verify_Existence_Of_All_Buttons

    Page Should Contain Element  ${xpath_AlwaysOn_radio}
    Page Should Contain Element  ${xpath_AlwaysOff_radio}
    Page Should Contain Element  ${xpath_LastState_radio}
    Page Should Contain Element  ${xpath_save_settings_button}


Verify Power Restore Policy with Always_OFF With Host OFF 
    [Documentation]  Verify Power Restore Policy ALWAYS OFF With HOST OFF.
    [Tags]  Verify_Power_Restore_Policy_ALWAYS_OFF_With_HOST_OFF
    [Setup]  Run Keywords  Redfish Power Off  stack_mode=skip  AND  Test Setup Execution

    Click Element At Coordinates  ${xpath_AlwaysOff_radio}  0  0
    Click Element At Coordinates  ${xpath_save_settings_button}  0  0

    Open Connection And Log In    
    OBMC Reboot (off)
    Sleep  10min
#    Wait Until Keyword Succeeds  10 min  15 sec  Element Should Contain  ${xpath_current_power_state}

    Check the Host Status OFF


Verify Power Restore Policy with Last_State With Host OFF
    [Documentation]  Verify Power Restore Policy Last State With HOST OFF.
    [Tags]  Verify_Power_Restore_Policy_LAST_STATE__With_HOST_OFF
    [Setup]  Run Keywords  Redfish Power Off  stack_mode=skip  AND  Test Setup Execution

    Click Element At Coordinates  ${xpath_LastState_radio}  0  0
    Click Element At Coordinates  ${xpath_save_settings_button}  0  0

    OBMC Reboot (off)
    #Sleep  20s

    Check the Host Status OFF


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_power_restore_policy_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  power-restore-policy


Wait BMC Online
    [Documentation]  Wait for Host to be online.

    Click Element  ${xpath_refresh_button}


Check the Host Status OFF
    [Documentation]  Expected Host Status is OFF

    Launch Browser And Login GUI
    Click Element  ${xpath_control_menu}
    Click Element  ${xpath_server_power_operations_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  server-power-operations

    Page Should Contain Element  ${xpath_current_power_state}
    Element Should Contain   ${xpath_current_power_state}  Off
 
