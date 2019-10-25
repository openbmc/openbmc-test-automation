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

** Variables ***

${max_num_event_logs}  ${200}

*** Test Cases ***

Event Log Check After BMC Reboot
    [Documentation]  Check event log after BMC rebooted.
    [Tags]  Event_Log_Check_After_BMC_Reboot

    Redfish Purge Event Log
    Event Log Should Not Exist

    Redfish OBMC Reboot (off)

    Redfish.Login
    Wait Until Keyword Succeeds  1 mins  15 secs   Redfish.Get  ${EVENT_LOG_URI}Entries

    Event Log Should Not Exist


Event Log Check After Host Poweron
    [Documentation]  Check event log after host has booted.
    [Tags]  Event_Log_Check_After_Host_Poweron

    Redfish Purge Event Log
    Event Log Should Not Exist

    Redfish Power On

    Redfish.Login
    Event Log Should Not Exist


Create Test Event Log And Verify
    [Documentation]  Create event logs and verify via redfish.
    [Tags]  Create_Test_Event_Log_And_Verify

    Create Test Error Log
    Event Log Should Exist


Test Event Log Persistency On Restart
    [Documentation]  Restart logging service and verify event logs.
    [Tags]  Test_Event_Log_Persistency_On_Restart

    Create Test Error Log
    Event Log Should Exist

    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.

    Event Log Should Exist


Test Event Entry Numbering Reset On Restart
    [Documentation]  Restart logging service and verify event logs entry starts
    ...  from entry "Id" 1.
    [Tags]  Test_Event_Entry_Numbering_Reset_On_Restart

    #{
    #  "@odata.context": "/redfish/v1/$metadata#LogEntryCollection.LogEntryCollection",
    #  "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries",
    #  "@odata.type": "#LogEntryCollection.LogEntryCollection",
    #  "Description": "Collection of System Event Log Entries",
    #  "Members": [
    #  {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntry.LogEntry",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/1",
    #    "@odata.type": "#LogEntry.v1_4_0.LogEntry",
    #    "Created": "2019-05-29T13:19:27+00:00",
    #    "EntryType": "Event",
    #    "Id": "1",               <----- Event log ID
    #    "Message": "org.open_power.Host.Error.Event",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    #  }
    #  ],
    #  "Members@odata.count": 1,
    #  "Name": "System Event Log Entries"
    #}

    Create Test Error Log
    Create Test Error Log
    Event Log Should Exist

    Redfish Purge Event Log
    Event Log Should Not Exist

    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.

    Create Test Error Log
    ${elogs}=  Get Event Logs
    Should Be Equal  ${elogs[0]["Id"]}  1  msg=Event log entry is not 1.


Test Event Log Persistency On Reboot
    [Documentation]  Reboot BMC and verify event log.
    [Tags]  Test_Event_Log_Persistency_On_Reboot

    Redfish Purge Event Log
    Create Test Error Log
    Event Log Should Exist

    Redfish OBMC Reboot (off)

    Redfish.Login
    Wait Until Keyword Succeeds  1 mins  15 secs   Redfish.Get  ${EVENT_LOG_URI}Entries

    Event Log Should Exist


# TODO: openbmc/openbmc-test-automation#1789
Create Test Event Log And Verify Resolved Field
    [Documentation]  Create event log and verify "Resolved" field is 0.
    [Tags]  Create_Test_Event_Log_And_Verify_Resolved_Field

    # Example Error log:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #    "AdditionalData": [
    #        "STRING=FOO"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.AutoTestSimple",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1490817164983,
    #    "associations": []
    # },

    # To mark an error as resolved, without deleting the error, user would
    # set this bool property.
    # In this test context we are making sure "Resolved" field is "0"
    # by default.

    Redfish Purge Event Log
    Create Test Error Log
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resolved}=  Read Attribute  ${elog_entry[0]}  Resolved
    Should Be True  ${resolved} == 0


