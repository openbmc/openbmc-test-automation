*** Settings ***
Documentation  The purpose of this test suite is for
...  "OpenBMC ASMI Menu -> Server Overview" module
...  functionality validation. This will validate and
...  verifies variations of supported use cases for
...  the OpenBMC "Server Overview " sub menu
...  functionalities expectation.

Resource   ../../lib/resource.robot
Test Setup  OpenBMC Test Setup
Test Teardown  OpenBMC Test Closure

*** Variables ***
${x_select_overview_1}  //*[@id="nav__top-level"]/li[1]/a/span
${x_select_overview_2}  //a[@href='#/overview/system']
${string_display_content}  Server overview

*** Test Case ***
Verify Title Text Content
    [Documentation]  Verify displaying of text.
    [Tags]  Verify_Title_Text_Content
    Verify Display Content

*** Keywords ***
Verify Display Content
    [Documentation]  Verify displaying of text.
    Click Button  ${x_select_overview_1}
    Click Button  ${x_select_overview_2}
    Page Should Contain  ${string_display_content}
