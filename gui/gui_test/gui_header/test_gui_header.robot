*** Settings ***
Documentation       Test OpenBMC GUI header.

Resource            ../../lib/gui_resource.robot

Suite Teardown      Close Browser
Test Setup          Launch Browser And Login GUI

Test Tags           gui_header


*** Variables ***
${xpath_header_text}    //*[contains(@class, "navbar-text")]


*** Test Cases ***
Verify GUI Header Text
    [Documentation]    Verify text in GUI header.
    [Tags]    verify_gui_header_text

    ${gui_header_text}=    Get Text    ${xpath_header_text}
    Should Contain    ${gui_header_text}    BMC System Management

Verify Server Health Button
    [Documentation]    Verify event log page on clicking health button.
    [Tags]    verify_server_health_button

    Wait Until Element Is Visible    ${xpath_server_health_header}
    Click Element    ${xpath_server_health_header}
    Wait Until Page Contains Element    ${xpath_event_logs_heading}    timeout=15s

Verify Server Power Button
    [Documentation]    Verify server power operations page on clicking power button.
    [Tags]    verify_server_power_button

    Wait Until Element Is Visible    ${xpath_server_power_header}
    Click Element    ${xpath_server_power_header}
    Wait Until Page Contains    Server power operations

Verify GUI Logout
    [Documentation]    Verify OpenBMC GUI logout.
    [Tags]    verify_gui_logout

    Click Element    ${xpath_root_button_menu}
    Click Element    ${xpath_logout_button}
    Wait Until Page Contains Element    ${xpath_login_button}    timeout=15s
    Wait Until Element Is Not Visible    ${xpath_page_loading_progress_bar}    timeout=30

Verify System Serial And Model Number In GUI Header Page
    [Documentation]    Verify system serial and model number in GUI header page.
    [Tags]    verify_system_serial_and_model_number_in_gui_header_page
    [Setup]    Run Keywords    Launch Browser And Login GUI    AND    Redfish Login

    # Model.
    ${redfish_model_number}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    Model
    Element Should Be Visible    //*[@data-test-id='appHeader-container-overview']
    ...    /following-sibling::*/*[text()='${redfish_model_number}']

    # Serial Number.
    ${redfish_serial_number}=    Redfish.Get Attribute    ${SYSTEM_BASE_URI}    SerialNumber
    Element Should Be Visible    //*[@data-test-id='appHeader-container-overview']
    ...    /following-sibling::*/*[text()='${redfish_serial_number}']
    [Teardown]    Run Keywords    Close Browser    AND    Redfish.Logout
