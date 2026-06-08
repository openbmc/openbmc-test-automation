*** Settings ***

Documentation  Test OpenBMC GUI "Virtual Media" sub-menu of "Operations".

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

Test Tags      Virtual_Media

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
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_operations_menu}
    Sleep  1s
    Click Element  ${xpath_virtual_media_sub_menu}
    Sleep  1s
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  virtual-media
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

Test Teardown Execution
    [Documentation]  Do test case teardown tasks.
    ...  Reloads the GUI URL to reset browser state generically.

    Reload GUI Page
    Sleep    1s