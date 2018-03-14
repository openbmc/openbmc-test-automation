*** Settings ***
Documentation       Test Error logging.

Resource            ../lib/connection_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot
Resource            ../lib/ipmi_client.robot
Resource            ../lib/boot_utils.robot

Test Setup          Test Setup Execution
Test Teardown       Test Teardown Execution
Suite Teardown      Delete Error Logs And Verify

*** Variables ***

${stack_mode}       skip

*** Test Cases ***

Error Log Check After BMC Reboot
    [Documentation]  Check error log after BMC rebooted.
    [Tags]  Error_Log_Check_At_BMC_Ready
    # 1. Power off.
    # 2. Delete error logs.
    # 3. Reboot BMC.
    # 4. Check if eror log exists.

    Smart Power Off
    Delete Error Logs And Verify
    OBMC Reboot (off)  stack_mode=normal
    Error Logs Should Not Exist


Error Log Check After Host Poweron
    [Documentation]  Check error log after host has booted.
    [Tags]  Error_Log_Check_At_Host_Booted
    # 1. Delete error logs
    # 1. Power on.
    # 3. Check if eror log exists.

    Delete Error Logs And Verify
    REST Power On
    Error Logs Should Not Exist


Create Test Error And Verify
    [Documentation]  Create error logs and verify via REST.
    [Tags]  Create_Test_Error_And_Verify

    Create Test Error Log
    Verify Test Error Log


Test Error Persistency On Restart
    [Documentation]  Restart logging service and verify error logs.
    [Tags]  Test_Error_Persistency_On_Restart

    Create Test Error Log
    Verify Test Error Log
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.
    Verify Test Error Log


Test Error Entry Numbering Reset On Restart
    [Documentation]  Restarts logging service and verify error logs entry start
    ...  from entry "Id" 1.
    # 1. Create error log.
    # 2. Verify error log.
    # 3. Delete error log.
    # 4. Restart logging service.
    # 5. Create error log.
    # 6. Verify new error log entry starts with Id entry 1.

    [Tags]  Test_Error_Entry_Numbering_Reset_On_Restart
    # Example Error logs:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #    "AdditionalData": [
    #        "STRING=FOO"
    #    ],
    #    "Id": 1,   <--- Entry value should be 1.
    #    "Message": "example.xyz.openbmc_project.Example.Elog.AutoTestSimple",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1490818990051,
    #    "associations": []
    #  },

    Create Test Error Log
    Verify Test Error Log
    Delete All Error Logs
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.
    Create Test Error Log
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Id
    Should Be Equal  ${entry_id}  ${1}


Test Error Persistency On Reboot
    [Documentation]  Reboot BMC and verify error logs.
    [Tags]  Test_Error_Persistency_On_Reboot

    Create Test Error Log
    Verify Test Error Log
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
    Verify Test Error Log


Create Test Error And Verify Resolved Field
    [Documentation]  Create error log and verify "Resolved"
    ...              field is 0.
    [Tags]  Create_Test_Error_And_Verify_Resolved_Field

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

    # It's work in progress, but it's mnfg need. To mark an error as
    # resolved, without deleting the error, mfg will set this bool
    # property.
    # In this test context we are making sure "Resolved" field is "0"
    # by default.

    Delete All Error Logs
    Create Test Error Log
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resolved}=  Read Attribute  ${elog_entry[0]}  Resolved
    Should Be True  ${resolved} == 0


Create Test Errors And Verify Time Stamp
    [Documentation]  Create error logs and verify time stamp.
    [Tags]  Create_Test_Error_And_Verify_Time_Stamp

    # Example Error logs:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #    "AdditionalData": [
    #        "STRING=FOO"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.AutoTestSimple",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1490818990051,  <--- Time stamp
    #    "associations": []
    #  },
    #  "/xyz/openbmc_project/logging/entry/2": {
    #    "AdditionalData": [
    #        "STRING=FOO"
    #    ],
    #    "Id": 2,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.AutoTestSimple",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1490818992116,   <---- Time stamp
    #    "associations": []
    # },

    Delete All Error Logs
    Create Test Error Log
    Create Test Error Log
    # The error log generated is associated with the epoc time and unique
    # for every error and in increasing time stamp.
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${time_stamp1}=  Read Attribute  ${elog_entry[0]}  Timestamp
    ${time_stamp2}=  Read Attribute  ${elog_entry[1]}  Timestamp
    Should Be True  ${time_stamp2} > ${time_stamp1}

Create Test Error Log And Delete
    [Documentation]  Create an error log and delete it.
    [Tags]  Create_Test_Error_Log_And_Delete

    Delete Error Logs And Verify
    Create Test Error Log
    Delete Error Logs And Verify

Create Multiple Test Error Logs And Delete All
    [Documentation]  Create multiple error logs and delete all.
    [Tags]  Create_Multiple_Test_Error_Logs_And_Delete_All

    Delete Error Logs And Verify
    Create Test Error Log
    Create Test Error Log
    Create Test Error Log
    Delete Error Logs And Verify

