*** Settings ***
Documentation       BMC server health, collect eSELs.

# Test Parameters:
# OPENBMC_HOST      The BMC host name or IP address.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn

*** Variables ***
${QUIET}                       ${1}
${error_logs_flagged_rest}     Rest error log collection excluded
${event_logs_flagged_redfish}  Redfish event log collection excluded
${rest_error_logs}             Rest error log collection excluded
${redfish_event_logs}          Redfish error log collection excluded

*** Test Cases ***

Rest Collect eSELs
    [Documentation]  Collect eSEL using the OpenBMC Rest API.
    [Tags]  Rest_Collect_eSELs  rest
    [Teardown]  FFDC On Test Case Fail  clean_up=${FALSE}

    ${error_logs}=  Get Error Logs  ${QUIET}
    ${rest_error_logs}=  gen_robot_print.Sprint Vars  error_logs
    Set Suite Variable  ${rest_error_logs}
    Log To Console  ${rest_error_logs}

    # Filter out informational error logs.
    ${non_informational_error_logs}=  Filter Struct  ${error_logs}  [('Severity', '\.Informational$')]
    ...  regex=1  invert=1
    ${error_logs_flagged_rest}=  gen_robot_print.Sprint Vars  non_informational_error_logs
    Set Suite Variable  ${error_logs_flagged_rest}


Redfish Collect eSELs
    [Documentation]  Collect eSEL with Redfish.
    [Tags]  Redfish_Collect_eSELs  redfish
    [Setup]  Redfish.Login
    [Teardown]  Redfish Test Teardown Execution

    ${redfish_event_logs}=  Get Event Logs
    ${redfish_event_logs}=  gen_robot_print.Sprint Vars  redfish_event_logs
    Set Suite Variable  ${redfish_event_logs}
    Log To Console  ${redfish_event_logs}
    ${event_logs_flagged_redfish}=  Get Event Logs Not Ok
    ${event_logs_flagged_redfish}=  gen_robot_print.Sprint Vars  event_logs_flagged_redfish
    Set Suite Variable  ${event_logs_flagged_redfish}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do test suite setup tasks.

    Set Log Level  DEBUG
    REST Power On  stack_mode=skip


Suite Teardown Execution
    [Documentation]  Do suite teardown tasks. Log error and event logs collected.

    Log Many  ${rest_error_logs}  ${redfish_event_logs}
    Log  Flagged error logs found via REST:${\n}${error_logs_flagged_rest}  console=true
    Log  Flagged events logs found via Redfish:${\n}${event_logs_flagged_redfish}  console=true


Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown for redfish.

    Redfish.Logout
    FFDC On Test Case Fail  clean_up=${FALSE}
