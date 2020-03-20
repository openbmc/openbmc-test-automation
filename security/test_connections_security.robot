*** Settings ***

Documentation     Testsuite for verify securiy requiremnets.

Variables        ../gui/data/resource_variables.py
Resource         ../gui/lib/resource.robot


*** Variables ***
${range}        ${10}


*** Test Cases ***
Test For Wrong Login Attempt
    [Documentation]  Verify Login functionality with invalid credentials.
    [Tags]   Test_For_Wrong_Login_Attempt

    Open Browser  ${obmc_gui_url}  ${GUI_BROWSER}

    FOR  ${i}  IN  ${range}
      ${invalid_password}=  Catenate  ${password}  '${i}'
      Input Text  ${xpath_textbox_username}  ${username}
      Input Password  ${xpath_textbox_password}  ${invalid_password}
      Click Element  ${xpath_button_login}
      ${status}=   Wait Until Element Is Enabled  ${xpath_button_logout}
      Should Be Equal As Strings  ${status}  ${False}
    END
 



