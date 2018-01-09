*** Settings ***
Documentation     BMC error polling test to check errors every 10 seconds.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.txt
Resource          ../lib/boot_utils.robot

Suite Setup      Suite Setup Execution
Test Teardown    Post Test Case Execution

*** Variables ***

# Default duration and interval of test to run.
${POLL_DURATION}  48 hours
${POLL_INTERVAL}  10 second

*** Test Cases ***

Poll BMC For Errors
    [Documentation]  Poll BMC for errors.
    ...  exist.
    [Tags]  Poll_BMC_For_Errors

    Repeat Keyword  ${POLL_DURATION}
    ...  Run Keywords  Enumerate Sensors And Check For Errors
    ...  AND  Sleep  ${POLL_INTERVAL}

*** Keywords ***

Enumerate Sensors And Check For Errors
    [Documentation]  Enumerate and check if there is any error reported.

    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/sensors/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    Error Logs Should Not Exist


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide hostname or IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

    Delete Error Logs
    Error Logs Should Not Exist

Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.

    FFDC On Test Case Fail
