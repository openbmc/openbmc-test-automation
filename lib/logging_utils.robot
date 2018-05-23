*** Settings ***
Documentation    Error logging utility keywords.

Resource        rest_client.robot
Variables       ../data/variables.py

*** Keywords ***

Get Logging Entry List
    [Documentation]  Get logging entry and return the object list.

    ${entry_list}=  Create List
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ${jsondata}=  To JSON  ${resp.content}

    :FOR  ${entry}  IN  @{jsondata["data"]}
    \  Continue For Loop If  '${entry.rsplit('/', 1)[1]}' == 'callout'
    \  Append To List  ${entry_list}  ${entry}

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

    :FOR  ${entry}  IN  @{elog_entries}
    \  ${resp}=  Read Properties  ${entry}
    \  ${status}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${message_id}  ${resp["Message"]}
    \  Return From Keyword If  ${status} == ${TRUE}  ${entry}

    Fail  No ${message_id} logging entry found.


Get Error Logs
    [Documentation]  Return a dictionary which contains the BMC error logs.
    [Arguments]   ${quiet}=1

    # Description of argument(s):
    # quiet   Indicates whether this keyword should run without any output to
    #         the console, 0 = verbose, 1 = quiet.

    #  The length of the returned dictionary indicates how many logs there are.
    #  Printing of error logs can be done with the keyword Print Error Logs,
    #  for example, Print Error Logs  ${error_logs}  Message.

    ${status}  ${error_logs}=  Run Keyword And Ignore Error  Read Properties
    ...  /xyz/openbmc_project/logging/entry/enumerate  quiet=${quiet}

    ${empty_dict}=  Create Dictionary
    Return From Keyword If  '${status}' == 'FAIL'  ${empty_dict}
    [Return]  ${error_logs}


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
    #      "associations": []
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
    #     "associations": []
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
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    ...  msg=Error logs not deleted as expected.


Install Tarball
    [Documentation]  Install tarball on BMC.
    Run Keyword If  '${DEBUG_TARBALL_PATH}' == '${EMPTY}'  Return From Keyword
    BMC Execute Command  rm -rf /tmp/tarball
    Install Debug Tarball On BMC  ${DEBUG_TARBALL_PATH}
