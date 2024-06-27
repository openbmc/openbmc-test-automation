*** Settings ***
Documentation       Inventory of hardware resources under systems.

Resource            ../../../lib/bmc_redfish_resource.robot
Resource            ../../../lib/bmc_redfish_utils.robot
Resource            ../../../lib/logging_utils.robot
Resource            ../../../lib/openbmc_ffdc.robot
Resource            ../../../lib/ipmi_client.robot
Library             ../../../lib/logging_utils.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Test Setup Execution
Test Teardown       Test Teardown Execution

Test Tags           event_logging


*** Variables ***
${max_num_event_logs}       ${200}


*** Test Cases ***
Event Log Check After BMC Reboot
    [Documentation]    Check event log after BMC rebooted.
    [Tags]    event_log_check_after_bmc_reboot

    Redfish Purge Event Log
    Event Log Should Not Exist

    Redfish OBMC Reboot (off)

    Redfish.Login
    Wait Until Keyword Succeeds    1 mins    15 secs    Redfish.Get    ${EVENT_LOG_URI}Entries

    Event Log Should Not Exist

Event Log Check After Host Poweron
    [Documentation]    Check event log after host has booted.
    [Tags]    event_log_check_after_host_poweron

    Redfish Purge Event Log
    Event Log Should Not Exist

    Redfish Power On

    Redfish.Login
    Event Log Should Not Exist

Create Test Event Log And Verify
    [Documentation]    Create event logs and verify via redfish.
    [Tags]    create_test_event_log_and_verify

    Create Test Error Log
    Event Log Should Exist

Delete Redfish Event Log And Verify
    [Documentation]    Delete Redfish event log and verify via Redfish.
    [Tags]    delete_redfish_event_log_and_verify

    Redfish.Login
    Redfish Purge Event Log
    Create Test PEL Log
    ${elog_entry}=    Get Event Logs

    Redfish.Delete    /redfish/v1/Systems/${SYSTEM_ID}/LogServices/EventLog/Entries/${elog_entry[0]["Id"]}

    ${error_entries}=    Get Redfish Error Entries
    Should Be Empty    ${error_entries}

Test Event Log Persistency On Restart
    [Documentation]    Restart logging service and verify event logs.
    [Tags]    test_event_log_persistency_on_restart

    Create Test Error Log
    Event Log Should Exist

    BMC Execute Command
    ...    systemctl restart xyz.openbmc_project.Logging.service
    Sleep    10s    reason=Wait for logging service to restart properly.

    Event Log Should Exist

Test Event Entry Numbering Reset On Restart
    [Documentation]    Restart logging service and verify event logs entry starts
    ...    from entry "Id" 1.
    [Tags]    test_event_entry_numbering_reset_on_restart
    [Setup]    Redfish Power Off    stack_mode=skip

    # {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntryCollection.LogEntryCollection",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries",
    #    "@odata.type": "#LogEntryCollection.LogEntryCollection",
    #    "Description": "Collection of System Event Log Entries",
    #    "Members": [
    #    {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntry.LogEntry",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/1",
    #    "@odata.type": "#LogEntry.v1_4_0.LogEntry",
    #    "Created": "2019-05-29T13:19:27+00:00",
    #    "EntryType": "Event",
    #    "Id": "1",    <----- Event log ID
    #    "Message": "org.open_power.Host.Error.Event",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    #    }
    #    ],
    #    "Members@odata.count": 1,
    #    "Name": "System Event Log Entries"
    # }

    Create Test PEL Log
    Create Test PEL Log
    Event Log Should Exist

    Redfish Purge Event Log
    Event Log Should Not Exist

    BMC Execute Command
    ...    systemctl restart xyz.openbmc_project.Logging.service
    Sleep    10s    reason=Wait for logging service to restart properly.

    Create Test PEL Log
    ${elogs}=    Get Event Logs

    # After issuing Redfish purge event log, there will be one informational error log
    # in BMC with ID 1. Due to this the newly generated error log would have ID as 2.
    Should Be Equal    ${elogs[0]["Id"]}    2    msg=Event log entry is not 2

