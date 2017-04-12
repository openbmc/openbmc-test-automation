*** Settings ***

Library  OperatingSystem
Library  Selenium2Library  120  120
# Library  AngularJSLibrary
Library  Screenshot

Resource  resource.txt

*** Keywords ***

Open Browser With URL
    [Documentation]  Opens browser with specified URL.
    [Arguments]  ${URL}  ${l_browser}
    ${browser_ID}=  Open Browser  ${URL}  ${l_browser}
    [Return]  browser_ID


Power-Operations Power On the CEC
    [Documentation]  Power on the CEC.

    Wait Until Element Is Visible  ${xpath_power-operations}
    Click Element  ${xpath_power-operations}
    Page Should Contain  Attempts to power on the server
    Wait Until Element Is Visible  ${xpath_power-on}
    Click Element  ${xpath_power-on}

