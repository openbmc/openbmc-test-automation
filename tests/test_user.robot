*** Settings ***

Documentation       This suite is for testing Open BMC user account management.
...                 The randomness of the string generated is limited to the
...                 instance per test case however we end up running multiple
...                 test and multiple iteration. This creates scenario where
...                 the same previous user is generated.
...                 As a good pratice, clean up all the users at the end of
...                 test.

Resource            ../lib/rest_client.robot
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot

Library             OperatingSystem
Library             SSHLibrary
Library             String
Test Teardown       FFDC On Test Case Fail

Force Tags  User_Management

*** Variables ***
${RANDOM_STRING_LENGTH}    ${8}
${VALID_PASSWORD}          abc123
${NON_EXISTING_USER}       aaaaa

*** Test Cases ***

Create and delete user group
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is for testing user group creation
    ...                 and deletion in open bmc.\n
    [Tags]  Create_and_delete_user_group

    ${groupname}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${resp}=    Create UserGroup    ${groupname}
    Should Be Equal    ${resp}    ok
    ${usergroup_list}=    Get GroupListUsr
    Should Contain     ${usergroup_list}    ${groupname}
    ${resp}=    Delete Group    ${groupname}
    Should Be Equal    ${resp}    ok

Create and delete user without group name
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is for testing user creation with
    ...                 without groupname in open bmc.\n
    [Tags]              Create_and_delete_user_without_group_name

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${password}
    Should Be Equal    ${resp}    ok
    ${user_list}=    Get UserList
    Should Contain     ${user_list}    ${username}

    Login BMC    ${username}    ${password}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Delete User    ${username}
    Should Be Equal    ${resp}    ok

Create and delete user with user group name
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is for testing user creation with
    ...                 user name, password, comment and group name(user group)
    ...                 in open bmc.\n
    [Tags]              Create_and_delete_user_with_user_group_name

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${groupname}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create UserGroup    ${groupname}
    Should Be Equal    ${resp}    ok
    ${resp}=    Create User    ${comment}    ${username}    ${groupname}    ${password}
    Should Be Equal    ${resp}    ok
    ${user_list}=    Get UserList
    Should Contain     ${user_list}    ${username}

    Login BMC    ${username}    ${password}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Delete User    ${username}
    Should Be Equal    ${resp}    ok
    ${resp}=    Delete Group    ${groupname}
    Should Be Equal    ${resp}    ok

Create multiple users
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to verify that multiple users creation
    ...                 in open bmc.\n
    [Tags]              Create_multiple_users

    : FOR    ${INDEX}    IN RANGE    1    10
        \    Log    ${INDEX}
        \    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
        \    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
        \    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}
        \    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${password}
        \    Should Be Equal    ${resp}    ok
        \    ${user_list}=    Get UserList
        \    Should Contain     ${user_list}    ${username}
        \    Login BMC    ${username}    ${password}
        \    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
        \    Should Be Equal    ${rc}    ${0}

Create and delete user without password
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to create and delete a user without password
    ...                 in open bmc.\n
    [Tags]              Create_and_delete_user_without_password

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${groupname}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create UserGroup    ${groupname}
    Should Be Equal    ${resp}    ok
    ${resp}=    Create User    ${comment}    ${username}    ${groupname}    ${EMPTY}
    Should Be Equal    ${resp}    ok
    ${user_list}=    Get UserList
    Should Contain     ${user_list}    ${username}

    Login BMC    ${username}    ${EMPTY}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Delete User    ${username}
    Should Be Equal    ${resp}    ok
    ${resp}=    Delete Group    ${groupname}
    Should Be Equal    ${resp}    ok

Set password for existing user
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is for testing password set for user
    ...                 in open bmc.\n
    [Tags]              Set_password_for_existing_user

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${password}
    Should Be Equal    ${resp}    ok
    ${user_list}=    Get UserList
    Should Contain     ${user_list}    ${username}

    Login BMC    ${username}    ${password}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Change Password    ${username}    ${VALID_PASSWORD}
    Should Be Equal    ${resp}    ok

    Login BMC    ${username}    ${VALID_PASSWORD}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Delete User    ${username}
    Should Be Equal    ${resp}    ok

Set password with empty password for existing
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to verify that empty password can be set
    ...                 for a existing user.\n
    [Tags]              Set_password_with_empty_password_for_existing

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${password}
    Should Be Equal    ${resp}    ok
    ${user_list}=    Get UserList
    Should Contain     ${user_list}    ${username}

    Login BMC    ${username}    ${password}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

    ${resp}=    Change Password    ${username}    ${EMPTY}
    Should Be Equal    ${resp}    ok

    Login BMC    ${username}    ${EMPTY}
    ${rc}=    Execute Command    echo Login    return_stdout=False    return_rc=True
    Should Be Equal    ${rc}    ${0}

Set password for non existing user
    [Documentation]     ***BAD PATH***
    ...                 This testcase is for testing password set for non-existing user
    ...                 in open bmc.\n
    [Tags]              Set_password_for_non_existing_user

    ${resp}=    Change Password    ${NON_EXISTING_USER}    ${VALID_PASSWORD}
    Should Be Equal    ${resp}    error

