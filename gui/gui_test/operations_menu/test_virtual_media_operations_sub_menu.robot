*** Settings ***

Documentation   Test OpenBMC GUI "Virtual Media" sub-menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close All Browsers
Test Setup      Test Setup Execution

Test Tags       Virtual_Media_Operations_Sub_Menu

*** Variables ***

${xpath_virtual_media_heading}  //h1[text()='Virtual media']
${xpath_add_file_button}        //button[contains(normalize-space(.),'Add file')]

*** Test Cases ***

Verify Navigation To Virtual Media Page
    [Documentation]  Verify navigation to Virtual media page.
    [Tags]  Verify_Navigation_To_Virtual_Media_Page

    Page Should Contain Element  ${xpath_virtual_media_heading}


Verify Virtual Media Page Contains Add File Button
    [Documentation]  Verify Virtual media page contains Add file button.
    [Tags]  Verify_Virtual_Media_Page_Contains_Add_File_Button

    Page Should Contain Element  ${xpath_add_file_button}


*** Keywords ***

Test Setup Execution
    [Documentation]  Launch browser, login to GUI, and navigate to Virtual Media page.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_virtual_media_sub_menu}  virtual-media
