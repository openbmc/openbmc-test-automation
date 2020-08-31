*** Settings ***

Documentation   Test OpenBMC GUI "Hardware Status" sub-menu of "Health" menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_hardware_status_heading}  //h1[text()="Hardware status"]

*** Test Cases ***

Verify Navigation To Hardware Status Page
    [Documentation]  Verify navigation to hardware status page.
    [Tags]  Verify_Navigation_To_Hardware_Status_Page

    Page Should Contain Element  ${xpath_hardware_status_heading}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_hardware_status_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  hardware-status
