*** Settings ***

Documentation  Test OpenBMC Firmware Update" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close All Browsers

Test Tags      Firmware_Sub_Menu

*** Variables ***

${xpath_firmware_heading}                //h1[text()="Firmware"]
${xpath_add_file_button}                 //span[@class='add-file-btn btn btn-secondary']
#${xpath_add_file_button_disabled} is Xpath of add file button in host poweron state.
${xpath_add_file_button_disabled}        //span[@class='add-file-btn btn disabled btn-secondary']
${xpath_start_update_button}             //*[@data-test-id="firmware-button-startUpdate"]
${xpath_switch_to_running}               //*[@data-test-id="firmware-button-switchToRunning"]

*** Test Cases ***

Verify Navigation To Firmware Page
    [Documentation]  Verify navigation to firmware page.
    [Tags]  Verify_Navigation_To_Firmware_Page

    Page Should Contain Element  ${xpath_firmware_heading}


Verify Existence Of All Sections In Firmware Page
    [Documentation]  Verify existence of all sections in firmware page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Firmware_Page

    Page Should Contain  BMC and server
    Page Should Contain  Update firmware
    Page Should Contain  Access key expiration


###  Power Off Test Cases  ###

Verify Existence Of All Buttons In Firmware Page At Host Power Off
    [Documentation]  Verify existence of all buttons in firmware page at host power off.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_Off

    Power Off Server
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    Wait Until Page Contains    Update firmware  30s
    Minimize Browser Window
    Page Should Contain Element  ${xpath_add_file_button}
    Page Should Contain Element  ${xpath_start_update_button}


Verify Existence Of All Sub Sections Under BMC And Server Section At Poweroff State
    [Documentation]  Verify existence of all sub sections under BMC and server section at poweroff state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Poweroff_State

    Power Off Server
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Visible  ${xpath_switch_to_running}


###  Power On Test Cases  ###

Verify Existence Of All Sub Sections Under BMC And Server Section At Power On State
    [Documentation]  Verify existence of all sub sections under BMC and server section at power on state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Power_On_State

    Power On Server
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Disabled  ${xpath_switch_to_running}


Verify Existence Of All Buttons In Firmware Page At Host Power On
    [Documentation]  Verify existence of all buttons in firmware page at host power on.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_On

    Power On Server
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_firmware_update_sub_menu}  firmware
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
    Minimize Browser Window
    Page Should Contain Element    ${xpath_add_file_button_disabled}
    Element Should Be Disabled  ${xpath_start_update_button}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_firmware_update_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  firmware
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