Create Two Test Error Logs And Delete One
    [Documentation]  Create two error logs and delete the first entry.
    [Tags]  Create_Two_Test_Error_Logs_And_Delete_One

    Delete Error Logs And Verify
    Create Test Error Log
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    Create Test Error Log
    Delete Error log Entry  ${elog_entry[0]}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Verify IPMI SEL Version
    [Documentation]  Verify IPMI SEL's version info.
    [Tags]  Verify_IPMI_SEL_Version

    ${version_info}=  Get IPMI SEL Setting  Version
    ${setting_status}=  Fetch From Left  ${version_info}  (
    ${setting_status}=  Evaluate  $setting_status.replace(' ','')

    Should Be True  ${setting_status} >= 1.5
    Should Contain  ${version_info}  v2 compliant  case_insensitive=True


Verify Watchdog Timedout Error
    [Documentation]  Trigger watchdog timed out and verify errorlog generated.
    [Tags]  Verify_Watchdog_Timedout_Error

    REST Power Off
    REST Power On

    # Clear errors if there are any.
    Delete All Error Logs

    Trigger Host Watchdog Error

    # Logging took time to generate the timedout error.
    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Verify Watchdog Errorlog Content


Verify IPMI SEL Delete
    [Documentation]  Verify IPMI SEL delete operation.
    [Tags]  Verify_IPMI_SEL_Delete

    Delete Error Logs And Verify
    Create Test Error Log

    ${sel_list}=  Run IPMI Standard Command  sel list
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


Verify Empty SEL
    [Documentation]  Verify empty SEL list.
    [Tags]  Verify_Empty_SEL

    Delete Error Logs And Verify

    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Delete Non Existing SEL Entry
    [Documentation]  Delete non existing SEL entry.
    [Tags]  Delete_Non_Existing_SEL_Entry

    Delete Error Logs And Verify
    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete 100
    Should Contain  ${sel_delete}  Unable to delete entry
    ...  case_insensitive=True


Delete Invalid SEL Entry
    [Documentation]  Delete invalid SEL entry.
    [Tags]  Delete_Invalid_SEL_Entry

    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete abc
    Should Contain  ${sel_delete}  Given SEL ID 'abc' is invalid
    ...  case_insensitive=True


Verify IPMI SEL Entries
    [Documentation]  Verify IPMI SEL's entries info.
    [Tags]  Verify_IPMI_SEL_Entries

    Delete Error Logs And Verify

    # Generate error logs of random count.
    ${count}=  Evaluate  random.randint(1, 5)  modules=random
    Repeat Keyword  ${count}  Create Test Error Log

    ${sel_entries_count}=  Get IPMI SEL Setting  Entries
    Should Be Equal As Strings  ${sel_entries_count}  ${count}


Verify IPMI SEL Last Add Time
    [Documentation]  Verify IPMI SEL's last added timestamp.
    [Tags]  Verify_IPMI_SEL_Last_Add_Time

    Create Test Error Log
    ${sel_time}=  Run IPMI Standard Command  sel time get
    ${sel_time}=  Convert Date  ${sel_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${sel_last_add_time}=  Get IPMI SEL Setting  Last Add Time
    ${sel_last_add_time}=  Convert Date  ${sel_last_add_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${time-diff}=
    ...  Subtract Date From Date  ${sel_last_add_time}  ${sel_time}

    # Verify if the delay in current time check and last add SEL time
    # is less or equals to 2 seconds.
    Should Be True  ${time-diff} <= 2

Verify Error Logs Capping
    [Documentation]  Verify error logs capping.
    [Tags]  Verify_Error_Logs_Capping

    Delete Error Logs And Verify
    ${cmd}=  Catenate  for i in {1..201}; do /tmp/tarball/bin/logging-test -c
    ...  AutoTestSimple; done
    Execute Command On BMC  ${cmd}
    ${count}=  Count Error Entries
    Run Keyword If  ${count} > 200
    ...  Fail  Error logs created exceeded max capacity 200.

Test Error Log Rotation
    [Documentation]  Verify creation of 201 error log is replaced by entry id 1.
    [Tags]  Test_Error_Log_Rotation

    Delete Error Logs And Verify

    # Restart service.
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.

    # Create 200 error logs.
    ${cmd}=  Catenate  for i in {1..200}; do /tmp/tarball/bin/logging-test -c
    ...  AutoTestSimple;done
    BMC Execute Command  ${cmd}

    # Check the response for 200th error log.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${200}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Check if error log with id 1 exists.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Create error log and verify the entry ID is 201 and not 1.
    Create Test Error Log
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${201}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Error log 1 is not present.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

*** Keywords ***

Test Setup Execution
   [Documentation]  Do test case setup tasks.

   ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
   Run Keyword If  ${status} == ${False}  Install Tarball
   Delete Error Logs And Verify


Test Teardown Execution
   [Documentation]  Do the post test teardown.
   # 1. Capture FFDC on test failure.
   # 2. Delete error logs.
   # 3. Close all open SSH connections.
   # 4. Clear all REST sessions.

   FFDC On Test Case Fail
   Delete All Error Logs
   Close All Connections
