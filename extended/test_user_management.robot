*** Settings ***
Documentation   OpenBMC user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          SSHLibrary

Test Teardown    Test Teardown Execution

*** Variables ****

${test_password}   0penBmc123

*** Test Cases ***


Verify At Least One User In List
    [Documentation]  Verify user list API list minimum one user.
    [Tags]  Verify_At_Least_One_User_In_List
    # Forego normal test teardown:
    [Teardown]  No Operation

    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}list
    Should Not Be Empty  ${bmc_user_uris}


Verify Root Password Update
    [Documentation]  Update system "root" user password and verify.
    [Tags]  Verify_Root_Password_Update

    Delete All Sessions

    Initialize OpenBMC
    Update Root Password  ${test_password}

    # Time for user manager to sync.
    Sleep  5 s

    Delete All Sessions

    # SSH Login to BMC with new "root" password.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Login  ${OPENBMC_USERNAME}  ${test_password}

    # REST Login to BMC with new "root" password.
    Initialize OpenBMC  REST_PASSWORD=${test_password}

    ${resp}=  Get Request  openbmc  ${BMC_USER_URI}enumerate
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Verify of new root password failed, RC=${resp.status_code}.


*** Keywords ***

Test Teardown Execution
    [Documentation]  Do test teardown task.

    # REST Login to BMC with new "root" password.
    Initialize OpenBMC  REST_PASSWORD=${test_password}
    Update Root Password
    Sleep  5 s
    Delete All Sessions

    # SSH Login to BMC with user default "root" password.
    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    # REST Login to BMC with user default "root" password.
    Initialize OpenBMC

    FFDC On Test Case Fail
    Close All Connections


Update Root Password
    [Documentation]  Update system default "root" user password.
    [Arguments]  ${user_password}=${OPENBMC_PASSWORD}

    # Description of argument(s):
    # user_password  User password string.

    @{password} =  Create List  ${user_password}
    ${data} =  Create Dictionary  data=@{password}

    ${headers} =  Create Dictionary  Content-Type=application/json
    ${resp} =  Post Request  openbmc  ${BMC_USER_URI}root/action/SetPassword
    ...  data=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  msg=Updating the new root password failed, RC=${resp.status_code}.
