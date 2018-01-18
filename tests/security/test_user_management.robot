*** Settings ***
Documentation   OpenBMC user management test.

Resource         ../../lib/rest_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          SSHLibrary

Test Teardown    Test Teardown Execution

*** Variables ****

${OPENBMC_TEST_PASSWORD}   abc123

*** Test Cases ***

Verify Root Password Update
    [Documentation]  Update system "root" user password and verify.
    [Tags]  Verify_Root_Password_Update

    Delete All Sessions

    Initialize OpenBMC
    Update Root Password  ${OPENBMC_TEST_PASSWORD}

    # Time for user manager to sync.
    Sleep  5 s

    Delete All Sessions

    # SSH Login to BMC with new "root" password.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Login  ${OPENBMC_USERNAME}  ${OPENBMC_TEST_PASSWORD}

    # REST Login to BMC with new "root" password.
    REST Login To BMC  ${OPENBMC_TEST_PASSWORD}

    ${resp}=  Get Request  openbmc  ${BMC_USER_URI}enumerate
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do test teardown task.

    REST Login To BMC  ${OPENBMC_TEST_PASSWORD}
    Update Root Password
    Sleep  5 s
    Delete All Sessions

    # SSH Login to BMC with user default "root" password.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    # REST Login to BMC with user default "root" password.
    REST Login To BMC  ${OPENBMC_PASSWORD}

    FFDC On Test Case Fail


Update Root Password
    [Documentation]  Update system default "root" user password.
    [Arguments]  ${user_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # user_password  User password string.

    @{password} =  Create List  ${user_password}
    ${data}=  Create Dictionary  data=@{password}

    ${headers}=  Create Dictionary  Content-Type=application/json
    ${resp}=  Post Request  openbmc  ${BMC_USER_URI}root/action/SetPassword
    ...  data=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


REST Login To BMC
    [Documentation]  Establish session to BMC.
    [Arguments]  ${user_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # user_password  User password string.

    Create Session  openbmc  ${AUTH_URI}  timeout=20  max_retries=3

    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${user_password}
    ${data}=  Create Dictionary   data=@{credentials}
    ${resp}=  Post Request  openbmc  /login  data=${data}  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

