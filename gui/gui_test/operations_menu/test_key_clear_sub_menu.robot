*** Settings ***

Documentation  Test OpenBMC GUI "Key clear" sub-menu of "Operations" menu.

Resource         ../../lib/gui_resource.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Close All Browsers
Test Setup       Suite Setup Execution

Test Tags        Key_Clear_Sub_Menu

*** Variables ***

${xpath_none_radio}                             //input[@value='NONE']
${xpath_clear_all_radio}                        //input[@value='ALL']
${xpath_clear_hypervisor_system_key_radio}      //input[@value='POWERVM_SYSKEY']
${xpath_clear_settings_button}                  //button[contains(normalize-space(), 'Clear')]

*** Test Cases ***

Verify Navigation To Key Clear Page
    [Documentation]  Verify navigation to Key Clear page.
    [Tags]  Verify_Navigation_To_Key_Clear_Page

    Page Should Contain    Key clear


Verify Existence Of All Buttons In Key Clear Page
    [Documentation]  Verify existence of all buttons in Key Clear page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Key_Clear_Page

    Page Should Contain Element  ${xpath_none_radio}
    Page Should Contain Element  ${xpath_clear_all_radio}
    Page Should Contain Element  ${xpath_clear_hypervisor_system_key_radio}
    Page Should Contain Element  ${xpath_clear_settings_button}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Launch browser and login to GUI, then navigate to Key Clear sub-menu.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_key_clear_sub_menu}  key-clear
