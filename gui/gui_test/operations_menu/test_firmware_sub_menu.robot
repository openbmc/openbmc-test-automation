*** Settings ***

Documentation  Test OpenBMC Firmware Update" sub menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser

*** Variables ***

${xpath_firmware_heading}                //h1[text()="Firmware"]
${xpath_add_file_button}                 //*[@id='image-file']
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


Verify Existence Of All Buttons In Firmware Page At Host Power Off
    [Documentation]  Verify existence of all buttons in firmware page at host power off.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_Off

    Redfish Power Off  stack_mode=skip

    Page Should Contain Element  ${xpath_add_file_button}
    Page Should Contain Element  ${xpath_start_update_button}


Verify Existence Of All Sub Sections Under BMC And Server Section At Poweroff State
    [Documentation]  Verify existence of all sub sections under BMC and server section at poweroff state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Poweroff_State

    Redfish Power Off  stack_mode=skip  quiet=1

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Visible  ${xpath_switch_to_running}


Verify Existence Of All Buttons In Firmware Page At Host Power On
    [Documentation]  Verify existence of all buttons in firmware page at host power on.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Firmware_Page_At_Host_Power_On

    Redfish Power On  stack_mode=skip

    Element Should Be Disabled  ${xpath_add_file_button}
    Element Should Be Disabled  ${xpath_start_update_button}


Verify Existence Of All Sub Sections Under BMC And Server Section At Power On State
    [Documentation]  Verify existence of all sub sections under BMC and server section at power on state.
    [Tags]  Verify_Existence_Of_All_Sub_Sections_Under_BMC_And_Server_Section_At_Power_On_State

    Redfish Power On  stack_mode=skip  quiet=1

    Page Should Contain  Running image
    Page Should Contain  Backup image
    Page Should Contain  Temporary
    Page Should Contain  Permanent
    Element Should Be Disabled  ${xpath_switch_to_running}


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Launch Browser And Login GUI
    Click Element  ${xpath_operations_menu}
    Click Element  ${xpath_firmware_update_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  firmware
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30
