*** Settings ***
Documentation       Test Error logging.

Resource            ../lib/connection_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource            ../lib/state_manager.robot

Suite Setup         Clear Existing Error Logs
Test Setup          Open Connection And Log In
Test Teardown       Close All Connections
Suite Teardown      Clear Existing Error Logs

*** Test Cases ***

Create Test Error And Verify
    [Documentation]  Create error logs and verify via REST.

    Create Test Error Log
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Test Error Persitency
    [Documentation]  Reboot BMC and check if error log exist.

    Clear Existing Error Logs
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


*** Keywords ***

Clear Existing Error Logs
    [Documentation]  Flush error logs entries if exist.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    # If entry doesn't exist return else reboot BMC to clear
    # existing error logs.
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Create Test Error Log
    [Documentation]  Generate test error log.

    # Test error log entry example :
    # "/xyz/openbmc_project/logging/entry/1": {
    #    "Timestamp": 1487744075266,
    #    "AdditionalData": [],
    #    "Message": "AutoTestSimple",
    #    "Id": 1,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency"
    # }

    Execute Command On BMC  logging-test -c AutoTestSimple

