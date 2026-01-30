*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu of "Logs" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot
Variables       ../../../data/pel_variables.py

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution

Test Tags      Event_Logs_Sub_Menu

*** Variables ***
${xpath_event_logs_heading}       //h1[text()="Event logs"]
${xpath_filter_event}             //button[contains(normalize-space(.),"Filter")]
${xpath_event_severity_ok}        //*[@data-test-id="tableFilter-checkbox-OK"]
${xpath_event_severity_warning}   //*[@data-test-id="tableFilter-checkbox-Warning"]
${xpath_event_severity_critical}  //*[@data-test-id="tableFilter-checkbox-Critical"]
${xpath_event_from_date}          //*[@id="input-from-date"]
${xpath_event_to_date}            //*[@id="input-to-date"]
${xpath_select_all_events}        //*[@data-test-id="eventLogs-checkbox-selectAll"]
${xpath_event_action_delete}      //*[@data-test-id="table-button-deleteSelected"]
${xpath_event_action_export}      //*[contains(text(),"Export")]
${xpath_event_action_cancel}      //button[contains(text(),"Cancel")]
${xpath_delete_first_row}         //*[@data-test-id="eventLogs-button-deleteRow-0"][2]
${xpath_confirm_delete}           //button[text()="Delete"]
${xpath_event_status_resolved}    //*[@data-test-id="tableFilter-checkbox-Resolved"]
${xpath_event_status_unresolved}  //*[@data-test-id="tableFilter-checkbox-Unresolved"]
${xpath_event_action_download}    //button[text()[normalize-space()='Download']]
${xpath_success_message}          //*[contains(text(),"Success")]
${xpath_resolved_button}          //button[contains(text(),"Resolve")]
${xpath_unresolved_button}        //button[contains(text(),"Unresolve")]
${xpath_filter_clearall_button}   //button[contains(normalize-space(.),"Clear all")]
${xpath_clear_search}             //button[@title="Clear search input"]
${xpath_event_log_resolve}        //*[@name="switch"]
${xpath_event_logs_resolve}       //button[contains(text(),'Resolve')]
${xpath_event_log_data}           //td[contains(text(),'Critical')]/following-sibling::td[3]

*** Test Cases ***

Verify Navigation To Event Logs Page
    [Documentation]  Verify navigation to Event Logs page.
    [Tags]  Verify_Navigation_To_Event_Logs_Page

    Page Should Contain Element  ${xpath_event_logs_heading}


Verify Existence Of All Buttons In Event Logs Page
    [Documentation]  Verify existence of all buttons in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Event_Logs_Page
    [Setup]  Click Element  ${xpath_filter_event}
    [Teardown]  Click Button  ${xpath_filter_clearall_button}

    # Types of event severity: OK, Warning, Critical.
    Page Should Contain Element  ${xpath_event_severity_ok}  limit=1
    Page Should Contain Element  ${xpath_event_severity_warning}  limit=1
    Page Should Contain Element  ${xpath_event_severity_critical}  limit=1

    # Types of event status: Resolved, Unresolved.
    Page Should Contain Element  ${xpath_event_status_resolved}  limit=1
    Page Should Contain Element  ${xpath_event_status_unresolved}  limit=1


Verify Existence Of All Input Boxes In Event Logs Page
    [Documentation]  Verify existence of all input boxes in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Event_Logs_Page

    # Search logs.
    Page Should Contain Element  ${xpath_event_search}

    # Date filter.
    Page Should Contain Element  ${xpath_event_from_date}  limit=1
    Page Should Contain Element  ${xpath_event_to_date}  limit=1


Select Single Error Log And Delete
    [Documentation]  Select single error log and delete it.
    [Tags]  Select_Single_Error_Log_And_Delete

    Create Error Logs  ${2}
    ${number_of_events_before}=  Get Number Of Event Logs
    Click Element  ${xpath_delete_first_row}
    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}
    ${number_of_events_after}=  Get Number Of Event Logs
    Should Be Equal  ${number_of_events_before -1}  ${number_of_events_after}
    ...  msg=Failed to delete single error log entry.
    Wait Until Element Is Not Visible   ${xpath_success_message}  timeout=30


Select All Error Logs And Verify Buttons
    [Documentation]  Select all error logs and verify delete, export and cancel buttons.
    [Tags]  Select_All_Error_Logs_And_Verify_Buttons

    Create Error Logs  ${2}
    Wait Until Element Is Visible  ${xpath_delete_first_row}
    Select All Events
    Page Should Contain Element  ${xpath_resolved_button}
    Page Should Contain Element  ${xpath_unresolved_button}
    Page Should Contain Element  ${xpath_event_action_download}
    Page Should Contain Element  ${xpath_event_action_delete}
    Page Should Contain Element  ${xpath_event_action_cancel}


