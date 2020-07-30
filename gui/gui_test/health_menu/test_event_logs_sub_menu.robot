*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu.

Resource        ../../lib/resource.robot

Suite Setup     Launch Browser And Login GUI
Suite Teardown  Close Browser
Test Setup      Test Setup Execution


*** Variables ***
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

Verify Existence Of All Sections In Event Logs Page
    [Documentation]  Verify existence of all sections in Event Logs page.
    [Setup]  Navigate To Event Logs Page
    [Tags]  Verify_Existence_Of_All_Sections_In_Event_Logs_Page

    Page Should Contain  Event logs


Verify Filters By Severity Elements Appear
    [Documentation]  Check the presence of filters by severity.
    [Setup]  Navigate To Event Logs Page
    [Tags]  Verify_Filters_By_Severity_Elements_Appear

    # Types of event severity: OK, Warning, Critical.
    Click Element  ${xpath_filter_event}
    Page Should Contain Element  ${xpath_event_severity_ok}  limit=1
    Page Should Contain Element  ${xpath_event_severity_warning}  limit=1
    Page Should Contain Element  ${xpath_event_severity_critical}  limit=1


Verify Content Search Element Appears
    [Documentation]  Check that the "event search element is available with
    ...  filter" button appears.
    [Setup]  Navigate To Event Logs Page
    [Tags]  Verify_Content_Search_Element_Appears

    Page Should Contain Element  ${xpath_event_search}


Verify Filter By Date Element Appears
    [Documentation]  Check that the "filter by date" elements are available and
    ...  visible.
    [Setup]  Navigate To Event Logs Page
    [Tags]  Verify_Filter_By_Date_Element_Appears

    Page Should Contain Element  ${xpath_event_from_date}  limit=1
    Page Should Contain Element  ${xpath_event_to_date}  limit=1


Verify Click Events Check Box
    [Documentation]  Check that "event check box" element appears and on click
    ...  should be able to see elements like "Delete" button and "Export" element.
    [Tags]  Verify_Click_Events_Check_Box

    Create Error Logs  ${1}
    Click Element  ${xpath_select_refresh_button}
    Sleep  2s
    Select All Events
    Page Should Contain Button  ${xpath_event_action_delete}  limit=1
    Page Should Contain Element  ${xpath_event_action_export}  limit=1
    Page Should Contain Element  ${xpath_event_action_cancel}  limit=1


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Navigate To Event Logs Page
    Delete Error Logs And Verify
    Install Error Log Tarball

Navigate To Event Logs Page
    [Documentation]  Navigate to the event logs page from main menu.

    Click Element  ${xpath_health_menu}
    Click Element  ${xpath_event_logs_sub_menu}
    Wait Until Keyword Succeeds  30 sec  5 sec  Location Should Contain  event-logs

Install Error Log Tarball
    [Documentation]  Copy the script to create error logs.

    ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball

Create Error Logs
    [Documentation]  Create given number of error logs.
    [Arguments]  ${number_of_error_logs}

    # Description of argument(s):
    # number_of_error_logs       Number of error logs to create.

    FOR  ${num}  IN RANGE  ${number_of_error_logs}
        Create Test Error Log
    END

Select All Events
    [Documentation]  Select all error logs.

    Click Element At Coordinates  ${xpath_select_all_events}  0  0