Create existing user
    [Documentation]     ***BAD PATH***
    ...                 This testcase is for checking that user creation is not allowed
    ...                 for existing user in open bmc.\n
    [Tags]              Create_existing_user

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${EMPTY}
    Should Be Equal    ${resp}    ok
    ${resp}=    Create User    ${comment}    ${username}    ${EMPTY}    ${EMPTY}
    Should Be Equal    ${resp}    error

    ${resp}=    Delete User    ${username}
    Should Be Equal    ${resp}    ok

Create user with no name
    [Documentation]     ***BAD PATH***
    ...                 This testcase is for checking that user creation is not allowed
    ...                 with empty username in open bmc.\n
    [Tags]              Create_user_with_no_name

    ${username}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${password}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${comment}=    Generate Random String    ${RANDOM_STRING_LENGTH}
    ${groupname}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create User    ${comment}    ${EMPTY}    ${groupname}    ${password}
    Should Be Equal    ${resp}    error
    ${user_list}=    Get UserList
    Should Not Contain     ${user_list}    ${EMPTY}

Create existing user group
    [Documentation]     ***BAD PATH***
    ...                 This testcase is for checking that user group creation is not allowed
    ...                 for existing user group in open bmc.\n
    [Tags]              Create_existing_user_group

    ${groupname}=    Generate Random String    ${RANDOM_STRING_LENGTH}

    ${resp}=    Create UserGroup    ${groupname}
    Should Be Equal    ${resp}    ok
    ${resp}=    Create UserGroup    ${groupname}
    Should Be Equal    ${resp}    error

    ${resp}=    Delete Group    ${groupname}
    Should Be Equal    ${resp}    ok

Create user group with no name
    [Documentation]     ***BAD PATH***
    ...                 This testcase is for checking that user group creation is not allowed
    ...                 with empty groupname in open bmc.\n
    [Tags]              Create_user_group_with_no_name

    ${resp}=    Create UserGroup    ${EMPTY}
    Should Be Equal    ${resp}    error
    ${usergroup_list}=    Get GroupListUsr
    Should Not Contain    ${usergroup_list}    ${EMPTY}

Cleanup Users List
    [Documentation]     ***GOOD PATH***
    ...                 This testcase is to clean up multiple users created by
    ...                 the test so as to leave the system in cleaner state.
    ...                 This is a no-op if there is no user list on the BMC.
    [Tags]  Cleanup_Users_List

    ${user_list}=    Get UserList
    : FOR   ${username}   IN   @{user_list}
    \    ${resp}=    Delete User    ${username}
    \    Should Be Equal    ${resp}    ok


*** Keywords ***

Get UserList
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   OpenBMC Post Request
    ...   ${USER_MANAGER_URI}Users/action/UserList   data=${data}
    should be equal as strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['data']}

Get GroupListUsr
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   OpenBMC Post Request
    ...   ${USER_MANAGER_URI}/Groups/action/GroupListUsr   data=${data}
    should be equal as strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['data']}

Create User
    [Arguments]    ${comment}    ${username}    ${groupname}    ${password}
    @{user_list}=   Create List     ${comment}    ${username}    ${groupname}    ${password}
    ${data}=   create dictionary   data=@{user_list}
    ${resp}=   OpenBMC Post Request
    ...    ${USER_MANAGER_URI}Users/action/UserAdd      data=${data}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['status']}

Change Password
    [Arguments]    ${username}    ${password}
    @{user_list}=   Create List     ${username}    ${password}
    ${data}=   create dictionary   data=@{user_list}
    ${resp}=   OpenBMC Post Request
    ...    ${USER_MANAGER_URI}User/action/Passwd      data=${data}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['status']}

Create UserGroup
    [Arguments]    ${args}
    @{group_list}=   Create List     ${args}
    ${data}=   create dictionary   data=@{group_list}
    ${resp}=   OpenBMC Post Request
    ...    ${USER_MANAGER_URI}Groups/action/GroupAddUsr      data=${data}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['status']}

Delete Group
    [Arguments]    ${args}
    @{group_list}=   Create List     ${args}
    ${data}=   create dictionary   data=@{group_list}
    ${resp}=   OpenBMC Post Request
    ...    ${USER_MANAGER_URI}Group/action/GroupDel      data=${data}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['status']}

Delete User
    [Arguments]    ${args}
    @{user_list}=   Create List     ${args}
    ${data}=   create dictionary   data=@{user_list}
    ${resp}=   OpenBMC Post Request
    ...    ${USER_MANAGER_URI}User/action/Userdel      data=${data}
    ${jsondata}=    to json    ${resp.content}
    [Return]    ${jsondata['status']}

Login BMC
    [Arguments]    ${username}    ${password}
    Open connection     ${OPENBMC_HOST}
    ${resp}=   Login   ${username}    ${password}
    [Return]    ${resp}
