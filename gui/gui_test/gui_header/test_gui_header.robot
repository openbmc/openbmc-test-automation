*** Settings ***

Documentation   Test OpenBMC GUI header.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser


*** Variables ***

${xpath_header_text}       //*[contains(@class, "navbar-text")]
${xpath_sensors_filter}    //button[contains(text(),'Filter')]
${xpath_filter_ok}         //*[@data-test-id='tableFilter-checkbox-OK']
${xpath_filter_warning}    //*[@data-test-id='tableFilter-checkbox-Warning']
${xpath_filter_critical}   //*[@data-test-id='tableFilter-checkbox-Critical']
${xpath_filter_clear_all}  //*[@data-test-id='tableFilter-button-clearAll']

*** Test Cases ***

Verify GUI Header Text
    [Documentation]  Verify text in GUI header.
    [Tags]  Verify_GUI_Header_Text

    ${gui_header_text}=  Get Text  ${xpath_header_text}
    Should Contain  ${gui_header_text}  BMC System Management


Verify Server Health Button
    [Documentation]  Verify event log page on clicking health button.
    [Tags]  Verify_Server_Health_Button

    Wait Until Element Is Visible   ${xpath_server_health_header}
    Click Element  ${xpath_server_health_header}
    Wait Until Page Contains Element  ${xpath_event_header}  timeout=15s


Verify Sensors Filter From Server Health Clickable
    [Documentation]  Verify sensors filter from server health clickable
    [Tags]  Verify_Sensors_Filter_From_Server_Health_Clickable

    Wait Until Element Is Visible   ${xpath_server_health_header}
    Click Element  ${xpath_server_health_header}
    Wait Until Page Contains Element  ${xpath_sensors_filter}  timeout=15s
    Click Element  ${xpath_sensors_filter}

    Page Should Contain Element  ${xpath_filter_ok}
    Page Should Contain Element  ${xpath_filter_warning}
    Page Should Contain Element  ${xpath_filter_critical}
    Page Should Contain Element  ${xpath_filter_clear_all}


Verify GUI Logout
    [Documentation]  Verify OpenBMC GUI logout.
    [Tags]  Verify_GUI_Logout

    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}  timeout=15s