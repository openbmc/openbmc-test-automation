*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/ipmi_utils.py

Test Teardown       FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

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

    # Set invalid password for newly created user.
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set password ${random_userid} ""

    Should Contain  ${msg}  Invalid data field in request


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
