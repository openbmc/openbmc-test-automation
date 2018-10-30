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
    [Teardown]  FFDC On Test Case Fail

    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}list
    Should Not Be Empty  ${bmc_user_uris}


Verify User Group And Privilege Created
    [Documentation]  Verify user group and associated privilege is created.
    [Tags]  Verify_User_Group_And_Privilege_Created

    Create Group And Privilege  ${GROUP_NAME}  ${GROUP_PRIVILEGE}
    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    Should Contain  ${bmc_user_uris}  ${GROUP_NAME}
    Should Contain  ${bmc_user_uris}  ${GROUP_PRIVILEGE}



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


Create Group And Privilege
    [Documentation]  Create group and privilege for users.
    [Arguments]  ${user_group}  ${user_privilege}

    # Description of argument(s):
    # user_group  User group string.
    # user_privilege  User privilge string  like priv-admin, priv-user.

    @{ldap_parm_list}=  Create List
    ...  ${user_group}  ${user_privilege}

    ${data}=  Create Dictionary  data=@{ldap_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${BMC_USER_URI}ldap/action/Create  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