Create Test Event Log And Verify Time Stamp
    [Documentation]  Create event logs and verify time stamp.
    [Tags]  Create_Test_Event_Log_And_Verify_Time_Stamp

    #{
    #  "@odata.context": "/redfish/v1/$metadata#LogEntryCollection.LogEntryCollection",
    #  "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries",
    #  "@odata.type": "#LogEntryCollection.LogEntryCollection",
    #  "Description": "Collection of System Event Log Entries",
    #  "Members": [
    #  {
    #    "@odata.context": "/redfish/v1/$metadata#LogEntry.LogEntry",
    #    "@odata.id": "/redfish/v1/Systems/system/LogServices/EventLog/Entries/1",
    #    "@odata.type": "#LogEntry.v1_4_0.LogEntry",
    #    "Created": "2019-05-29T13:19:27+00:00", <--- Time stamp
    #    "EntryType": "Event",
    #    "Id": "1",
    #    "Message": "org.open_power.Host.Error.Event",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    #  }
    #  ],
    #  "Members@odata.count": 1,
    #  "Name": "System Event Log Entries"
    #}

    Redfish Purge Event Log

    Create Test Error Log
    Sleep  2s
    Create Test Error Log

    ${elog_entry}=  Get Event Logs

    # The event log generated is associated with the epoc time and unique
    # for every error and in increasing time stamp.
    ${time_stamp1}=  Convert Date  ${elog_entry[0]["Created"]}  epoch
    ${time_stamp2}=  Convert Date  ${elog_entry[1]["Created"]}  epoch

    Should Be True  ${time_stamp2} > ${time_stamp1}


Verify IPMI SEL Delete
    [Documentation]  Verify IPMI SEL delete operation.
    [Tags]  Verify_IPMI_SEL_Delete

    Redfish Purge Event Log
    Create Test Error Log

    ${sel_list}=  Run IPMI Standard Command  sel list
    Should Not Be Equal As Strings  ${sel_list}  SEL has no entries

    # Example of SEL List:
    # 4 | 04/21/2017 | 10:51:16 | System Event #0x01 | Undetermined system hardware failure | Asserted

    ${sel_entry}=  Fetch from Left  ${sel_list}  |
    ${sel_entry}=  Evaluate  $sel_entry.replace(' ','')
    ${sel_entry}=  Convert To Integer  0x${sel_entry}

    ${sel_delete}=  Run IPMI Standard Command  sel delete ${sel_entry}
    Should Be Equal As Strings  ${sel_delete}  Deleted entry ${sel_entry}
    ...  case_insensitive=True

    ${sel_list}=  Run IPMI Standard Command  sel list
    Should Be Equal As Strings  ${sel_list}  SEL has no entries
    ...  case_insensitive=True


Delete Non Existing SEL Event Entry
    [Documentation]  Delete non existing SEL event entry.
    [Tags]  Delete_Non_Existing_SEL_Event_Entry

    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete 100
    Should Contain  ${sel_delete}  Unable to delete entry
    ...  case_insensitive=True


Delete Invalid SEL Event Entry
    [Documentation]  Delete invalid SEL event entry.
    [Tags]  Delete_Invalid_SEL_Event_Entry

    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete abc
    Should Contain  ${sel_delete}  Given SEL ID 'abc' is invalid
    ...  case_insensitive=True


Verify IPMI SEL Event Entries
    [Documentation]  Verify IPMI SEL's entries info.
    [Tags]  Verify_IPMI_SEL_Event_Entries

    # Generate error logs of random count.
    ${count}=  Evaluate  random.randint(1, 5)  modules=random
    Repeat Keyword  ${count}  Create Test Error Log

    ${sel_entries_count}=  Get IPMI SEL Setting  Entries
    Should Be Equal As Strings  ${sel_entries_count}  ${count}


