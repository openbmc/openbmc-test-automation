*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/ipmi_utils.py

Test Teardown       Test Teardown Execution


*** Variables ***

${invalid_username}     user%
${invalid_password}     abc123
${root_userid}          1
${operator_level_priv}  0x3
${valid_password}       0penBmc1
${max_password_length}  20


*** Test Cases ***

Verify IPMI User Creation With Valid Name And ID
    [Documentation]  Create user via IPMI and verify.
    [Tags]  Test_IPMI_User_Creation_With_Valid_Name_And_ID

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(1, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}


Verify IPMI User Creation With Invalid Name
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  name(e.g. user name with special characters).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_Name

    ${random_userid}=  Evaluate  random.randint(1, 15)  modules=random
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_userid} ${invalid_username}
    Should Contain  ${msg}  Invalid data


Verify IPMI User Creation With Invalid ID
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  ID(i.e. any number greater than 15 or 0).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_ID

    @{id_list}=  Create List
    ${random_invalid_id}=  Evaluate  random.randint(16, 1000)  modules=random
    Append To List  ${id_list}  ${random_invalid_id}
    Append To List  ${id_list}  0

    :FOR  ${id}  IN  @{id_list}
    \    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    \    ...  user set name ${id} newuser
    \    Should Contain  ${msg}  User ID is limited to range


Verify Setting IPMI User With Invalid Password
    [Documentation]  Verify error while setting IPMI user with invalid
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Invalid_Password

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(1, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ${invalid_password}

    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI Root User With New Name
    [Documentation]  Verify error while setting IPMI root user with new
    ...  name.
    [Tags]  Verify_Setting_IPMI_Root_User_With_New_Name

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${root_userid} abcd

    Should Contain  ${msg}  Set User Name command failed


Verify IPMI User Password Via Test Command
    [Documentation]  Verify IPMI user password using test command.
    [Tags]  Verify_IPMI_User_Password_Via_Test_Command

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}


    # Verify newly set password using test command
    ${msg}=  Run IPMI Standard Command
    ...  user test ${random_userid} ${max_password_length} ${valid_password}

    Should Contain  ${msg}  Success


Verify IPMI User Creation With Same Name
    [Documentation]  Verify error while creating two IPMI user with same name.
    [Tags]  Verify_IPMI_User_Creation_With_Same_Name

    ${random_username}=  Generate Random String  8  [LETTERS]
    IPMI Create User  2  ${random_username}

    # Set same username for another IPMI user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name 3 ${random_username}
    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI User With Null Password
    [Documentation]  Verify error while setting IPMI user with null
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Null_Password

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(1, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set null password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ""

    Should Contain  ${msg}  Invalid data field in request


Verify IPMI User Deletion
    [Documentation]  Delete user via IPMI and verify.
    [Tags]  Verify_IPMI_User_Deletion

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Delete IPMI User and verify
    Run IPMI Standard Command  user set name ${random_userid} ""
    Should Be Equal  ${user_info['user_name']}  ${EMPTY}



*** Keywords ***

IPMI Create User
    [Documentation]  Create IPMI user with given userid and username.
    [Arguments]  ${userid}  ${username}

    # Description of argument(s):
    # userid      The user ID (e.g. "1", "2", etc.).
    # username    The user name (e.g. "root", "robert", etc.).

    ${ipmi_cmd}=  Catenate  user set name ${userid} ${username}
    ${resp}=  Run IPMI Standard Command  ${ipmi_cmd}
    ${user_info}=  Get User Info  ${userid}
    Should Be Equal  ${user_info['user_name']}  ${username}


Delete All Non Root IPMI User
    [Documentation]  Delete all non-root IPMI user.

    :FOR  ${userid}  IN RANGE  2  16
    \  ${user_info}=  Get User Info  ${userid}
    \  Run Keyword If  "${user_info['user_name']}" != ""
    ...  Run IPMI Standard Command  user set name ${userid} ""


Test Teardown Execution
    [Documentation]  Do the test teardown execution.

    FFDC On Test Case Fail
    Delete All Non Root IPMI User

