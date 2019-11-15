*** Settings ***

Documentation  Test Open BMC GUI server health under GUI Header.

Resource        ../../lib/resource.robot
Resource        ../../../lib/boot_utils.robot
Resource        ../../../lib/utils.robot
Resource        ../../../lib/openbmc_ffdc.robot
Resource        ../../../lib/state_manager.robot
Resource        ../../../lib/openbmc_ffdc_methods.robot
Resource        ../../../lib/dump_utils.robot
Resource        ../../../lib/logging_utils.robot
Library         ../../../lib/gen_robot_keyword.py

Test Setup      Test Setup Execution
Test Teardown   Test Teardown Execution

*** Variables ***

${xpath_delete_remote_server}  //*[@class="remote-logging-server"]//button[2]
${xpath_add_server}            //*[@class="remote-logging-server"]//button[1]
${xpath_remote_server_ip}      //input[@id="remoteServerIP"]
${xpath_remote_server_port}    //input[@id="remoteServerPort"]

*** Test Cases ***

Verify Event Log Text Appears By Clicking Server Health
    [Documentation]  Check that "Event Log" text appears by clicking server
    ...  health in GUI header.
    [Tags]  Verify_Event_Log_Text_Appears_By_Clicking_Server_Health

    Wait Until Page Contains Element  event-log
    Page should contain  Event log


Verify Filters By Severity Elements Appears
    [Documentation]  Check that the "event log" filters appears by clicking
    ...  server health in GUI header.
    [Tags]  Verify_Filters_By_Severity_Elements_Appears

    # Types of event severity: All, High, Medium, Low.
    Page Should Contain Element  ${xpath_event_severity_all}  limit=1
    Page Should Contain Element  ${xpath_event_severity_high}  limit=1
    Page Should Contain Element  ${xpath_event_severity_medium}  limit=1
    Page Should Contain Element  ${xpath_event_severity_low}  limit=1


Verify Drop Down Button User Timezone Appears
    [Documentation]  Check that the "drop down" button of user timezone appears
    ...  by clicking server health in GUI header.
    [Tags]  Verify_Drop_Down_Button_User_Timezone_Appears

    Page Should Contain Button  ${xpath_drop_down_timezone_edt}
    # Ensure that page is not in refreshing state.
    # It helps to click the drop down element.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  //*[@class='dropdown__button']
    Page Should Contain Button  ${xpath_drop_down_timezone_utc}


Verify Content Search Element Appears
    [Documentation]  Check that the "event search element is available with
    ...  filter" button appears.
    [Tags]  Verify_Content_Search_Element_Appears

    Page Should Contain Element  content__search-input  limit=1
    # Ensure that page is not in refreshing state.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Button  content__search-submit


Verify Filter By Date Element Appears
    [Documentation]  Check that the "filter by date" elements are available and
    ...  visible.
    [Tags]  Verify_Filter_By_Date_Element_Appears

    Wait Until Element Is Visible  event-filter-start-date
    Page Should Contain Element  event-filter-start-date  limit=1
    Page Should Contain Element  event-filter-end-date  limit=1


Verify Filter By Event Status Element Appears
    [Documentation]  Check that the "filter by event status" element appears.
    [Tags]  Verify_Filter_By_Event_Status_Element_Appears

    # Ensure that page is not in refreshing state.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Wait Until Element is Visible  //*[@class='dropdown__wrapper']
    Click Element  //*[@class='dropdown__wrapper']
    Page Should Contain Element  ${xpath_event_filter_all}  limit=2
    Page Should Contain Element  ${xpath_event_filter_resolved}  limit=1
    Page Should Contain Element  ${xpath_event_filter_unresolved}  limit=1


Verify Event Action Bar Element Appears
    [Documentation]  Check that "event action bar" element appears.
    [Tags]  Verify_Event_Action_Bar_Element_Appears

    # Ensure that page is not in refreshing state.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_event_action_bars}  limit=1
    Page Should Contain Element  ${xpath_select_all_events}


