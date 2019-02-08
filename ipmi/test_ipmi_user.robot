*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/ipmi_utils.py

Test Teardown       FFDC On Test Case Fail


*** Variables ***

${invalid_user_name}    user%
${invalid_password}     abc123
${root_user_id}         1
${operator_level_priv}  0x3


*** Test Cases ***

Test IPMI User Creation With Valid Name And ID
    [Documentation]  Create IPMI user creation with valid name and ID and
    ...  verify.
    [Tags]  Test_IPMI_User_Creation_With_Valid_Name_And_ID

    ${random_name}=  Generate Random String  8  [LETTERS]
    ${random_id}=  Evaluate  random.randint(1, 15)  modules=random
    ${status}=  Create IPMI User  ${random_id}  ${random_name}
    Should Be Equal  '${status}'  'True'


Verify IPMI User Creation With Invalid Name
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  name(e.g. user name with special charaters).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_Name

    ${random_id}=  Evaluate  random.randint(1, 15)  modules=random
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_id} ${invalid_user_name}
    Should Contain  ${msg}  Invalid data


Verify IPMI User Creation With Invalid ID
    [Documentation]  Verify error while creating IPMI user with invalid
    ...  ID(i.e. any number greater than 16).
    [Tags]  Verify_IPMI_User_Creation_With_Invalid_ID

    ${random_invalid_id}=  Evaluate  random.randint(16, 1000)  modules=random
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_invalid_id} newuser
    Should Contain  ${msg}  User ID is limited to range


Verify Setting IPMI User With Invalid Password
    [Documentation]  Verify error while setting IPMI user with invalid
    ...  password.
    [Tags]  Verify_Setting_IPMI_User_With_Invalid_Password

    # Create IPMI user
    ${random_name}=  Generate Random String  8  [LETTERS]
    ${random_id}=  Evaluate  random.randint(1, 15)  modules=random
    Create IPMI User  ${random_id}  ${random_name}

    # Set invalid password for newly created user
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_id} ${invalid_password}

    Should Contain  ${msg}  Invalid data field in request


Verify Setting IPMI Root User With New Name
    [Documentation]  Verify error while setting IPMI root user with new
    ...  name.
    [Tags]  Verify_Setting_IPMI_Root_User_With_New_Name

    # Set invalid password for newly created user
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${root_user_id} abcd

    Should Contain  ${msg}  Set User Name command failed


Verify Setting IPMI Root User With New Privilege
    [Documentation]  Verify error while setting IPMI root user with new
    ...  privilege.
    [Tags]  Verify_Setting_IPMI_Root_User_With_New_Privilege

    # Set new privilege for root user
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user priv ${root_user_id} ${operator_level_priv}

    Should Contain  ${msg}  Set Privilege Level command failed


*** Keywords ***

Create IPMI User
    [Documentation]  Create IPMI user with given id and name.
    [Arguments]  ${id}  ${name}
    # Description of argument(s):
    # id        ID of the user.
    # name      Name of the user.

    ${ipmi_cmd}=  Catenate  user set name ${id} ${name}
    ${resp}=  Run IPMI Standard Command  ${ipmi_cmd}
    ${user_info}=  Get User Info  ${id}
    Should Be Equal  ${user_info['user_name']}  ${name}

    ${status}=  Run Keyword And Return Status  Should Be Equal
    ...  ${user_info['user_name']}  ${name}
    [Return]  ${status}
