*** Settings ***

Documentation  Test OpenBMC GUI "Event logs" sub-menu of "Logs" menu.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/logging_utils.robot
Variables       ../../../data/pel_variables.py

Suite Setup     Suite Setup Execution
Suite Teardown  Suite Teardown Execution

Test Tags       Event_Logs_Sub_Menu

*** Variables ***

${generate_error_logs_count}      3
${xpath_event_logs_heading}       //h1[text()="Event logs"]
${xpath_filter_event}             //button[contains(normalize-space(.),"Filter")]
${xpath_event_severity_ok}        //*[@data-test-id="tableFilter-checkbox-OK"]
${xpath_event_severity_warning}   //*[@data-test-id="tableFilter-checkbox-Warning"]
${xpath_event_severity_critical}  //*[@data-test-id="tableFilter-checkbox-Critical"]
${xpath_event_from_date}          (//input[@class='dp-input'])[1]
${xpath_event_to_date}            (//input[@class='dp-input'])[2]
${xpath_select_all_events}        //*[@data-test-id="eventLogs-checkbox-selectAll"]
${xpath_event_action_delete}      //*[@data-test-id="table-button-deleteSelected"]
${xpath_event_action_export}      //*[contains(text(),"Export")]
${xpath_event_action_cancel}      //button[contains(normalize-space(.),"Cancel")]
${xpath_delete_first_row}         //*[@data-test-id="eventLogs-button-deleteRow-0"][2]
${xpath_confirm_delete}           //button[text()="Delete"]
${xpath_event_status_resolved}    //*[@data-test-id="tableFilter-checkbox-Resolved"]
${xpath_event_status_unresolved}  //*[@data-test-id="tableFilter-checkbox-Unresolved"]
${xpath_event_action_download}    //button[text()[normalize-space()='Download']]
${xpath_success_message}          //*[contains(text(),"Success")]
${xpath_resolved_button}          //button[contains(normalize-space(.),"Resolve")]
${xpath_unresolved_button}        //button[contains(normalize-space(.),"Unresolve")]
${xpath_filter_clearall_button}   //button[contains(normalize-space(.),"Clear all")]
${xpath_clear_search}             //button[@title="Clear search input"]
${xpath_event_log_resolve}        //*[@name="switch"]
${xpath_event_logs_resolve}       //button[contains(normalize-space(.),'Resolve')]
${xpath_event_log_data}           //td[contains(normalize-space(.)),'Critical']/following-sibling::td[3]
${view_page_button}               //*[@id='pagination-items-per-page']
${page_selection}                 //select[@id="pagination-items-per-page"]
${log_table_popup}                //*[@class='toolbar-content']


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

    Redfish Purge Event Log
    Create Error Logs  ${2}
    Wait Until Element Is Visible  ${xpath_delete_first_row}
    Select All Events
    Page Should Contain Element  ${xpath_resolved_button}
    Page Should Contain Element  ${xpath_unresolved_button}
    Page Should Contain Element  ${xpath_event_action_download}
    Page Should Contain Element  ${xpath_event_action_delete}
    Page Should Contain Element  ${xpath_event_action_cancel}
    Redfish Purge Event Log


Select And Verify Default UTC Timezone For Events
    [Documentation]  Select and verify that default UTC timezone is displayed for an event.
    [Tags]  Select_And_Verify_Default_UTC_Timezone_For_Events
    [Setup]  Run Keywords  Redfish.Login  AND  Redfish Purge Event Log
    [Teardown]  Redfish.Logout

    Create Error Logs  ${1}

    # Set Default timezone in profile settings page.
    Set Timezone In Profile Settings Page  Default
    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_event_logs_sub_menu}  event-logs

    # Get date and time from backend.
    ${event_data}=  Get Event Logs
    # Date format: 2023-05-02T04:49:29.149+00:00
    VAR  ${redfish_event_date_time}  ${event_data[0]["Created"].split('T')}

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

    # Expected parameters.
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


Verify Valid Content Search Logs
    [Documentation]  Input valid PEL ID in the search log and verify the results.
    [Tags]  Verify_Valid_Content_Search_Logs
    [Setup]  Redfish Purge Event Log

    # Delete the clear log entry, so that we can create a new singleerror log and verify.
    Click Element  ${xpath_delete_first_row}
    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}

    BMC Execute Command  ${CMD_INFORMATIONAL_ERROR}
    Refresh GUI
    Input Text  ${xpath_event_search}  TestError2
    Page Should Not Contain  No items match the search query
    Click Button  ${xpath_clear_search}