Verify Click Events Check Box
    [Documentation]  Check that "event check box" element appears and on click
    ...  should be able to see elements like "Delete" button and "Export"
    ...  element.
    [Tags]  Verify_Click_Events_Check_Box

    Create Test Error Log
    Click Element  ${xpath_select_refresh_button}
    # Ensure that page is not in refreshing state.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Click Element  ${xpath_select_all_events}
    Page Should Contain Button  ${xpath_event_action_delete}  limit=1
    Page Should Contain Element  ${xpath_event_action_export}  limit=1


Verify Number of Events Appears
    [Documentation]  Check that "number of events" element appears and value is
    ...  visible.
    [Tags]  Verify_Number_of_Events_Appears

    # Ensure that page is not in refreshing state.
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Log To Console  \n Number of Events:${number_of_events}


Select All Error Logs And Mark As Resolved
    [Documentation]  Select all error logs and mark them as resolved.
    [Tags]  Select_All_Error_Logs_And_Mark_As_Resolved

    Create Test Error Log
    Create Test Error Log
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Click Element  ${xpath_select_all_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Click Element  ${xpath_mark_as_resolved}
    Element Should Be Disabled  ${xpath_mark_as_resolved}


Select All Error Logs And Click Export
    [Documentation]  Select all error logs and click export element.
    [Tags]  Select_All_Error_Logs_And_Click_Export

    Create Test Error Log
    Create Test Error Log
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Click Element  ${xpath_select_all_events}
    Page Should Contain Element  ${xpath_events_export}
    Run Keyword If  ${number_of_events} > 0
    ...  Click Element  ${xpath_events_export}


Select All Error Logs And Delete
    [Documentation]  Select all error logs and delete them.
    [Tags]  Select_All_Error_Logs_And_Delete

    Create Test Error Log
    Create Test Error Log
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Common Event Log Click Element  ${xpath_individual_event_delete}
    ...  ${xpath_yes_button}  ${xpath_select_all_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  0


Select Single Error Log And Delete
    [Documentation]  Select single error log and delete it.
    [Tags]  Select_Single_Error_Log_And_Delete

    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Common Event Log Click Element  ${xpath_individual_event_delete}
    ...  ${xpath_yes_button}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  0
    ...  msg=Failed to delete single error log entry.


Select Multiple Error Logs And Delete
    [Documentation]  Select multiple error logs and delete them.
    [Tags]  Select_Multiple_Error_Logs_And_Delete

    Create Test Error Log
    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Double Event Log Click Element  ${xpath_individual_event_delete}
    ...  ${xpath_yes_button}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  0
    ...  msg=Failed to delete multiple error log entries.


Select Single Error Log And Mark As Resolved
    [Documentation]  Select single error log and mark as resolved.
    [Tags]  Select_Single_Error_Log_And_Mark_As_Resolved

    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Common Event Log Click Element  ${xpath_individual_event_resolved}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  1
    ...  msg=Failed to mark single error log entry as resolved.


Select Multiple Error Logs And Mark As Resolved
    [Documentation]  Select multiple error logs and mark as resolved.
    [Tags]  Select_Multiple_Error_Logs_And_Mark_As_Resolved

    Create Test Error Log
    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Double Event Log Click Element  ${xpath_individual_event_resolved}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  2
    ...  msg=Failed to mark multiple error log entries as resolved.


Select Single Error Log And Export
    [Documentation]  Select single error log and export.
    [Tags]  Select_Single_Error_Log_And_Export

    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Common Event Log Click Element  ${xpath_individual_event_export}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  1
    ...  msg=Failed to export single error log entry.


Select Multiple Error Log And Export
    [Documentation]  Select multiple error log and export.
    [Tags]  Select_Multiple_Error_Log_And_Export

    Create Test Error Log
    Create Test Error Log
    # Refresh the GUI to get the latest update.
    Click Element  ${xpath_select_refresh_button}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Page Should Contain Element  ${xpath_number_of_events}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Run Keyword If  ${number_of_events} > 0
    ...  Double Event Log Click Element  ${xpath_individual_event_export}
    ${number_of_events}=  Get Text  ${xpath_number_of_events}
    Should Be Equal  ${number_of_events}  2
    ...  msg=Failed to export multiple error log entries.


Verify Existence Of All Buttons In Remote Logging Server Page
    [Documentation]  Verify existence of all buttons in remote logging server
    ...              page.
    [Tags]  Verify_Existence_Of_All_Buttons_In_Remote_Logging_Server_Page
    [Setup]  Setup For Remote Logging Server
    [Teardown]  Teardown For Remote Logging Server

    Page Should Contain Button  ${xpath_cancel_button}
    Page Should Contain Button  ${xpath_add_button}


Verify Existence Of All Input Boxes In Remote Logging Server Page
    [Documentation]  Verify existence of all input boxes in remote logging server
    ...              page.
    [Tags]  Verify_Existence_Of_All_Input_Boxes_In_Remote_Logging_Server_Page
    [Setup]  Setup For Remote Logging Server
    [Teardown]  Teardown For Remote Logging Server

    Page Should Contain Textfield  ${xpath_remote_server_ip}
    Page Should Contain Textfield  ${xpath_remote_server_port}

*** Keywords ***

Common Event Log Click Element
   [Documentation]  Keep common click elements associated with event log.
   [Arguments]  ${action_element}  ${action_click_confirmation}=${None}
   ...  ${xpath_event_select}=${xpath_individual_event_select}

    # Description of argument(s):
    # action_element             xpath value of the element to be actioned
    #                            (e.g. "Delete" or "Resolved" or "Export").
    # action_click_confirmation  Confirmation of action by pressing yes
    #                            (e.g.  "Yes" or "No").
    # xpath_event_select         xpath to select event log.

    Click Element  ${xpath_event_select}
    Page Should Contain Element  ${action_element}
    Click Element  ${action_element}
    Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
    Run Keyword If  "${action_click_confirmation}" != "${None}"
    ...  Click Element  ${action_click_confirmation}
    Click Element  ${xpath_select_refresh_button}
    Run Key  Sleep \ 50s

Double Event Log Click Element
   [Documentation]  Keep double click elements associated with event logs.
   [Arguments]  ${action_element}  ${action_click_confirmation}=${None}

    # Description of argument(s):
    # action_element             xpath value of the element to be actioned
    #                            (e.g. "Delete" or "Resolved" or "Export").
    # action_click_confirmation  Confirmation of action by pressing yes
    #                            (e.g.  "Yes" or "No").

   Click Element  ${xpath_second_event_select}
   Common Event Log Click Element  ${action_element}
   ...  ${action_click_confirmation}

Navigate To Event Log Page
   [Documentation]  Go to event log page from BMC homepage.

   Launch Browser And Login OpenBMC GUI
   Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
   Click Element  ${xpath_select_server_health}
   Wait Until Page Does Not Contain Element  ${xpath_refresh_circle}
   Wait Until Page Contains  Event Log

Test Setup Execution
   [Documentation]  Do test case setup tasks.

   ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
   Run Keyword If  ${status} == ${False}  Install Tarball
   Delete Error Logs And Verify

   Navigate To Event Log Page

Test Teardown Execution
   [Documentation]  Do the post test teardown.

   FFDC On Test Case Fail
   Delete All Error Logs
   Close All Connections
   Close Browser

Delete Remote Logging Server
   [Documentation]  Delete remote logging server entry.

   Click Button  ${xpath_delete_remote_server}
   Click Button  ${xpath_remove_button}

Setup For Remote Logging Server
   [Documentation]  Test setup for remote logging server page.

   Navigate To Event Log Page

   # An entry for remote server may not exist so ignoring if there is a fail
   # when deleting the entry.
   Run Keyword And Ignore Error  Delete Remote Logging Server
   Click Button  ${xpath_add_server}
   Page Should Contain  Add remote logging server

Teardown For Remote Logging Server
   [Documentation]  Test teardown for remote logging server page.

   Click Button  ${xpath_cancel_button}
   FFDC On Test Case Fail
   Close Browser
