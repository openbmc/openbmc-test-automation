*** Settings ***
Documentation       BMC server health, check error logs.

# Test Parameters:
# OPENBMC_HOST      The BMC host name or IP address.

Resource            ../lib/bmc_redfish_resource.robot
Resource            ../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Test Setup          Printn

*** Variables ***
${QUIET}                       ${1}

*** Test Cases ***

Collect Error Logs
    [Documentation]  Check error logs with Redfish.
    [Tags]  check_errors
    [Setup]  Redfish.Login
    [Teardown]  Redfish Test Teardown Execution

    ${redfish_event_logs}=  Get Event Logs
    ${redfish_event_logs}=  gen_robot_print.Sprint Vars  redfish_event_logs
    Set Suite Variable  ${redfish_event_logs}
    Log To Console  \n\nEvent logs:${redfish_event_logs}
    ${event_logs_flagged}=  Get Event Logs Not Ok
    ${event_logs_flagged}=  gen_robot_print.Sprint Vars  event_logs_flagged
    Log To Console  \n\nEvent logs flagged:${event_logs_flagged}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Set Log Level  DEBUG
    Log To Console  ${OPENBMC_HOST}


Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown for redfish.

    Redfish.Logout
    FFDC On Test Case Fail  clean_up=${FALSE}