Test Event Log Persistency On Reboot
    [Documentation]    Reboot BMC and verify event log.
    [Tags]    test_event_log_persistency_on_reboot

    Redfish Purge Event Log
    Create Test Error Log
    Event Log Should Exist

    Redfish OBMC Reboot (off)

    Redfish.Login
    Wait Until Keyword Succeeds    1 mins    15 secs    Redfish.Get    ${EVENT_LOG_URI}Entries

    Event Log Should Exist

Create Test Event Log And Verify Time Stamp
    [Documentation]    Create event logs and verify time stamp.
    [Tags]    create_test_event_log_and_verify_time_stamp

    # {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntryCollection.LogEntryCollection",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries",
    #    "@odata.type": "#LogEntryCollection.LogEntryCollection",
    #    "Description": "Collection of System Event Log Entries",
    #    "Members": [
    #    {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntry.LogEntry",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/1",
    #    "@odata.type": "#LogEntry.v1_4_0.LogEntry",
    #    "Created": "2023-05-10T10:26:02.186+00:00", <--- Time stamp
    #    "EntryType": "Event",
    #    "Id": "1",
    #    "Message": "org.open_power.Host.Error.Event",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    #    }
    #    ],
    #    "Members@odata.count": 1,
    #    "Name": "System Event Log Entries"
    # }

    Redfish Purge Event Log

    Create Test Error Log
    Sleep    2s
    Create Test Error Log

    ${elog_entry}=    Get Event Logs

    # The event log generated is associated with the epoc time and unique
    # for every error and in increasing time stamp.
    ${time_stamp1}=    Convert Date    ${elog_entry[0]["Created"].split('.')[0]}    epoch
    ${time_stamp2}=    Convert Date    ${elog_entry[1]["Created"].split('.')[0]}    epoch

    Should Be True    ${time_stamp2} > ${time_stamp1}

# TODO: openbmc/openbmc-test-automation#1789

Verify Setting Error Log As Resolved
    [Documentation]    Verify modified field of error log is updated when error log is marked resolved.
    [Tags]    verify_setting_error_log_as_resolved

    Create Test PEL Log
    ${elog_entry}=    Get Event Logs

    # Wait for 5 seconds after creating error log.
    Sleep    5s

    # Mark error log as resolved by setting it to true.
    Redfish.Patch    ${EVENT_LOG_URI}Entries/${elog_entry[0]["Id"]}    body={'Resolved':True}

    ${elog_entry}=    Get Event Logs

    # Example error log with resolve field set to true:
    # {
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/2045",
    #    "@odata.type": "#LogEntry.v1_8_0.LogEntry",
    #    "AdditionalDataURI": "/redfish/v1/Systems/system/LogServices/EventLog/attachment/2045",
    #    "Created": "2023-05-10T10:26:02.186+00:00",
    #    "EntryType": "Event",
    #    "Id": "2045",
    #    "Message": "xyz.openbmc_project.Host.Error.Event",
    #    "Modified": "2023-05-10T10:26:02.186+00:00",
    #    "Name": "System Event Log Entry",
    #    "Resolved": true,
    #    "Severity": "OK"
    # }

    Should Be Equal As Strings    ${elog_entry[0]["Resolved"]}    True

    # Difference created and modified time of error log should be around 5 seconds.
    ${creation_time}=    Convert Date    ${elog_entry[0]["Created"].split('.')[0]}    epoch
    ${modification_time}=    Convert Date    ${elog_entry[0]["Modified"].split('.')[0]}    epoch

    ${diff}=    Subtract Date From Date    ${modification_time}    ${creation_time}
    ${diff}=    Convert To Number    ${diff}
    Should Be True    4 < ${diff} < 8

Verify IPMI SEL Delete
    [Documentation]    Verify IPMI SEL delete operation.
    [Tags]    verify_ipmi_sel_delete

    Redfish Purge Event Log
    Create Test Error Log

    ${sel_list}=    Run IPMI Standard Command    sel list
    Should Not Be Equal As Strings    ${sel_list}    SEL has no entries

    # Example of SEL List:
    # 4 | 04/21/2017 | 10:51:16 | System Event #0x01 | Undetermined system hardware failure | Asserted

    ${sel_entry}=    Fetch from Left    ${sel_list}    |
    ${sel_entry}=    Evaluate    $sel_entry.replace(' ','')
    ${sel_entry}=    Convert To Integer    0x${sel_entry}

    ${sel_delete}=    Run IPMI Standard Command    sel delete ${sel_entry}
    Should Be Equal As Strings    ${sel_delete}    Deleted entry ${sel_entry}
    ...    case_insensitive=True

    ${sel_list}=    Run IPMI Standard Command    sel list
    Should Be Equal As Strings    ${sel_list}    SEL has no entries
    ...    case_insensitive=True

