*** Settings ***
Documentation  Connections and authentication module stability tests.

Library   XvfbRobot
Library   OperatingSystem
Library   Selenium2Library  120  120
Library   Telnet  30 Seconds
Library   Screenshot
Library   OperatingSystem
Library   Collections

*** Variables ***

${bmc_url}       https://${OPENBMC_HOST}
${iterations}    10000
${gui_browser}   chrome

*** Test Cases ***

Test Stability On Large Number Of Wrong Login Attempts To GUI
    [Documentation]  Test stability on large number of wrong login attempts to GUI.
    [Tags]   Test_Stability_On_Large_Number_Of_Wrong_Login_Attempts_To_GUI

    @{status_list}=  Create List

    # Open headless browser.
    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=wrong
    Set Window Size  1920  1080

    Go To  ${bmc_url}

    FOR  ${i}  IN RANGE  ${1}  ${iterations}
        Log To Console  ${i}th login
        Run Keyword And Ignore Error  Login to GUI With Wrong Credentials  ${bmc_url}

        # Every 100th iteration, check BMC GUI is responsive.
        ${status}=  Run Keyword If  ${i} % 100 == 0  Run Keyword And Return Status
        ...  Open Browser  ${bmc_url}
        Append To List  ${status_list}  ${status}
        Run Keyword If  '${status}' == 'True'  Run Keywords  Close Browser  AND  Switch Browser  wrong
    END

    ${fail_count}=  Count Values In List  ${status_list}  False
    Run Keyword If  ${fail_count} > ${1}  FAIL  Could not open BMC GUI ${fail_count} times

*** Keywords ***

Login to GUI With Wrong Credentials
    [Documentation]  Login to GUI With Wrong Credentials.

    Input Text  //*[@id="username"]  root
    Input Password  //*[@id="password"]  wrong_password
    Click Button  //*[@id="login__submit"]

