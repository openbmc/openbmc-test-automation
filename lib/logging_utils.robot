*** Settings ***
Documentation    Error logging utility keywords.

Resource        rest_client.robot
Resource        bmc_redfish_utils.robot
Variables       ../data/variables.py
Variables       ../data/pel_variables.py

*** Variables ***


# Define variables for use by callers of 'Get Error Logs'.
${low_severity_errlog_regex}  \\.(Informational|Notice|Debug|OK)$
&{low_severity_errlog_filter}  Severity=${low_severity_errlog_regex}
&{low_severity_errlog_filter_args}  filter_dict=${low_severity_errlog_filter}  regex=${True}  invert=${True}
# The following is equivalent to &{low_severity_errlog_filter_args} but the name may be more intuitive for
# users. Example usage:
# ${err_logs}=  Get Error Logs  &{filter_low_severity_errlogs}
&{filter_low_severity_errlogs}  &{low_severity_errlog_filter_args}

*** Keywords ***

Get Logging Entry List
    [Documentation]  Get logging entry and return the object list.

    ${entry_list}=  Create List
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ${jsondata}=  To JSON  ${resp.content}

    FOR  ${entry}  IN  @{jsondata["data"]}
        Continue For Loop If  '${entry.rsplit('/', 1)[1]}' == 'callout'
        Append To List  ${entry_list}  ${entry}
    END

    # Logging entries list.
    # ['/xyz/openbmc_project/logging/entry/14',
    #  '/xyz/openbmc_project/logging/entry/15']
    [Return]  ${entry_list}


Logging Entry Should Exist
    [Documentation]  Find the matching message id and return the entry id.
    [Arguments]  ${message_id}

    # Description of argument(s):
    # message_id    Logging message string.
    #               Example: "xyz.openbmc_project.Common.Error.InternalFailure"

    @{elog_entries}=  Get Logging Entry List

    FOR  ${entry}  IN  @{elog_entries}
         ${resp}=  Read Properties  ${entry}
         ${status}=  Run Keyword And Return Status
         ...  Should Be Equal As Strings  ${message_id}  ${resp["Message"]}
         Return From Keyword If  ${status} == ${TRUE}  ${entry}
    END

    Fail  No ${message_id} logging entry found.


Get Error Logs
    [Documentation]  Return the BMC error logs as a dictionary.
    [Arguments]   ${quiet}=1  &{filter_struct_args}

    # Example of call using pre-defined filter args (defined above).

    # ${err_logs}=  Get Error Logs  &{filter_low_severity_errlogs}

    # In this example, all error logs with "Severity" fields that are neither Informational, Debug nor
    # Notice will be returned.

    # Description of argument(s):
    # quiet                         Indicates whether this keyword should run without any output to the
    #                               console, 0 = verbose, 1 = quiet.
    # filter_struct_args            filter_struct args (e.g. filter_dict, regex, etc.) to be passed directly
    #                               to the Filter Struct keyword.  See its prolog for details.

    #  The length of the returned dictionary indicates how many logs there are.

    # Use 'Print Error Logs' to print.  Example:

    # Print Error Logs  ${error_logs}  Message.

    ${status}  ${error_logs}=  Run Keyword And Ignore Error  Read Properties
    ...  /xyz/openbmc_project/logging/entry/enumerate  timeout=30  quiet=${quiet}
    Return From Keyword If  '${status}' == 'FAIL'  &{EMPTY}
    ${num_filter_struct_args}=  Get Length  ${filter_struct_args}
    Return From Keyword If  '${num_filter_struct_args}' == '${0}'  ${error_logs}
    ${filtered_error_logs}=  Filter Struct  ${error_logs}  &{filter_struct_args}
    [Return]  ${filtered_error_logs}


Get IPMI SEL Setting
    [Documentation]  Returns status for given IPMI SEL setting.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  SEL setting which needs to be read(e.g. "Last Add Time").

    ${resp}=  Run IPMI Standard Command  sel info

    ${setting_line}=  Get Lines Containing String  ${resp}  ${setting}
    ...  case-insensitive
    ${setting_status}=  Fetch From Right  ${setting_line}  :${SPACE}

    [Return]  ${setting_status}


Verify Watchdog Errorlog Content
    [Documentation]  Verify watchdog errorlog content.
    # Example:
    # "/xyz/openbmc_project/logging/entry/1":
    #  {
    #      "AdditionalData": [],
    #      "Id": 1,
    #      "Message": "org.open_power.Host.Boot.Error.WatchdogTimedOut",
    #      "Resolved": 0,
    #      "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #      "Timestamp": 1492715244828,
    #      "Associations": []
    # },

    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${elog}=  Read Properties  ${elog_entry[0]}
    Should Be Equal As Strings
    ...  ${elog["Message"]}  org.open_power.Host.Boot.Error.WatchdogTimedOut
    ...  msg=Watchdog timeout error log was not found.
    Should Be Equal As Strings
    ...  ${elog["Severity"]}  xyz.openbmc_project.Logging.Entry.Level.Error
    ...  msg=Watchdog timeout severity unexpected value.


Logging Test Binary Exist
    [Documentation]  Verify existence of prerequisite logging-test.
    Open Connection And Log In
    ${out}  ${stderr}=  Execute Command
    ...  which /tmp/tarball/bin/logging-test  return_stderr=True
    Should Be Empty  ${stderr}  msg=Logging Test stderr is non-empty.
    Should Contain  ${out}  logging-test
    ...  msg=Logging test returned unexpected result.

