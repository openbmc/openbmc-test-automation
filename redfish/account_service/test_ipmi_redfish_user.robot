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

    Verify IPMI Username And Password  ${random_username}  ${valid_password}


Create User Using IPMI And Verify Login Via Redfish
    [Documentation]  Create user using IPMI and verify via Redfish.
    [Tags]  Create_User_Using_IPMI_And_Verify_Login_Via_Redfish

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Enable IPMI user
    Run IPMI Standard Command  user enable ${random_userid}

    # Set admin privilege and enable IPMI messaging for newly created user
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Verify user login using Redfish.
    Redfish.Login  ${random_username}  ${valid_password}


Update User Password Via IPMI And Verify Using Redfish
    [Documentation]  Update user password via IPMI and verify using Redfish.
    [Tags]  Update_User_Password_Via_IPMI_And_Verify_Using_Redfish

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    Set Test Variable  ${random_username}

    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Enable IPMI user
    Run IPMI Standard Command  user enable ${random_userid}

    # Set admin privilege and enable IPMI messaging for newly created user
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Update user password using IPMI.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password2}

    # Verify that user login works with new password using Redfish.
    Redfish.Login  ${random_username}  ${valid_password2}


Delete User Via IPMI And Verify Using Redfish
    [Documentation]  Delete user via IPMI and verify using Redfish.
    [Tags]  Delete_User_Via_IPMI_And_Verify_Using_Redfish

    # Create IPMI user.
    ${random_username}=  Generate Random String  8  [LETTERS]
    ${random_userid}=  Evaluate  random.randint(2, 15)  modules=random
    IPMI Create User  ${random_userid}  ${random_username}

    # Set valid password for newly created user.
    Run IPMI Standard Command
    ...  user set password ${random_userid} ${valid_password}

    # Enable IPMI user
    Run IPMI Standard Command  user enable ${random_userid}

    # Set admin privilege and enable IPMI messaging for newly created user
    Set Channel Access  ${random_userid}  ipmi=on privilege=${admin_level_priv}

    # Delete IPMI User and verify
    Run IPMI Standard Command  user set name ${random_userid} ""

    # Verify that Redfish login fails with deleted user.
    Run Keyword And Expect Error  *InvalidCredentialsError*
    ...  Redfish.Login  ${random_username}  ${valid_password}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    #FFDC On Test Case Fail
    # Delete the test user.
    Run Keyword And Ignore Error
    ...  Redfish.Delete  /redfish/v1/AccountService/Accounts/${random_username}

    Redfish.Logout
