*** Settings ***
Documentation    Test IPMI and Redfish combinations for user management.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Library          ../lib/ipmi_utils.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${valid_password}       0penBmc1
${valid_password2}      0penBmc2
${admin_level_priv}     4
${operator_level_priv}  3
${readonly_level_priv}  2
${ipmi_max_num_users}   ${15}
${max_num_users}        ${15}
${empty_name_pattern}   ^User Name\\s.*\\s:\\s$

** Test Cases **

Create Admin Redfish User And Verify Login Via IPMI
    [Documentation]  Create user using redfish and verify via IPMI.
    [Tags]  Create_Admin_Redfish_User_And_Verify_Login_Via_IPMI

    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Delay added for created new user password to get set.
    Sleep  5s

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Update User Password Via Redfish And Verify Using IPMI
    [Documentation]  Update user password via Redfish and verify using IPMI.
    [Tags]  Update_User_Password_Via_Redfish_And_Verify_Using_IPMI

    # Create user using Redfish.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Update user password using Redfish.
    ${payload}=  Create Dictionary  Password=${valid_password2}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    # Verify that IPMI command works with new password and fails with older password.
    Verify IPMI Username And Password  ${random_username}  ${valid_password2}

    Run Keyword And Expect Error  *Error: Unable to establish IPMI*
    ...  Verify IPMI Username And Password  ${random_username}  ${valid_password}


Update User Privilege Via Redfish And Verify Using IPMI
    [Documentation]  Update user privilege via Redfish and verify using IPMI.
    [Tags]  Update_User_Privilege_Via_Redfish_And_Verify_Using_IPMI

    # Create user using Redfish with admin privilege.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Update user privilege to operator using Redfish.
    ${payload}=  Create Dictionary  RoleId=Operator
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    # Verify new user privilege level via IPMI.
    ${resp}=  Run IPMI Standard Command  user list ${CHANNEL_NUMBER}

    # Example of response data:
    # ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
    # 1   root             false   true       true       ADMINISTRATOR
    # 2   OAvCxjMv         false   true       true       OPERATOR
    # 3                    true    false      false      NO ACCESS
    # ..
    # ..
    # 15                   true    false      false      NO ACCESS

    ${user_info}=
    ...  Get Lines Containing String  ${resp}  ${random_username}
    Should Contain  ${user_info}  OPERATOR


Delete User Via Redfish And Verify Using IPMI
    [Documentation]  Delete user via redfish and verify using IPMI.
    [Tags]  Delete_User_Via_Redfish_And_Verify_Using_IPMI

    # Create user using Redfish.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Delete user using Redfish.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    # Verify that IPMI command fails with deleted user.
    Run Keyword And Expect Error  *Error: Unable to establish IPMI*
    ...  Verify IPMI Username And Password  ${random_username}  ${valid_password}


Create IPMI User And Verify Login Via Redfish
    [Documentation]  Create user using IPMI and verify user login via Redfish.
    [Tags]  Create_IPMI_User_And_Verify_Login_Via_Redfish

    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}  ${admin_level_priv}

    Redfish.Logout

    # Verify user login using Redfish.
    Redfish.Login  ${username}  ${valid_password}
    Redfish.Logout

    Redfish.Login


Update User Password Via IPMI And Verify Using Redfish
    [Documentation]  Update user password using IPMI and verify user
    ...  login via Redfish.
    [Tags]  Update_User_Password_Via_IPMI_And_Verify_Using_Redfish

    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}  ${admin_level_priv}

    # Update user password using IPMI.
    Run IPMI Standard Command
    ...  user set password ${userid} ${valid_password2}

    Redfish.Logout

    # Verify that user login works with new password using Redfish.
    Redfish.Login  ${username}  ${valid_password2}
    Redfish.Logout

    Redfish.Login


Update User Privilege To Operator Via IPMI And Verify Using Redfish
    [Documentation]  Update user privilege to operator via IPMI and verify using Redfish.
    [Tags]  Update_User_Privilege_To_Operator_Via_IPMI_And_Verify_Using_Redfish
    # Create user using IPMI with admin privilege.
    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}  ${admin_level_priv}

    # Change user privilege to opetrator using IPMI.
    Run IPMI Standard Command
    ...  user priv ${userid} ${operator_level_priv} ${CHANNEL_NUMBER}

    # Verify new user privilege level via Redfish.
    ${privilege}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${privilege}  Operator