Create Test Event Log And Delete
    [Documentation]    Create an event log and delete it.
    [Tags]    create_test_event_log_and_delete

    Create Test Error Log
    Redfish Purge Event Log
    Event Log Should Not Exist

Create Multiple Test Event Logs And Delete All
    [Documentation]    Create multiple event logs and delete all.
    [Tags]    create_multiple_test_event_logs_and_delete_all

    Create Test Error Log
    Create Test Error Log
    Create Test Error Log
    Redfish Purge Event Log
    Event Log Should Not Exist

Create Two Test Event Logs And Delete One
    [Documentation]    Create two event logs and delete the first entry.
    [Tags]    create_two_test_event_logs_and_delete_one
    [Setup]    Redfish Power Off    stack_mode=skip

    Redfish Purge Event Log
    Create Test PEL Log
    Create Test PEL Log
    ${error_entries_before}=    Get Redfish Error Entries
    Redfish.Delete    /redfish/v1/Systems/${SYSTEM_ID}/LogServices/EventLog/Entries/${error_entries_before[0]}

    ${error_entries_after}=    Get Redfish Error Entries
    Should Not Contain    ${error_entries_after}    ${error_entries_before[0]}
    Should Contain    ${error_entries_after}    ${error_entries_before[1]}

Verify Watchdog Timedout Event
    [Documentation]    Trigger watchdog timed out and verify event log generated.
    [Tags]    verify_watchdog_timedout_event

    Redfish Power Off    stack_mode=skip

    # Clear errors if there are any.
    Redfish.Login
    Redfish Purge Event Log

    # Reference: [Old legacy REST code] Trigger Host Watchdog Error
    # Currently, no known redfish interface to set to trigger watchdog timer.

    Redfish Initiate Auto Reboot    1000

    # Logging takes time to generate the timeout error.
    Wait Until Keyword Succeeds    3 min    20 sec    Verify Watchdog EventLog Content
    [Teardown]    Run Keywords    Test Teardown Execution    AND    Redfish Power Off    stack_mode=skip

Verify Event Logs Capping
    [Documentation]    Verify event logs capping.
    [Tags]    verify_event_logs_capping

    Redfish Purge Event Log

    ${cmd}=    Catenate    uptime; for i in {1..201}; do /tmp/tarball/bin/logging-test -c
    ...    AutoTestSimple;sleep 1;done; uptime
    BMC Execute Command    ${cmd}

    ${elogs}=    Get Event Logs
    ${count}=    Get Length    ${elogs}
    IF    ${count} > 200
        Fail    Error logs created exceeded max capacity 200.
    END

Test Event Log Wrapping
    [Documentation]    Verify event log entries wraps when 200 max cap is reached.
    [Tags]    test_event_log_wrapping

    # Restarting logging service in order to clear logs and get the next log
    # ID set to 1.
    BMC Execute Command
    ...    systemctl restart xyz.openbmc_project.Logging.service
    Sleep    10s    reason=Wait for logging service to restart properly.

    # Create ${max_num_event_logs} event logs.
    ${cmd}=    Catenate    uptime; for i in {1..${max_num_event_logs}}; do /tmp/tarball/bin/logging-test -c
    ...    AutoTestSimple;sleep 1;done; uptime
    BMC Execute Command    ${cmd}

    # Verify that event logs with IDs 1 and ${max_num_event_logs} exist.
    ${event_log}=    Get Event Logs

    ${log_entries}=    Filter Struct    ${event_log}    [('Id', '1')]
    Rprint Vars    log_entries
    Should Be Equal As Strings    ${log_entries[0]["Id"]}    1

    ${log_entries}=    Filter Struct    ${event_log}    [('Id', '${max_num_event_logs}')]
    Rprint Vars    log_entries
    Should Be Equal As Strings    ${log_entries[0]["Id"]}    ${max_num_event_logs}

    # Create event log and verify the entry ID, ${max_num_event_logs + 1}.
    ${next_event_log_id}=    Set Variable    ${max_num_event_logs + 1}

    Create Test Error Log

    ${event_log}=    Get Event Logs

    ${log_entries}=    Filter Struct    ${event_log}    [('Id', '${next_event_log_id}')]
    Rprint Vars    log_entries
    Should Be Equal As Strings    ${log_entries[0]["Id"]}    ${next_event_log_id}

    # Event log 1 should be wrapped.
    ${log_entries}=    Filter Struct    ${event_log}    [('Id', '1')]
    Rprint Vars    log_entries

    ${length_log_entries}=    Get Length    ${log_entries}
    Should Be Equal As Integers    ${length_log_entries}    0
    ...    msg=The event log should have wrapped such that entry ID 1 is now purged.

