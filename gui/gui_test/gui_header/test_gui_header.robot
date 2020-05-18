*** Settings ***

Documentation   Test OpenBMC GUI header.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser


*** Variables ***

${xpath_header_text}    //*[contains(@class, "navbar-text")]


*** Test Cases ***

Verify GUI Header Text
    [Documentation]  Verify text in GUI header.
    [Tags]  Verify_GUI_Header_Text

    ${gui_header_text}=  Get Text  ${xpath_header_text}
    Should Contain  ${gui_header_text}  BMC System Management


Verify GUI Logout
    [Documentation]  Verify OpenBMC GUI logout.
    [Tags]  Verify_GUI_Logout

    Click Element  ${xpath_logout_button}
    Wait Until Page Contains Element  ${xpath_login_button}  timeout=15s
