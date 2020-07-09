*** Settings ***
Documentation     BMC error polling test to check errors every 10 seconds.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/esel_utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    Post Test Case Execution

*** Variables ***

# Default duration and interval of test to run.
${POLL_DURATION}  48 hours
${POLL_INTERVAL}  10 second

# Error log Severities to ignore when checking Error Logs.
@{ESEL_IGNORE_LIST}
...  xyz.openbmc_project.Logging.Entry.Level.Informational


*** Test Cases ***

Poll BMC For Errors
    [Documentation]  Poll BMC for errors.
    ...  exist.
    [Tags]  Poll_BMC_For_Errors

    Redfish.Login
    Repeat Keyword  ${POLL_DURATION}
    ...  Run Keywords  Enumerate Sensors And Check For Errors
    ...  AND  Sleep  ${POLL_INTERVAL}

*** Keywords ***

Enumerate Sensors And Check For Errors
    [Documentation]  Enumerate and check if there is any error reported.

    Redfish.Get  /redfish/v1/Chassis/chassis/Sensors

    Check For Error Logs  ${ESEL_IGNORE_LIST}


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide hostname or IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    Redfish Power On  stack_mode=skip
    Redfish.Login

    Delete Error Logs
    Error Logs Should Not Exist


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.

    FFDC On Test Case Fail
    Redfish.Logout
