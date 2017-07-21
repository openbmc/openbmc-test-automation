*** Settings ***
Documentation     BMC error polling test to check errors every 10 seconds.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/resource.txt
Resource          ../lib/boot_utils.robot

Suite Setup      Setup The Suite
Test Teardown    Post Test Case Execution

*** Variables ***

# Default duration and interval of test to run.
${POLL_DURATION}  48 hours
${POLL_INTERVAL}  10 second

*** Test Cases ***

Poll BMC For Errors
    [Documentation]  Poll every user defined interval and verify if errors
    ...  exist.
    [Tags]  Poll_BMC_For_Errors

    Repeat Keyword  ${POLL_DURATION}
    ...  Run Keywords  Enumerate Sensors And Check For Errors
    ...  AND  Sleep  ${POLL_INTERVAL}

***Keywords***

Enumerate Sensors And Check For Errors
    [Documentation]  Enumerate and check if there is any error reported.

    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/sensors/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    Check If Error Logs Exist


Setup The Suite
    [Documentation]  Validates input parameters & check if HOST OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Open Connection And Log In

    Delete Error Logs
    Check If Error Logs Exist


Check If Error Logs Exist
    [Documentation]  Delete all error logs and verify.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Post Test Case Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