Verify IPMI SEL Event Last Add Time
    [Documentation]  Verify IPMI SEL's last added timestamp.
    [Tags]  Verify_IPMI_SEL_Event_Last_Add_Time

    Create Test Error Log
    ${sel_time}=  Run IPMI Standard Command  sel time get
    ${sel_time}=  Convert Date  ${sel_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${sel_last_add_time}=  Get IPMI SEL Setting  Last Add Time
    ${sel_last_add_time}=  Convert Date  ${sel_last_add_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${time_diff}=
    ...  Subtract Date From Date  ${sel_last_add_time}  ${sel_time}

    # Verify if the delay in current time check and last add SEL time
    # is less or equals to 2 seconds.
    Should Be True  ${time_diff} <= 2


Create Test Event Log And Delete
    [Documentation]  Create an event log and delete it.
    [Tags]  Create_Test_Event_Log_And_Delete

    Create Test Error Log
    Redfish Purge Event Log
    Event Log Should Not Exist


Create Multiple Test Event Logs And Delete All
    [Documentation]  Create multiple event logs and delete all.
    [Tags]  Create_Multiple_Test_Event_Logs_And_Delete_All

    Create Test Error Log
    Create Test Error Log
    Create Test Error Log
    Redfish Purge Event Log
    Event Log Should Not Exist


# TODO: openbmc/openbmc-test-automation#1789
Create Two Test Event Logs And Delete One
    [Documentation]  Create two event logs and delete the first entry.
    [Tags]  Create_Two_Test_Eevent_Logs_And_Delete_One

    Redfish Purge Event Log
    Create Test Error Log
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    Create Test Error Log
    Delete Error log Entry  ${elog_entry[0]}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Verify Watchdog Timedout Event
    [Documentation]  Trigger watchdog timed out and verify event log generated.
    [Tags]  Verify_Watchdog_Timedout_Event

    Redfish Power On

    # Clear errors if there are any.
    Redfish.Login
    Redfish Purge Event Log

    Trigger Host Watchdog Error

    # Logging takes time to generate the timeout error.
    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Verify Watchdog EventLog Content


Verify Event Logs Capping
    [Documentation]  Verify event logs capping.
    [Tags]  Verify_Event_Logs_Capping

    Redfish Purge Event Log

    ${cmd}=  Catenate  for i in {1..201}; do /tmp/tarball/bin/logging-test -c
    ...  AutoTestSimple;sleep 1;done
    BMC Execute Command  ${cmd}

    ${elogs}=  Get Event Logs
    ${count}=  Get Length  ${elogs}
    Run Keyword If  ${count} > 200
    ...  Fail  Error logs created exceeded max capacity 200.


Test Event Log Wrapping
    [Documentation]  Verify event log entries wraps when 200 max cap is reached.
    [Tags]  Test_Event_Log_Wrapping

    # Restarting logging service in order to clear logs and get the next log
    # ID set to 1.
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.

    # Create ${max_num_event_logs} event logs.
    ${cmd}=  Catenate  for i in {1..${max_num_event_logs}}; do /tmp/tarball/bin/logging-test -c
    ...  AutoTestSimple;sleep 1;done
    BMC Execute Command  ${cmd}

    # Verify that event logs with IDs 1 and ${max_num_event_logs} exist.
    ${event_log}=  Get Event Logs

    ${log_entries}=  Filter Struct  ${event_log}  [('Id', '1')]
    Rprint Vars  log_entries
    Should Be Equal As Strings  ${log_entries[0]["Id"]}  1

    ${log_entries}=  Filter Struct  ${event_log}  [('Id', '${max_num_event_logs}')]
    Rprint Vars  log_entries
    Should Be Equal As Strings  ${log_entries[0]["Id"]}  ${max_num_event_logs}

    # Create event log and verify the entry ID, ${max_num_event_logs + 1}.
    ${next_event_log_id}=  Set Variable  ${max_num_event_logs + 1}

    Create Test Error Log

    ${event_log}=  Get Event Logs

    ${log_entries}=  Filter Struct  ${event_log}  [('Id', '${next_event_log_id}')]
    Rprint Vars  log_entries
    Should Be Equal As Strings  ${log_entries[0]["Id"]}  ${next_event_log_id}

    # Event log 1 should be wrapped.
    ${log_entries}=  Filter Struct  ${event_log}  [('Id', '1')]
    Rprint Vars  log_entries

    ${length_log_entries}  Get Length  ${log_entries}
    Should Be Equal As Integers  ${length_log_entries}  0
    ...  msg=The event log should have wrapped such that entry ID 1 is now purged.


*** Keywords ***

Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Redfish.Login

    Redfish Purge Event Log

    ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Redfish Purge Event Log

    ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Login
    Redfish Purge Event Log


Event Log Should Not Exist
    [Documentation]  Event log entries should not exist.

    ${elogs}=  Get Event Logs
    Should Be Empty  ${elogs}  msg=System event log entry is not empty.


Event Log Should Exist
    [Documentation]  Event log entries should exist.

    ${elogs}=  Get Event Logs
    Should Not Be Empty  ${elogs}  msg=System event log entry is not empty.


Verify Watchdog EventLog Content
    [Documentation]  Verify watchdog event log content.

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

    ${elog}=  Get Event Logs
    Should Be Equal As Strings
    ...  ${elog[0]["Message"]}  org.open_power.Host.Boot.Error.WatchdogTimedOut
    ...  msg=Watchdog timeout event log was not found.
    Should Be Equal As Strings
    ...  ${elog[0]["Severity"]}  Critical
    ...  msg=Watchdog timeout severity unexpected value.
