*** Settings ***

Documentation  Test OpenBMC GUI "Overview" menu.

Resource        ../../lib/resource.robot
Resource        ../../../lib/logging_utils.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***

${xpath_overview_page_header}   //h1[contains(text(), "Overview")]
${xpath_eventlogs_page_header}  //h1[contains(text(), "Event logs")]
${view_all_event_logs}          //*[@data-test-id='overviewEvents-button-eventLogs']
${CMD_INTERNAL_FAILURE}        busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 0

*** Test Cases ***

Verify View All Event Logs Button
    [Documentation]  Verify all event log buttons in Overview page.
    [Tags]  Verify_View_All_Event_Logs_Button

    Create Test Error Log
    Page Should Contain Element  ${view_all_event_logs}
    Click Element  ${view_all_event_logs}
    Wait Until Page Contains Element  ${xpath_eventlogs_page_header}  timeout=30


Verify Existence Of All Sections In Overview Page
    [Documentation]  Verify existence of all sections in Overview page.
    [Tags]  Verify_Existence_Of_All_Sections_In_Overview_Page

    Page Should Contain  BMC information
    Page Should Contain  Server information
    Page Should Contain  Network information
    Page Should Contain  Power consumption
    Page Should Contain  High priority events


*** Keywords ***

Create Test Error Log
    [Documentation]  Generate test error log.

    BMC Execute Command  ${CMD_INTERNAL_FAILURE}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Click Element  ${xpath_overview_menu}
    Wait Until Page Contains Element  ${xpath_overview_page_header}

