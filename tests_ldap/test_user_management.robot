*** Settings ***
Documentation   OpenBMC user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/utils.robot
Resource         ../lib/user_utils.robot
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
    [Teardown]  FFDC On Test Case Fail

    Create Group And Privilege  ${GROUP_NAME}  ${GROUP_PRIVILEGE}
    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    ${bmc_user_uris}=  Convert To String  ${bmc_user_uris}
    Should Contain  ${bmc_user_uris}  ${GROUP_NAME}
    Should Contain  ${bmc_user_uris}  ${GROUP_PRIVILEGE}
    Delete Defined LDAP Group And Privilege  ${GROUP_NAME}


Verify LDAP User With Privilege Admin Able To Power On
    [Documentation]  Verify LDAP user with privilege admin able to power on.
    [Tags]  Verify_LDAP_User_With_Privilege_Admin_Able_To_Power_On
    [Teardown]  FFDC On Test Case Fail

    Create Privilege  priv-admin
    Initialize OpenBMC  60  1  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    REST Power On  stack_mode=normal  quiet=1
    Delete Defined LDAP Group And Privilege  ${GROUP_NAME}


Verify LDAP User With Privilege Admin Able To Power Off
    [Documentation]  Verify LDAP user with privilege admin able to power off.
    [Tags]  Verify_LDAP_User_With_Privilege_Admin_Able_To_Power_Off
    [Teardown]  FFDC On Test Case Fail

    Create Privilege  priv-admin
    Initialize OpenBMC  60  1  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    REST Hard Power Off  stack_mode=normal  quiet=1
    Delete Defined LDAP Group And Privilege  ${GROUP_NAME}


Verify LDAP User With Privilege User Able To Read Inventory
    [Documentation]  Verify LDAP user with privilege usern able to read
    ...  inventory assettag.
    [Tags]  Verify_LDAP_User_With_Privilege_User_Able_To_Read_Inventory
    [Teardown]  FFDC On Test Case Fail

    Create Privilege  priv-user
    Initialize OpenBMC  60  1  ${LDAP_USER}  ${LDAP_USER_PASSWORD}
    Read Attribute  /xyz/openbmc_project/inventory/system  AssetTag
    Delete Defined LDAP Group And Privilege  ${GROUP_NAME}


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
    ...  msg=Updating the new root password failed, RC=${resp.status_code}.


Create Privilege
    [Documentation]  Create privilege as priv-admin.
    [Arguments]  ${user_privilege}

    Create Group And Privilege  ${GROUP_NAME}  ${user_privilege}
    ${bmc_user_uris}=  Read Properties  ${BMC_USER_URI}ldap/enumerate
    ${bmc_user_uris}=  Convert To String  ${bmc_user_uris}
    Should Contain  ${bmc_user_uris}  ${user_privilege}
    ...  msg=Could not create ${user_privilege} privilege.



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
