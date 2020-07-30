*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu.

Resource        ../../lib/resource.robot

Suite Setup     Suite Setup Execution
Suite Teardown  Close Browser


*** Variables ***
${xpath_event_logs_heading}       //h1[text()="Event logs"]
${xpath_filter_event}             //button[contains(text(),"Filter")]
${xpath_event_severity_ok}        //*[@data-test-id="tableFilter-checkbox-OK"]
${xpath_event_severity_warning}   //*[@data-test-id="tableFilter-checkbox-Warning"]
${xpath_event_severity_critical}  //*[@data-test-id="tableFilter-checkbox-Critical"]
${xpath_event_search}             //input[@placeholder="Search logs"]
${xpath_event_from_date}          //*[@id="input-from-date"]
${xpath_event_to_date}            //*[@id="input-to-date"]
${xpath_select_all_events}        //*[@data-test-id="eventLogs-checkbox-selectAll"]
${xpath_event_action_delete}      //*[@data-test-id="table-button-deleteSelected"]
${xpath_event_action_export}      //*[contains(text(),"Export")]
${xpath_event_action_cancel}      //button[contains(text(),"Cancel")]


*** Test Cases ***

Verify Navigation To Event Logs Page
    [Documentation]  Verify navigation to Event Logs page.
    [Tags]  Verify_Navigation_To_Event_Logs_Page

    Page Should Contain Element  ${xpath_event_logs_heading}


Verify Existence Of All Buttons In Event Logs Page
    [Documentation]  Verify existence of all buttons in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Event_Logs_Page

    # Types of event severity: OK, Warning, Critical.
    Click Element  ${xpath_filter_event}
    Page Should Contain Element  ${xpath_event_severity_ok}  limit=1
    Page Should Contain Element  ${xpath_event_severity_warning}  limit=1
    Page Should Contain Element  ${xpath_event_severity_critical}  limit=1


Verify Existence Of All Input boxes In Event Logs Page
    [Documentation]  Verify existence of all input boxes in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Event_Logs_Page

    # Search logs.
    Page Should Contain Element  ${xpath_event_search}

    # Date filter.
    Page Should Contain Element  ${xpath_event_from_date}  limit=1
    Page Should Contain Element  ${xpath_event_to_date}  limit=1


Verify Event Log Options
    [Documentation]  Verify all the options after selecting event logs.
    [Tags]  Verify_Click_Event_Options

    Create Error Logs  ${1}
    Select All Events
    Page Should Contain Button  ${xpath_event_action_delete}  limit=1
    Page Should Contain Element  ${xpath_event_action_export}  limit=1
    Page Should Contain Element  ${xpath_event_action_cancel}  limit=1


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Event Logs Page

Navigate To Event Logs Page
    [Documentation]  Navigate to the event logs page from main menu.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_event_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  event-logs


Create Error Logs
    [Documentation]  Create given number of error logs.
    [Arguments]  ${log_count}

    # Description of argument(s):
    # log_count  Number of error logs to create.

    FOR  ${num}  IN RANGE  ${log_count}
        Generate Test Error Log
    END

Select All Events
    [Documentation]  Select all error logs.

    Click Element At Coordinates  ${xpath_select_all_events}  0  0