Select And Verify Default UTC Timezone For Events
    [Documentation]  Select and verify that default UTC timezone is displayed for an event.
    [Tags]  Select_And_Verify_Default_UTC_Timezone_For_Events
    [Setup]  Run Keywords  Redfish.Login  AND  Redfish Purge Event Log
    [Teardown]  Redfish.Logout

    Create Error Logs  ${1}

    # Set Default timezone in profile settings page.
    Set Timezone In Profile Settings Page  Default
    Navigate To Event Logs Page

    # Get date and time from backend.
    ${event_data}=  Get Event Logs
    # Date format: 2023-05-02T04:49:29.149+00:00
    ${redfish_event_date_time}=  Set Variable  ${event_data[0]["Created"].split('T')}

    Page Should Contain  ${redfish_event_date_time[0]}
    Page Should Contain  ${redfish_event_date_time[1].split('.')[0]}


Verify Displayed Event Details With Redfish
    [Documentation]  Verify event details like severity, desc etc using Redfish.
    [Tags]  Verify_Displayed_Event_Details_With_Redfish
    [Setup]  Run Keywords  Redfish.Login  AND  Redfish Purge Event Log
    [Teardown]  Redfish.Logout

    Create Error Logs  ${1}
    # Added a delay for error log to appear on error log page.
    Sleep  5s
    ${event_data}=  Get Event Logs
    Page Should Contain  ${event_data[0]["Severity"]}
    Page Should Contain  ${event_data[0]["EntryType"]}
    Page Should Contain  ${event_data[0]["Message"]}


Verify Existence Of All Fields In Event Logs Page
    [Documentation]  Verify existence of all required fields in Event Logs page.
    [Tags]  Verify_Existence_Of_All_Fields_In_Event_Logs_Page
    [Template]  Page Should Contain

    #Expected parameters
    ID
    Severity
    Date
    Description
    Status


Verify Invalid Content Search Logs
    [Documentation]  Input invalid PEL ID in the search log  and verify error message.
    [Tags]  Verify_Invalid_Content_Search_Logs

    Input Text  ${xpath_event_search}  AG806993
    Page Should Contain  No items match the search query
    Click Button  ${xpath_clear_search}


Verify Resolving Single Error Log In GUI
    [Documentation]   Verify that error log can be resolved via GUI
    ...               and the resolution is reflected in Redfish.
    [Tags]  Verify_Resolving_Single_Error_Log_In_GUI
    [Setup]  Run Keywords  Redfish.Login  AND  Redfish Purge Event Log

    Create Error Logs  ${1}
    Refresh GUI

    # Mark single event log as resolved.
    Click Element At Coordinates  ${xpath_event_log_resolve}  0  0
    # Given the time to get the notification.
    Wait Until Page Contains  Successfully resolved 1 log  timeout=10
    Wait Until Page Does Not Contain Element  Success
    # Verify the Redfish response after event log mark as resolved.
    Get And Verify Status Of Resolved Field In Event Logs  ${True}


Verify Resolving Multiple Error Logs In GUI
    [Documentation]  Verify that error logs can be resolved via GUI
    ...               and the resolution is reflected in Redfish.
    [Tags]  Verify_Resolving_Multiple_Error_Logs_In_GUI
    [Setup]  Redfish Purge Event Log

    Create Error Logs  ${3}
    Refresh GUI

    Select All Events
    Click Element  ${xpath_event_logs_resolve}

    # Since we are selecting 'all events', 3+1 logs are resolved including informational.
    Wait Until Page Contains  Successfully resolved 4 logs.  timeout=10
    Wait Until Page Does Not Contain Element  Success
    # Verify the event logs status from Redfish after mark as resolved.
    Get And Verify Status Of Resolved Field In Event Logs  ${True}


Verify Default Value Of Resolved Field In Error Log
    [Documentation]   Verify that error log unresolved status from GUI
    [Tags]  Verify_Default_Value_Of_Resolved_Field_In_Error_Log

    Redfish Purge Event Log
    Create Error Logs  ${1}
    Refresh GUI

    # Verify default value of resolved field from GUI.
    Element Should Contain  ${xpath_event_log_data}  Unresolved


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Event Logs Page
    Redfish.Login
    Wait Until Element Is Not Visible   ${xpath_page_loading_progress_bar}  timeout=30

Suite Teardown Execution
    [Documentation]  Suite teardown tasks.

    Redfish.Logout
    Close Browser

Navigate To Event Logs Page
    [Documentation]  Navigate to the event logs page from main menu.

    Click Element  ${xpath_logs_menu}
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


Get And Verify Status Of Resolved Field In Event Logs
    [Documentation]  Get event log entry and verify resolved attribute value.
    [Arguments]  ${expected_resolved_status}

    # Description of argument(s):
    # expected_resolved_status    expected status of resolved field in error logs.

    ${elog_entry}=  Get Event Logs

    FOR  ${elog}  IN  @{elog_entry}
        Should Be Equal  ${elog["Resolved"]}   ${expected_resolved_status}
    END
