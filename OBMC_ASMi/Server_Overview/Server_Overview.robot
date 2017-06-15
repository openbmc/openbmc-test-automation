*** Settings ***
Documentation    Author: _*Sathyajith MS*_
...              The purpose of this test suite is for
...              "OpenBMC ASMI Menu -> Server Overview"
...              module functionality validation. This will validate and
...              verifies variations of supported use cases for the
...              OpenBMC "Server Overview " sub menu functionalities
...              expectation.

Resource         ${PATH_TEST_RESOURCES}${/}${RESOURCE_FILE}
Test Setup       OpenBMC Test Setup
Test Teardown    OpenBMC Test Closure

*** Variables ***

${xpath_SEL_OVERVIEW_1}      //*[@id="nav__top-level"]/li[1]/a/span
${xpath_SEL_OVERVIEW_2}      //a[@href='#/overview/system']
${string_Display_Content}    System Overview

*** Test Case ***

TC#1
    [Documentation]    Verify Displaying of Text.
    [Tags]             Verify_Text_Content  BMCReadyState  BMCRunState
    Verify Display Content



*** Keywords ***

Verify Display Content
    [Documentation]    Verify Displaying of Text.
    Click Button              ${xpath_SEL_OVERVIEW_1}
    Click Button              ${xpath_SEL_OVERVIEW_2}
    Page Should Contain       ${string_Display_Content}
