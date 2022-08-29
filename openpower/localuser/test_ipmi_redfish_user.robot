*** Settings ***
Documentation    Test IPMI and Redfish combinations for user management.

Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot


*** Test Cases ***

Create IPMI User Without Any Privilege And Verify Via Redfish
    [Documentation]  Create user using IPMI without privilege and verify user privilege
    ...  via Redfish.
    [Tags]  Create_IPMI_User_Without_Any_Privilege_And_Verify_Via_Redfish
    [Setup]  Redfish.Login
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Delete Created User  ${random_userid}  AND  Redfish.Logout

    # Create IPMI user with random id and username.
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    ${random_username}=  Generate Random String  8  [LETTERS]
    Run IPMI Standard Command
    ...  user set name ${random_userid} ${random_username}

    # Verify new user privilege level via Redfish.
    ${privilege}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${random_username}  RoleId
    Valid Value  privilege  ['ReadOnly']

