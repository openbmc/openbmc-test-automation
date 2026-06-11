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
${xpath_start_button}           //button[contains(normalize-space(.),'Start')]
${xpath_stop_button}            //button[contains(normalize-space(.),'Stop')]
${xpath_file_input}             //input[@type='file']
${css_success_toast}            css=div.toast.text-bg-success.show
${css_success_toast_header}     css=div.toast.text-bg-success.show .toast-header strong
${css_success_toast_body}       css=div.toast.text-bg-success.show .toast-body
${css_success_toast_close}      css=div.toast.text-bg-success.show .toast-header button.btn-close


*** Test Cases ***

Verify Navigation To Virtual Media Page
    [Documentation]  Verify navigation to Virtual media page.
    [Tags]  Verify_Navigation_To_Virtual_Media_Page

    Page Should Contain Element  ${xpath_virtual_media_heading}


Verify Virtual Media Page Contains Add File Button
    [Documentation]  Verify Virtual media page contains Add file button.
    [Tags]  Verify_Virtual_Media_Page_Contains_Add_File_Button

    Page Should Contain Element  ${xpath_add_file_button}


Verify Virtual Media File Upload Start And Stop
    [Documentation]  Verify virtual media add file upload, start and stop functionality.
    [Tags]  Verify_Virtual_Media_File_Upload_Start_And_Stop

    Should Not Be Empty  ${VIRTUAL_MEDIA_FILE_PATH}
    ...  msg=VIRTUAL_MEDIA_FILE_PATH must be set before running this test

    # Verify Add file button is present
    Page Should Contain Element  ${xpath_add_file_button}

    # Make file input visible via JavaScript and upload file
    # (bypasses native OS file dialog which Selenium cannot interact with)
    Execute Javascript
    ...  document.querySelector('input[type="file"]').style.display = 'block';
    Choose File  ${xpath_file_input}  ${VIRTUAL_MEDIA_FILE_PATH}
    Sleep  2s
    Capture Page Screenshot  virtual_media_after_add_file.png

    # Verify Start button is now enabled (file was selected successfully)
    Wait Until Element Is Enabled  ${xpath_start_button}  timeout=10s

    # Click Start button to begin virtual media session
    Click Element  ${xpath_start_button}

    # Validate "Server running" toast success message appears after Start
    Wait Until Element Is Visible  ${css_success_toast}  5s
    Wait Until Keyword Succeeds  10x  300ms  Element Text Should Be  ${css_success_toast_header}  Success
    Wait Until Keyword Succeeds  10x  300ms  Element Text Should Be  ${css_success_toast_body}  Server running

    # Take screenshot after clicking Start (with toast message visible)
    Capture Page Screenshot  virtual_media_after_start.png
    Click Element  ${css_success_toast_close}

    Sleep  2s

    # Click Stop button to end virtual media session
    Click Element  ${xpath_stop_button}

    # Validate "Server closed successfully" toast success message appears after Stop
    Wait Until Element Is Visible  ${css_success_toast}    5s
    Wait Until Keyword Succeeds  10x  300ms  Element Text Should Be  ${css_success_toast_header}  Success
    Wait Until Keyword Succeeds  10x  300ms  Element Text Should Be  ${css_success_toast_body}  Server closed successfully

    # Take screenshot after clicking Stop (with toast message visible)
    Capture Page Screenshot  virtual_media_after_stop.png
    Click Element  ${css_success_toast_close}


*** Keywords ***

Test Setup Execution
    [Documentation]  Launch browser, login to GUI, and navigate to Virtual Media page.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_operations_menu}  ${xpath_virtual_media_sub_menu}  virtual-media
