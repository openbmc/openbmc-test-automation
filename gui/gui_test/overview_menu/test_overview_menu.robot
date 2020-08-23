*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}   //h1[contains(text(), "Overview")]
${view_all_event_logs}          //*[@data-test-id='overviewEvents-button-eventLogs']

*** Test Cases ***

Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


Verify View All Event Logs Button
    [Documentation]  Verify view all event log button in overview page. 
    [Tags]  Verify_View_All_Event_Logs_Button

    Generate Test Error Log
    Page Should Contain Element  ${view_all_event_logs}  timeout=30
    Click Element  ${view_all_event_logs}
    Wait Until Page Contains Element  ${xpath_event_header}  timeout=30


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

