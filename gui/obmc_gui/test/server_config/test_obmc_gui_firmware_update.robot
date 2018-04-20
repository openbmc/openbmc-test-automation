*** Settings ***

Documentation  Test Open BMC GUI server configuration firmware update..

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login OpenBMC GUI
Suite Teardown  Logout And Close Browser
Test Setup      Test Setup Execution

*** Variables ***
${xpath_select_server_config}   //*[@id="nav__top-level"]/li[4]/button
${xpath_select_firmware}        //a[@href='#/configuration/firmware']
${xpath_choose_file_button}     //*[@id="firmware__upload-form"]/div[1]/label/span[1]

*** Test Cases ***

Verify Select Firmware From Server Configuration
    [Documentation]  Verify ability to select firmware option from server
    ...  configuration sub-menu.
    [Tags]  Verify_Select_Firmware_From_Server_Configuration

    Wait Until Page Contains  Firmware
    Page Should contain  Manage BMC and server firmware

Verify Choose File Button Click
    [Documentation]  Verify choose file button is clickable.
    [Tags]  Verify_Choose_File_Button_Click

    Page Should Contain  No file chosen
    Page Should Contain Element  ${xpath_choose_file_button}
    Click Element  ${xpath_choose_file_button}

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_select_server_config}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_firmware}
