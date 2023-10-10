*** Settings ***
Documentation    Test IPMI and Redfish combinations for user management.

Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Library          ../../lib/ipmi_utils.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Force Tags       IPMI_Redfish_User

*** Variables ***

${valid_password}       0penBmc1
${valid_password2}      0penBmc2


*** Test Cases ***

Create IPMI User Without Any Privilege And Verify Via Redfish
    [Documentation]  Create user using IPMI without privilege and verify user privilege
    ...  via Redfish.
    [Tags]  Create_IPMI_User_Without_Any_Privilege_And_Verify_Via_Redfish

    # Create IPMI user with random id and username.
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    ${random_username}=  Generate Random String  8  [LETTERS]
    Run IPMI Standard Command
    ...  user set name ${random_userid} ${random_username}

    # Verify new user privilege level via Redfish.
    ${privilege}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${random_username}  RoleId
    Valid Value  privilege  ['ReadOnly']


Create Admin User Via Redfish And Verify Login Via IPMI
    [Documentation]  Create user via redfish and verify via IPMI.
    [Tags]  Create_Admin_User_Via_Redfish_And_Verify_Login_Via_IPMI

    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${payload}=  Create Dictionary
    ...  UserName=${random_username}  Password=${valid_password}
    ...  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Add delay for a new admin user password to set.
    Sleep  5s

    Enable IPMI Access To User Using Redfish  ${random_username}

    # Update user password using Redfish.
    ${payload}=  Create Dictionary  Password=${valid_password2}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    Verify IPMI Username And Password  ${random_username}  ${valid_password2}


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

    Enable IPMI Access To User Using Redfish  ${random_username}

    # Update user password using Redfish.
    ${payload}=  Create Dictionary  Password=${valid_password2}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    # Delete user using Redfish.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    # Verify that IPMI command fails with deleted user.
    Run Keyword And Expect Error  *Error: Unable to establish IPMI*
    ...  Verify IPMI Username And Password  ${random_username}  ${valid_password2}


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

    Enable IPMI Access To User Using Redfish  ${random_username}

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

    Enable IPMI Access To User Using Redfish  ${random_username}

    # Update user password using Redfish.
    ${payload}=  Create Dictionary  Password=${valid_password2}
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    # Update user privilege to readonly using Redfish.
    ${payload}=  Create Dictionary  RoleId=ReadOnly
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${random_username}  body=&{payload}

    # Verify new user privilege level via IPMI.
    ${resp}=  Run IPMI Standard Command  user list

    # Example of response data:
    # ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
    # 1   ipmi_admin       false   true       true       ADMINISTRATOR
    # 2   OAvCxjMv         false   true       true       USER
    # 3                    true    false      false      NO ACCESS
    # ..
    # ..
    # 15                   true    false      false      NO ACCESS

    ${user_info}=
    ...  Get Lines Containing String  ${resp}  ${random_username}
    Should Contain  ${user_info}  USER


*** Keywords ***

Create IPMI Random User With Password And Privilege
    [Documentation]  Create random IPMI user with given password and privilege
    ...  level.
    [Arguments]  ${password}  ${privilege}=0

    # Description of argument(s):
    # password      Password to be assigned for the user.
    # privilege     Privilege level for the user (e.g. "1", "2", "3", etc.).

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Suite Variable  ${random_username}

    ${random_userid}=  Find And Return Free User Id
    IPMI Create User  ${random_userid}  ${random_username}

    # Set given password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${password}

    # Enable IPMI user.
    Run IPMI Standard Command  user enable ${random_userid}

    # Set given privilege and enable IPMI messaging for newly created user.
    Run Keyword If  '${privilege}' != '0'
    ...  Set Channel Access  ${random_userid}  ipmi=on privilege=${privilege}

    [Return]  ${random_username}  ${random_userid}


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


Enable IPMI Access To User Using Redfish
    [Documentation]  Add IPMI access to a user through Redfish.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  User name to which IPMI access is to be added.

    # Adding IPMI access to user name.
    Redfish.Patch    /redfish/v1/AccountService/Accounts/${user_name}
    ...  body={"AccountTypes": ["Redfish", "HostConsole", "ManagerConsole", "WebUI", "IPMI"]}


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


Find And Return Free User Id
    [Documentation]  Find and return userid that is not being used.

    FOR    ${index}    IN RANGE    300
        # IPMI maximum users count (i.e. 15 users).
        ${random_userid}=  Evaluate  random.randint(1, ${ipmi_max_num_users})  modules=random
        ${access_output}=  Run IPMI Standard Command  channel getaccess 1 ${random_userid}

        ${name_line}=  Get Lines Containing String  ${access_output}  User Name
        Log To Console  For ID ${random_userid}: ${name_line}
        ${is_empty}=  Run Keyword And Return Status
        ...  Should Match Regexp  ${name_line}  ${empty_name_pattern}

        Exit For Loop If  ${is_empty} == ${True}
    END
    Run Keyword If  '${index}' == '299'  Fail  msg=A free user ID could not be found.
    [Return]  ${random_userid}