Verify Default Value Of Resolved Field Is False For An Error Log Via Redfish
    [Documentation]    Verify the Resolve field status is false for an error log from Redfish.
    [Tags]    verify_default_value_of_resolved_field_is_false_for_an_error_log_via_redfish

    Redfish Purge Event Log
    Create Test Error Log

    # Check resolve field value of created error log.
    ${elog_entry}=    Get Event Logs
    Should Be Equal    ${elog_entry[0]["Resolved"]}    ${False}


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do test case setup tasks.

    Redfish.Login

    Redfish Purge Event Log

    ${status}=    Run Keyword And Return Status    Logging Test Binary Exist
    IF    ${status} == ${False}    Install Tarball

Suite Teardown Execution
    [Documentation]    Do the post suite teardown.

    Redfish.Logout

Test Setup Execution
    [Documentation]    Do test case setup tasks.

    Redfish Purge Event Log

    ${status}=    Run Keyword And Return Status    Logging Test Binary Exist
    IF    ${status} == ${False}    Install Tarball

Test Teardown Execution
    [Documentation]    Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Login
    Redfish Purge Event Log

Get Redfish Error Entries
    [Documentation]    Return Redfish error ids list.
    ${error_uris}=    redfish_utils.get_member_list    /redfish/v1/Systems/${SYSTEM_ID}/LogServices/EventLog/Entries
    ${error_ids}=    Create List

    FOR    ${error_uri}    IN    @{error_uris}
        ${error_id}=    Fetch From Right    ${error_uri}    /
        Append To List    ${error_ids}    ${error_id}
    END

    RETURN    ${error_ids}

Event Log Should Not Exist
    [Documentation]    Event log entries should not exist.

    ${elogs}=    Get Event Logs
    Should Be Empty    ${elogs}    msg=System event log entry is not empty.

Event Log Should Exist
    [Documentation]    Event log entries should exist.

    ${elogs}=    Get Event Logs
    Should Not Be Empty    ${elogs}    msg=System event log entry is not empty.

Verify Watchdog EventLog Content
    [Documentation]    Verify watchdog event log content.

    # Example:
    # {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntry.LogEntry",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/31",
    #    "@odata.type": "#LogEntry.v1_4_0.LogEntry",
    #    "Created": "2019-05-31T18:41:33+00:00",
    #    "EntryType": "Event",
    #    "Id": "31",
    #    "Message": "org.open_power.Host.Boot.Error.WatchdogTimedOut",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    # }

    ${elog_list}=    Get Event Logs

    Rprint Vars    elog_list

    FOR    ${entry}    IN    @{elog_list}
        ${found_match}=    Run Keyword And Return Status    Is Watchdog Error Found    ${entry}
        IF    '${found_match}' == 'True'    BREAK
    END

    IF    '${found_match}' == 'False'    Fail    msg=No watchdog error logged.

Is Watchdog Error Found
    [Documentation]    Check if the give log entry matches specific watchdog error.
    [Arguments]    ${elog}

    # Description of argument(s):
    # elog    Error log entry dictionary data.

    Should Contain Any
    ...    ${elog["Message"]}    org.open_power.Host.Boot.Error.WatchdogTimedOut
    ...    CEC Hardware - Hostboot-Service Processor Interface
    ...    msg=Watchdog timeout event log was not found.

    Log To Console    Matched Found: ${elog}