Update User Privilege To Readonly Via IPMI And Verify Using Redfish
    [Documentation]  Update user privilege to readonly via IPMI and verify using Redfish.
    [Tags]  Update_User_Privilege_To_Readonly_Via_IPMI_And_Verify_Using_Redfish

    # Create user using IPMI with admin privilege.
    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}  ${admin_level_priv}

    # Change user privilege to readonly using IPMI.
    Run IPMI Standard Command
    ...  user priv ${userid} ${readonly_level_priv} ${CHANNEL_NUMBER}

    # Verify new user privilege level via Redfish.
    ${privilege}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${privilege}  ReadOnly


Delete User Via IPMI And Verify Using Redfish
    [Documentation]  Delete user using IPMI and verify error while doing
    ...  user login with deleted user via Redfish.
    [Tags]  Delete_User_Via_IPMI_And_Verify_Using_Redfish

    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}  ${admin_level_priv}

    # Delete IPMI User.
    Run IPMI Standard Command  user set name ${userid} ""

    # Verify that Redfish login fails with deleted user.
    Run Keyword And Expect Error  *InvalidCredentialsError*
    ...  Redfish.Login  ${username}  ${valid_password}


Verify Failure To Exceed Max Number Of Users
    [Documentation]  Verify failure attempting to exceed the max number of user accounts.
    [Tags]  Verify_Failure_To_Exceed_Max_Number_Of_Users
    [Teardown]  Run Keywords  Test Teardown Execution
    ...         AND  Delete Users Via Redfish  ${username_list}

    # Get existing user count.
    ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/
    ${current_user_count}=  Get From Dictionary  ${resp.dict}  Members@odata.count

    ${payload}=  Create Dictionary  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}

    @{username_list}=  Create List

    # Create users to reach maximum users count (i.e. 15 users).
    FOR  ${INDEX}  IN RANGE  ${current_user_count}  ${max_num_users}
      ${random_username}=  Generate Random String  8  [LETTERS]
      Set To Dictionary  ${payload}  UserName  ${random_username}
      Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
      ...  valid_status_codes=[${HTTP_CREATED}]
      Append To List  ${username_list}  /redfish/v1/AccountService/Accounts/${random_username}
    END

    # Verify error while creating 16th user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set To Dictionary  ${payload}  UserName  ${random_username}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]


Create IPMI User Without Any Privilege And Verify Via Redfish
    [Documentation]  Create user using IPMI without privilege and verify via redfish.
    [Tags]  Create_IPMI_User_Without_Any_Privilege_And_Verify_Via_Redfish

    ${username}  ${userid}=  IPMI Create Random User Plus Password And Privilege
    ...  ${valid_password}

    # Verify new user privilege level via Redfish.
    ${privilege}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Valid Value  privilege  ['ReadOnly']

*** Keywords ***

IPMI Create Random User Plus Password And Privilege
    [Documentation]  Create random IPMI user with given password and privilege
    ...  level.
    [Arguments]  ${password}  ${privilege}=0

    # Description of argument(s):
    # password      Password to be assigned for the user.
    # privilege     Privilege level for the user (e.g. "1", "2", "3", etc.).

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Suite Variable  ${random_username}

    ${random_userid}=  Find Free User Id
    IPMI Create User  ${random_userid}  ${random_username}

    # Set given password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${password}

    # Enable IPMI user.
    Run IPMI Standard Command  user enable ${random_userid}

    # Set given privilege and enable IPMI messaging for newly created user.
    IF  '${privilege}' != '0'
        Set Channel Access  ${random_userid}  ipmi=on privilege=${privilege}
    END

    RETURN  ${random_username}  ${random_userid}


Delete Users Via Redfish
    [Documentation]  Delete all the users via redfish from given list.
    [Arguments]  ${user_list}

    # Description of argument(s):
    # user_list    List of user which are to be deleted.

    Redfish.Login

    FOR  ${user}  IN  @{user_list}
      Redfish.Delete  ${user}
    END

    Redfish.Logout


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    # Delete the test user.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    Redfish.Logout


Find Free User Id
    [Documentation]  Find a userid that is not being used.
    FOR    ${jj}    IN RANGE    300
        # IPMI maximum users count (i.e. 15 users).
        ${random_userid}=  Evaluate  random.randint(1, ${ipmi_max_num_users})  modules=random
        ${access}=  Run IPMI Standard Command  channel getaccess ${CHANNEL_NUMBER} ${random_userid}

        ${name_line}=  Get Lines Containing String  ${access}  User Name
        Log To Console  For ID ${random_userid}: ${name_line}
        ${is_empty}=  Run Keyword And Return Status
        ...  Should Match Regexp  ${name_line}  ${empty_name_pattern}

        IF  ${is_empty} == ${True}  BREAK
    END
    IF  '${jj}' == '299'  Fail  msg=A free user ID could not be found.
    RETURN  ${random_userid}
