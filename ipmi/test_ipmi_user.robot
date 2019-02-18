*** Settings ***
Documentation       Test suite for OpenBMC IPMI user management.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             ../lib/ipmi_utils.py

Test Teardown       FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***
Verify IPMI User Deletion
    [Documentation]  Delete user via IPMI and verify.
    [Tags]  Verify_IPMI_User_Deletion

    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(1, 15)  modules=random
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
