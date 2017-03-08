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
    [Tags]  Create_Test_Error_And_Verify

    Create Test Error Log
    Verify Test Error Log


Test Error Presistency On Restart
    [Documentation]  Restart logging service and check if error log exist.
    [Tags]  Test_Error_Presistency_On_Restart

    Create Test Error Log
    Verify Test Error Log
    Execute Command On BMC
    ...  systemctl restart xyz.openbmc_project.Logging.service
    Sleep  10s  reason=Wait for service to restart properly.
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Test Error Persistency On Reboot
    [Documentation]  Reboot BMC and check if error log exist.
    [Tags]  Test_Error_Persistency_On_Reboot

    Create Test Error Log
    Verify Test Error Log
    Initiate BMC Reboot
    Wait Until Keyword Succeeds  10 min  10 sec
    ...  Is BMC Ready
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

Verify Test Error Log
    [Documentation]  Verify test error log entries.
    ${content}=     Read Attribute      ${BMC_LOGGING_ENTRY}${1}   Message
    Should Be Equal     ${content}      AutoTestSimple
    ${content}=     Read Attribute      ${BMC_LOGGING_ENTRY}${1}   Severity
    Should Be Equal     ${content}
    ...    xyz.openbmc_project.Logging.Entry.Level.Emergency
