*** Settings ***
Documentation       Test Error logging.

Resource            ../lib/connection_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Suite Setup         Run Keywords  Verify logging-test  AND
...                 Clear Existing Error Logs
Test Setup          Open Connection And Log In
Test Teardown       Close All Connections
Suite Teardown      Clear Existing Error Logs

*** Test Cases ***

Create Test Error And Verify
    [Documentation]  Create error logs and verify via REST.
    [Tags]  Create_Test_Error_And_Verify

    Create Test Error Log
    Verify Test Error Log


Test Error Persistency On Restart
    [Documentation]  Restart logging service and verify error logs don't exist.
    [Tags]  Test_Error_Persistency_On_Restart

    Create Test Error Log
    Verify Test Error Log
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Test Error Persistency On Reboot
    [Documentation]  Reboot BMC and verify error logs don't exist.
    [Tags]  Test_Error_Persistency_On_Reboot

    Create Test Error Log
    Verify Test Error Log
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


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

    Delete Error logs
    Create Test Error Log
    ${resolved}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Resolved
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

    Delete Error logs
    Create Test Error Log
    Create Test Error Log
    # The error log generated is associated with the epoc time and unique
    # for every error and in increasing time stamp.
    ${time_stamp1}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Timestamp
    ${time_stamp2}=  Read Attribute  ${BMC_LOGGING_ENTRY}${2}  Timestamp
    Should Be True  ${time_stamp2} > ${time_stamp1}


*** Keywords ***

Verify logging-test
    [Documentation]  Verify existence of prerequisite logging-test.

    Open Connection And Log In
    ${out}  ${stderr}=  Execute Command  which logging-test  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${out}  logging-test

Clear Existing Error Logs
    [Documentation]  If error log isn't empty, reboot the BMC to clear the log.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

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

    Execute Command On BMC  logging-test -c AutoTestSimple

Verify Test Error Log
    [Documentation]  Verify test error log entries.
    ${content}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Message
    Should Be Equal  ${content}
    ...  example.xyz.openbmc_project.Example.Elog.AutoTestSimple
    ${content}=  Read Attribute  ${BMC_LOGGING_ENTRY}${1}  Severity
    Should Be Equal  ${content}
    ...  xyz.openbmc_project.Logging.Entry.Level.Error

Delete Error logs
    [Documentation]  Delete error logs.

    # The REST method to delete error openbmc/openbmc#1327
    # until then using logging restart.
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for logging service to restart properly.
