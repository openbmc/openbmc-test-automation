*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}  //h1[contains(text(), "Overview")]
${refesh_button}               //*[text()[contains(.,"Refresh")]]

*** Test Cases ***

Verify Message Under High Priority Events Section In Case Of No Events
    [Documentation]  Verify message under high priority events section in case of no events.
    [Tags]  Verify_Message_Under_High_Priority_Events_Section_In_Case_Of_No_Events

    Redfish Purge Event Log
    Click Element  ${refesh_button}
    Wait Until Page Contains  no high priority events to display  timeout=10


Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

