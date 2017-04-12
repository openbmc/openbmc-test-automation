*** Settings ***

Library  OperatingSystem
Library  Selenium2Library  120  120
# Library  AngularJSLibrary
Library  Screenshot

Resource  resource.txt

*** Keywords ***

Open Browser With URL
    [Documentation]  Open browser with specified URL.
    [Arguments]  ${URL}  ${browser}
    # Description of argument(s):
    # URL  Openbmc GUI URL to be open
    # (e.g. https://openbmc-test.mybluemix.net/#/login )
    # browser  browser used to open above URL
    # (e.g. gc for google chrome, ff for firefox)
    ${browser_ID}=  Open Browser  ${URL}  ${browser}
    [Return]  browser_ID


GUI Power On
    [Documentation]  Power on the CEC using GUI.

    Wait Until Element Is Visible  ${obmc_xpath_power_operations}
    Click Element  ${obmc_xpath_power_operations}
    Page Should Contain  Attempts to power on the server
    Wait Until Element Is Visible  ${obmc_xpath_power_on}
    Click Element  ${obmc_xpath_power_on}

OpenBMC GUI Login
    [Documentation]  Log into OpenBMC GUI.

    Log  ${obmc_BMC_URL}
    Log To Console  ${obmc_BMC_URL}
    Open Browser With URL  ${obmc_BMC_URL}  gc
    Page Should contain Button  ${obmc_xpath_login_button}
    Wait Until Page Contains Element  ${obmc_xpath_uname}
    Input Text  ${obmc_xpath_uname}  ${obmc_user_name}
    Input Password  ${obmc_xpath_password}  ${obmc_password}
    Click Element  ${obmc_xpath_login_button}
    Page Should Contain  System Overview

