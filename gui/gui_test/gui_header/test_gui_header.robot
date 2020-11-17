*** Settings ***

Documentation   Test OpenBMC GUI header.

Resource        ../../lib/gui_resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser


*** Variables ***

${xpath_header_text}       //*[contains(@class, "navbar-text")]


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


Verify Server Power Button
    [Documentation]  Verify server power operations page on clicking power button.
    [Tags]  Verify_Server_Power_Button

    Wait Until Element Is Visible   ${xpath_server_power_header}
    Click Element  ${xpath_server_power_header}
    Wait Until Page Contains  Server power operations


Verify GUI Logout
    [Documentation]  Verify OpenBMC GUI logout.
    [Tags]  Verify_GUI_Logout

    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}  timeout=15s
