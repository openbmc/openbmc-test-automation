*** Settings ***
Documentation       This suite tests IPMI user management in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/ipmi_utils.py

Test Teardown       Test Teardown Execution


*** Variables ***
${invalid_user_name}  user%

*** Test Cases ***

Test IPMI User Creation With Valid Name
    [Documentation]  Test IPMI user creation with valid name.
    [Tags]  Test_IPMI_User_Creation_With_Valid_Name

    ${random_name}=  Generate Random String  8  [LETTERS]
    ${random_id}=  Evaluate  random.randint(1, 15)  modules=random
    Create IPMI User  ${random_id}  ${random_name}
    Check If IPMI User Exits  ${random_id}  ${random_name}


Test IPMI User Creation With Invalid Name
    [Documentation]  Test IPMI user creation with invalid name(e.g. user name
    ...  with special charaters).
    [Tags]  Test_IPMI_User_Creation_With_Invalid_Name

    ${random_id}=  Evaluate  random.randint(1, 15)  modules=random
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_id} ${invalid_user_name}
    Should Contain  ${msg}  Invalid data


Test IPMI User Creation With Invalid ID
    [Documentation]  Test IPMI user creation with invalid ID(i.e any number
    ...  greater than 16).
    [Tags]  Test_IPMI_User_Creation_With_Invalid_ID

    ${random_invalid_id}=  Evaluate  random.randint(16, 1000)  modules=random
    ${msg}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  user set name ${random_invalid_id} newuser
    Should Contain  ${msg}  User ID is limited to range


*** Keywords ***

Create IPMI User
    [Documentation]  Create IPMI user with given id and name.
    [Arguments]  ${id}  ${name}
    # Description of argument(s):
    # id        ID of the user.
    # name      Name of the user.

    ${ipmi_cmd}=  Catenate  user set name ${id} ${name}
    ${resp}=  Run IPMI Standard Command  ${ipmi_cmd}

    
Check If IPMI User Exits
    [Documentation]  Check if given IPMI user exist or not.
    [Arguments]  ${id}  ${name}
    # Description of argument(s):
    # id        ID of the user.
    # name      Name of the user.

    ${output}=  Run IPMI Standard Command  user list
    @{lines}=  Split To Lines  ${output}
    ${user}=  Get From List  ${lines}  ${id}
    ${status}=  Run Keyword And Return Status  Should Contain  ${user}  ${name}
    [Return]  ${status}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