Verify Resolving Single Error Log In GUI
    [Documentation]   Verify that error log can be resolved via GUI
    ...               and the resolution is reflected in Redfish.
    [Tags]  Verify_Resolving_Single_Error_Log_In_GUI
    [Setup]  Redfish Purge Event Log

    # Delete the clear log entry, so that we can create a new singleerror log and verify.
    Click Element  ${xpath_delete_first_row}
    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}

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
    Sleep  5s
    Select All Events
    Sleep  5s
    Click Element  ${xpath_event_logs_resolve}

    # Since we are selecting 'all events', 3+1 logs are resolved including informational.
    Wait Until Page Contains  Successfully resolved 4 logs.  timeout=10
    Wait Until Page Does Not Contain Element  Success
    # Verify the event logs status from Redfish after mark as resolved.
    Get And Verify Status Of Resolved Field In Event Logs  ${True}


Verify Resolving And Unresolving Multiple Error Logs In GUI
    [Documentation]   Verify that error log can be resolved and unresolved via GUI
    ...               and the resolution is reflected in Redfish.
    [Tags]  Verify_Resolving_And_Unresolving_Multiple_Error_Logs_In_GUI
    [Setup]  Redfish Purge Event Log

    FOR  ${num}  IN RANGE  ${generate_error_logs_count}
        BMC Execute Command  ${CMD_INFORMATIONAL_ERROR}
    END
    Refresh GUI

    ${number_of_events}=  Get Number Of Event Logs

    Select All Events

    Wait Until Page Contains Element  ${xpath_event_logs_resolve}
    Click Element  ${xpath_event_logs_resolve}

    Wait Until Page Contains  Successfully resolved ${number_of_events} logs.  timeout=10

    ${number_of_events_before}=  Get Number Of Event Logs

    # Check the pop up message to ensure they are resolved.
    #Wait Until Page Contains  Successfully resolved ${number_of_events_before} logs.  timeout=10
    Wait Until Page Does Not Contain Element  Success

    # Verify the event logs status from Redfish after mark as resolved.
    Get And Verify Status Of Resolved Field In Event Logs  ${True}

    # Change the events to unresolved state.
    Click Element  ${xpath_unresolved_button}

    # Check the pop up message to ensure they are unresolved.
    Wait Until Page Contains  Successfully unresolved ${number_of_events} logs.  timeout=10
    Get And Verify Status Of Resolved Field In Event Logs  ${False}


Verify Default Value Of Resolved Field In Error Log
    [Documentation]   Verify that error log unresolved status from GUI
    [Tags]  Verify_Default_Value_Of_Resolved_Field_In_Error_Log

    Redfish Purge Event Log
    Create Error Logs  ${1}
    Refresh GUI

    # Verify default value of resolved field from GUI.
    Page Should Contain  Unresolved