Clear Existing Error Logs
    [Documentation]  If error log isn't empty, reboot the BMC to clear the log.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=Could not clear BMC error logs.


Create Test PEL Log
    [Documentation]  Generate test PEL log.
    [Arguments]  ${pel_type}=Internal Failure

    # Description of argument(s):
    # pel_type      The PEL type (e.g. Internal Failure, FRU Callout, Procedural Callout).

    # Test PEL log entry example:
    # {
    #    "0x5000002D": {
    #            "SRC": "BD8D1002",
    #            "Message": "An application had an internal failure",
    #            "PLID": "0x5000002D",
    #            "CreatorID": "BMC",
    #            "Subsystem": "BMC Firmware",
    #            "Commit Time": "02/25/2020  04:47:09",
    #            "Sev": "Unrecoverable Error",
    #            "CompID": "0x1000"
    #    }
    # }

    Run Keyword If  '${pel_type}' == 'Internal Failure'
    ...   BMC Execute Command  ${CMD_INTERNAL_FAILURE}
    ...  ELSE IF  '${pel_type}' == 'FRU Callout'
    ...   BMC Execute Command  ${CMD_FRU_CALLOUT}
    ...  ELSE IF  '${pel_type}' == 'Procedure And Symbolic FRU Callout'
    ...   BMC Execute Command  ${CMD_PROCEDURAL_SYMBOLIC_FRU_CALLOUT}


Create Test Error Log
    [Documentation]  Generate test error log.
    # Test error log entry example:
    # "/xyz/openbmc_project/logging/entry/1":  {
    #     "AdditionalData": [
    #         "STRING=FOO"
    #     ],
    #     "Id": 1,
    #     "Message": "example.xyz.openbmc_project.Example.Elog.AutoTestSimple",
    #     "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #     "Timestamp": 1487743963328,
    #     "Associations": []
    # }
    BMC Execute Command  /tmp/tarball/bin/logging-test -c AutoTestSimple

Count Error Entries
    [Documentation]  Count Error entries.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Failed to get error logs.
    ${jsondata}=  To JSON  ${resp.content}
    ${count}=  Get Length  ${jsondata["data"]}
    [Return]  ${count}

Verify Test Error Log
    [Documentation]  Verify test error log entries.
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Message
    Should Be Equal  ${entry_id}
    ...  example.xyz.openbmc_project.Example.Elog.AutoTestSimple
    ...  msg=Error log not from AutoTestSimple.
    ${entry_id}=  Read Attribute  ${elog_entry[0]}  Severity
    Should Be Equal  ${entry_id}
    ...  xyz.openbmc_project.Logging.Entry.Level.Error
    ...  msg=Error log severity mismatch.

Delete Error Logs And Verify
    [Documentation]  Delete all error logs and verify.
    Delete All Error Logs
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=Error logs not deleted as expected.


Install Tarball
    [Documentation]  Install tarball on BMC.
    Should Not Be Empty  ${DEBUG_TARBALL_PATH}
    ...  msg=Debug tarball path value is required.
    BMC Execute Command  rm -rf /tmp/tarball
    Install Debug Tarball On BMC  ${DEBUG_TARBALL_PATH}


Get Event Logs
    [Documentation]  Get all available EventLog entries.

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
    #    "Id": "1",
    #    "Message": "org.open_power.Host.Error.Event",
    #    "Name": "System DBus Event Log Entry",
    #    "Severity": "Critical"
    #  }
    #  ],
    #  "Members@odata.count": 1,
    #  "Name": "System Event Log Entries"
    #}

    ${members}=  Redfish.Get Attribute  ${EVENT_LOG_URI}Entries  Members
    [Return]  ${members}


Get Redfish Event Logs
    [Documentation]  Pack the list of all available EventLog entries in dictionary.
    [Arguments]   ${quiet}=1  &{filter_struct_args}

    # Description of argument(s):
    # quiet                  Indicates whether this keyword should run without any output to the
    #                        console, 0 = verbose, 1 = quiet.
    # filter_struct_args     filter_struct args (e.g. filter_dict, regex, etc.) to be passed
    #                        directly to the Filter Struct keyword.  See its prolog for details.

    ${packed_dict}=  Create Dictionary
    ${error_logs}=  Get Event Logs

    FOR  ${idx}   IN  @{error_logs}
       Set To Dictionary  ${packed_dict}    ${idx['@odata.id']}=${idx}
    END

    ${num_filter_struct_args}=  Get Length  ${filter_struct_args}
    Return From Keyword If  '${num_filter_struct_args}' == '${0}'  &{packed_dict}
    ${filtered_error_logs}=  Filter Struct  ${packed_dict}  &{filter_struct_args}

    [Return]  ${filtered_error_logs}


Get Event Logs Not Ok
    [Documentation]  Get all event logs where the 'Severity' is not 'OK'.

    ${members}=  Get Event Logs
    ${severe_logs}=  Evaluate  [elog for elog in $members if elog['Severity'] != 'OK']
    [Return]  ${severe_logs}


Get Number Of Event Logs
    [Documentation]  Return the number of EventLog members.

    ${members}=  Get Event Logs
    ${num_members}=  Get Length  ${members}
    [Return]  ${num_members}


Redfish Purge Event Log
    [Documentation]  Do Redfish EventLog purge.

    ${target_action}=  redfish_utils.Get Target Actions
    ...  /redfish/v1/Systems/system/LogServices/EventLog/  LogService.ClearLog
    Redfish.Post  ${target_action}  body={'target': '${target_action}'}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