Verify Error And Unauthorized Message Display When ReadOnly User Deletes Error Log
    [Documentation]  Verify error and unauthorized message displayed when a
    ...  readonly user deletes single error log.
    [Tags]  Verify_Error_And_Unauthorized_Message_Display_When_ReadOnly_User_Deletes_Error_Log
    [Setup]  Create Readonly User And Login To GUI
    [Teardown]  Run Keywords  Redfish Purge Event Log  AND
    ...  Delete Readonly User And Logout Current GUI Session

    # Clear error logs and navigate event-logs menu.
    Redfish Purge Event Log
    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_event_logs_sub_menu}  event-logs

    # Create new error log.
    Create Error Logs  ${2}
    ${number_of_events_before}=  Get Number Of Event Logs

    # Delete single error log and verify error and unauthorized message.
    Click Element  ${xpath_delete_first_row}
    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}
    Verify Error And Unauthorized Message On GUI

    # Make sure the count of error log remains same.
    ${number_of_events_after}=  Get Number Of Event Logs
    Should Be Equal  ${number_of_events_before}  ${number_of_events_after}
    ...  msg=Failed as readonly user was able to delete error log.


Verify Error And Unauthorized Message Display When ReadOnly User Resolving Single Error Log
    [Documentation]  Verify error and unauthorized message displayed when a
    ...  readonly user resolves single error log.
    [Tags]  Verify_Error_And_Unauthorized_Message_Display_When_ReadOnly_User_Resolving_Single_Error_Log
    [Setup]  Create Readonly User And Login To GUI
    [Teardown]  Run Keywords  Redfish Purge Event Log  AND
    ...  Delete Readonly User And Logout Current GUI Session

    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_event_logs_sub_menu}  event-logs
    Create Error Logs  ${1}
    Refresh GUI

    # Mark single event log as resolved.
    Click Element At Coordinates  ${xpath_event_log_resolve}  0  0
    Verify Error And Unauthorized Message On GUI


Verify Event Log Entries Match Between GUI And Redfish API
    [Documentation]  Verify view all logs in event Logs Page and verify the webui entries are same as the redfish api entries.
    [Tags]  Verify_Event_Log_Entries_Match_Between_GUI_And_Redfish_API
    [Setup]  Run Keywords  Redfish Purge Event Log  AND  Refresh GUI

    # Wait until the "clear log" entry is visible before attempting deletion.
    Wait Until Element Is Visible  ${xpath_delete_first_row}  timeout=15

    # Delete the clear log entry, so that we can clear a new single error log and verify.
    Click Element  ${xpath_delete_first_row}

    Wait Until Page Contains Element  ${xpath_confirm_delete}
    Click Button  ${xpath_confirm_delete}

    # Wait for deletion to complete before proceeding.
    Wait Until Element Is Not Visible  ${xpath_confirm_delete}  timeout=10

    ${create_error_logs_for_viewall}=    Evaluate    random.randint(41, 50)    modules=random

    FOR  ${num}  IN RANGE  ${create_error_logs_for_viewall}
        BMC Execute Command  ${CMD_INFORMATIONAL_ERROR}
    END
    Refresh GUI

    # Click item per page dropdown and select view all option.
    Click Element  ${view_page_button}

    # Select view all option from the dropdown.
    Select From List By Label  ${page_selection}  view all
    Sleep  5s

    Select All Events

    # Wait until the event logs table popup is displayed.
    Wait Until Page Contains Element  ${log_table_popup}

    # Get the selected count text from the toolbar.
    ${selected_count_text}=  Get Text  ${log_table_popup}

    # Extract the selected error count from the text.
    ${selected_logs}=  Fetch From Left  ${selected_count_text}  ${SPACE}
    ${selected_logs}=  Convert To Integer  ${selected_logs}

    # Get the total number of event log entries from Redfish API.
    ${members}=  Redfish.Get Attribute  ${EVENT_LOG_URI}Entries  Members@odata.count

    # Verify the selected error count is equal to the total redfish api error logs.
    Should Be Equal As Integers  ${selected_logs}  ${members}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Launch Browser And Login GUI
    Navigate To Required Sub Menu  ${xpath_logs_menu}  ${xpath_event_logs_sub_menu}  event-logs
    Redfish.Login


Suite Teardown Execution
    [Documentation]  Suite teardown tasks.

    Redfish Purge Event Log
    Redfish.Logout
    Close Browser


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
