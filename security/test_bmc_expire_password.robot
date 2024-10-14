*** Settings ***
Documentation     Test root user expire password.

Resource          ../lib/resource.robot
Resource          ../gui/lib/gui_resource.robot
Resource          ../lib/ipmi_client.robot
Resource          ../lib/bmc_redfish_utils.robot
Library           ../lib/bmc_ssh_utils.py
Library           SSHLibrary

Test Setup       Set Account Lockout Threshold

Test Tags       BMC_Expire_Password

*** Variables ***

# If user re-tries more than 5 time incorrectly, the user gets locked for 5 minutes.
${default_lockout_duration}   ${300}
${admin_user}                 admin_user
${default_adminuser_passwd}   AdminUser1
${admin_password}             AdminUser2
${invalid_password}           abcd12345


*** Test Cases ***

Expire Root Password And Check IPMI Access Fails
    [Documentation]   Expire root user password and expect an error while access via IPMI.
    [Tags]  Expire_Root_Password_And_Check_IPMI_Access_Fails
    [Teardown]  Test Teardown Execution

    Expire Password  ${OPENBMC_USERNAME}

    ${status}=  Run Keyword And Return Status   Run External IPMI Standard Command  lan print -v
    Should Be Equal  ${status}  ${False}


Expire Root Password And Check SSH Access Fails
    [Documentation]   Expire root user password and expect an error while access via SSH.
    [Tags]  Expire_Root_Password_And_Check_SSH_Access_Fails
    [Teardown]  Test Teardown Execution

    Expire Password  ${OPENBMC_USERNAME}

    ${status}=  Run Keyword And Return Status
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Should Be Equal  ${status}  ${False}


Expire And Change Root User Password And Access Via SSH
    [Documentation]   Expire and change root user password and access via SSH.
    [Tags]  Expire_And_Change_Root_User_Password_And_Access_Via_SSH
    [Teardown]  Run Keywords  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Restore Default Password For Root User  AND  FFDC On Test Case Fail

    Expire Password  ${OPENBMC_USERNAME}

    Redfish.Login
    # Change to a valid password.
    ${resp}=  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
    ...  body={'Password': '0penBmc123'}  valid_status_codes=[${HTTP_OK}]

    # Verify login with the new password through SSH.
    Open Connection And Log In  ${OPENBMC_USERNAME}  0penBmc123


Expire Root Password And Update Bad Password Length Via Redfish
   [Documentation]  Expire root password and update bad password via Redfish and expect an error.
   [Tags]  Expire_Root_Password_And_Update_Bad_Password_Length_Via_Redfish
   [Teardown]  Run Keywords  Wait Until Keyword Succeeds  1 min  10 sec
   ...  Restore Default Password For Root User  AND  FFDC On Test Case Fail

   Expire Password  ${OPENBMC_USERNAME}

   Redfish.Login
   ${status}=  Run Keyword And Return Status
   ...  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...  body={'Password': '0penBmc0penBmc0penBmc'}
   Should Be Equal  ${status}  ${False}


Expire And Change Root User Password Via Redfish And Verify
   [Documentation]   Expire and change root user password via Redfish and verify.
   [Tags]  Expire_And_Change_Root_User_Password_Via_Redfish_And_Verify
   [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
   ...  Wait Until Keyword Succeeds  1 min  10 sec
   ...  Restore Default Password For Root User

   Expire Password  ${OPENBMC_USERNAME}

   Verify User Password Expired Using Redfish  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
   # Change to a valid password.
   Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...  body={'Password': '0penBmc123'}
   Redfish.Logout

   # Verify login with the new password.
   Redfish.Login  ${OPENBMC_USERNAME}  0penBmc123


Verify Error While Creating User With Expired Password
    [Documentation]  Expire root password and expect an error while creating new user.
    [Tags]  Verify_Error_While_Creating_User_With_Expired_Password
    [Teardown]  Run Keywords  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Restore Default Password For Root User  AND  FFDC On Test Case Fail

    Expire Password  ${OPENBMC_USERNAME}

    Verify User Password Expired Using Redfish  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Redfish.Login
    ${payload}=  Create Dictionary
    ...  UserName=admin_user  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Expire And Change Root Password Via GUI
    [Documentation]  Expire and change root password via GUI.
    [Tags]  Expire_And_Change_Root_Password_Via_GUI
    [Setup]  Launch Browser And Login GUI
    [Teardown]  Run Keywords  Logout GUI  AND  Close Browser
    ...  AND  Restore Default Password For Root User  AND  FFDC On Test Case Fail

    Expire Password  ${OPENBMC_USERNAME}

    Wait Until Page Contains Element  ${xpath_root_button_menu}
    Click Element  ${xpath_root_button_menu}
    Click Element  ${xpath_profile_settings}
    Wait Until Page Contains  Change password

    # Change valid password.
    Input Text  ${xpath_input_password}  0penBmc123
    Input Text  ${xpath_input_confirm_password}  0penBmc123
    Click Button  ${xpath_profile_save_button}
    Wait Until Page Contains  Successfully saved account settings.
    Wait Until Page Does Not Contain  Successfully saved account settings.  timeout=20
    Logout GUI

    # Verify valid password.
    Login GUI  ${OPENBMC_USERNAME}  0penBmc123
    Redfish.Login  ${OPENBMC_USERNAME}  0penBmc123


Verify Maximum Failed Attempts And Check Root User Account Locked
    [Documentation]  Verify maximum failed attempts and locks out root user account.
    [Tags]  Verify_Maximum_Failed_Attempts_And_Check_Root_User_Account_Locked
    [Setup]   Set Account Lockout Threshold  account_lockout_threshold=${5}

    # Make maximum failed login attempts.
    Repeat Keyword  ${5} times
    ...  Run Keyword And Expect Error  InvalidCredentialsError*  Redfish.Login  root  0penBmc123

    # Verify that legitimate login fails due to lockout.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    # Wait for lockout duration to expire and then verify that login works.
    Sleep  ${default_lockout_duration}s
    Redfish.Login
    Redfish.Logout

Verify New Password Persistency After BMC Reboot
    [Documentation]  Verify new password persistency after BMC reboot.
    [Tags]  Verify_New_Password_Persistency_After_BMC_Reboot
    [Teardown]  Test Teardown Execution

    Redfish.Login

    # Make sure the user account in question does not already exist.
    Redfish.Delete  /redfish/v1/AccountService/Accounts/admin_user
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=admin_user  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]
    Redfish.Logout

    Redfish.Login  admin_user  TestPwd123

    # Change to a valid password.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/admin_user
    ...  body={'Password': '0penBmc123'}

    # Reboot BMC and verify persistency.
    Redfish OBMC Reboot (off)

    # verify new password
    Redfish.Login  admin_user  0penBmc123


Verify Expire And Change Admin User Password Via GUI
    [Documentation]  Force expire admin password and update admin password via GUI.
    [Tags]  Verify_Expire_And_Change_Admin_User_Password_Via_GUI
    [Setup]  Run Keywords  Launch Browser And Login GUI  AND
    ...  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}
    [Teardown]  Run Keywords  Logout GUI  AND  Close Browser

    Expire Password  ${admin_user}

    Logout GUI

    # Verify that admin user should not be able to login with expired password.
    Login GUI  ${admin_user}  ${default_adminuser_passwd}

    # Verify error message to update the password.
    Wait Until Page Contains  The password is expired and must be changed.  timeout=10

    # Update a valid acceptable password.
    Input Text  ${xpath_input_password}  ${admin_password}
    Input Text  ${xpath_input_confirm_password}  ${admin_password}
    Click Button  ${xpath_confirm_password_button}
    Wait Until Page Contains  Overview  timeout=20

    # Verify valid password.
    Redfish.Login  ${admin_user}  ${admin_password}


Expire Admin Password And Check IPMI Access Fails
    [Documentation]   Expire admin user password and expect an error while access via IPMI.
    [Tags]  Expire_Admin_Password_And_Check_IPMI_Access_Fails
    [Setup]  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}

    Expire Password  ${admin_user}

    ${status}=  Run Keyword And Return Status   Run External IPMI Standard Command  lan print -v
    Should Be Equal  ${status}  ${False}


Verify Expire Admin Password And Update Bad Password Length Via Redfish
   [Documentation]  Expire admin password and update bad password with more than 20 characters
   ...  via Redfish and expect an error.
   [Tags]  Verify_Expire_Admin_Password_And_Update_Bad_Password_Length_Via_Redfish
   [Setup]  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}

   Expire Password  ${admin_user}

   Redfish.Login

   Set Password Via Redfish  0penBmc0penBmc0penBmc  ${False}


Verify Error While Creating User With Expired Admin Password
    [Documentation]  Expire admin password and expect an error while creating new user.
    [Tags]  Verify_Error_While_Creating_User_With_Expired_Admin_Password
    [Teardown]  Restore Default Password For Admin User

    Expire Password  ${admin_user}

    Verify User Password Expired Using Redfish  ${admin_user}  ${default_adminuser_passwd}

    # Create new user with expired admin password and expect an error.
    ${payload}=  Create Dictionary
    ...  UserName=admin_user1  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify New Admin Password Persistency After BMC Reboot
    [Documentation]  Verify new admin password persistency after BMC reboot.
    [Tags]  Verify_New_Admin_Password_Persistency_After_BMC_Reboot
    [Setup]  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}
    [Teardown]  Restore Default Password For Admin User

    Expire Password  ${admin_user}

    Set Password Via Redfish  ${admin_password}  ${True}

    # Reboot BMC.
    Redfish OBMC Reboot (off)  stack_mode=skip

    # Verify password is persisted after bmc reboot.
    Redfish.Login  ${admin_user}  ${admin_password}


Expire And Change Admin User Password Via Redfish And Verify
   [Documentation]   Expire and change admin user password via Redfish and verify.
   [Tags]  Expire_And_Change_Admin_User_Password_Via_Redfish_And_Verify
   [Setup]  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}
   [Teardown]  Restore Default Password For Admin User

   Expire Password  ${admin_user}

   Verify User Password Expired Using Redfish  ${admin_user}  ${default_adminuser_passwd}

   # Change to a valid password.
   Set Password Via Redfish  AdminUser2  ${True}
   Redfish.Logout

   # Verify login with the new password.
   Redfish.Login  ${admin_user}  AdminUser2


Verify Maximum Failed Attempts For Admin User And Check Account Locked
    [Documentation]  Verify maximum failed attempts for admin user
    ...  and check whether admin user account is locked.
    [Tags]  Verify_Maximum_Failed_Attempts_For_Admin_User_And_Check_Account_Locked
    [Setup]  Run Keywords
    ...  Redfish Create User  ${admin_user}  ${default_adminuser_passwd}  Administrator  ${True}
    ...  AND  Set Account Lockout Threshold  account_lockout_threshold=${5}

    # Make maximum failed login attempts.
    Repeat Keyword  ${5} times
    ...  Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${admin_user}  ${invalid_password}

    # Verify that login fails with admin user due to lockout.
    Run Keyword And Expect Error  InvalidCredentialsError*
    ...  Redfish.Login  ${admin_user}  ${default_adminuser_passwd}

    # Wait for lockout duration to expire and then verify that login with admin user works.
    Sleep  ${default_lockout_duration}s
    Redfish.Login  ${admin_user}  ${default_adminuser_passwd}
    Redfish.Logout


*** Keywords ***

Set Account Lockout Threshold
   [Documentation]  Set user account lockout threshold.
   [Arguments]  ${account_lockout_threshold}=${0}  ${account_lockout_duration}=${50}

   # Description of argument(s):
   # account_lockout_threshold    Set lockout threshold value.
   # account_lockout_duration     Set lockout duration value.

   Redfish.login
   ${payload}=  Create Dictionary  AccountLockoutThreshold=${account_lockout_threshold}
   ...  AccountLockoutDuration=${account_lockout_duration}
   Redfish.Patch  /redfish/v1/AccountService/  body=&{payload}
   gen_robot_valid.Valid Length  OPENBMC_PASSWORD  min_length=8
   Redfish.Logout

Restore Default Password For Root User
    [Documentation]  Restore default password for root user (i.e. 0penBmc).

    # Set default password for root user.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
    ...   body={'Password': '${OPENBMC_PASSWORD}'}  valid_status_codes=[${HTTP_OK}]
    # Verify that root user is able to run Redfish command using default password.
    Redfish.Logout


Test Teardown Execution
    [Documentation]  Do test teardown task.

    Redfish.Login
    Wait Until Keyword Succeeds  1 min  10 sec  Restore Default Password For Root User
    Redfish.Logout
    Set Account Lockout Threshold  account_lockout_threshold=${5}
    FFDC On Test Case Fail


Expire Password
    [Documentation]  Force expire password.
    [Arguments]  ${username}

    # Description of argument(s):
    # username                       User to be created and expire.

    # Expire the password.
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${username}
    Should Contain Any  ${output}  password expiry information changed  password changed

    # Example output:
    # passwd --expire admin
    # passwd: password changed.

    Close All Connections


Restore Default Password For Admin User
    [Documentation]  Restore default password for admin user (i.e. AdminUser1).

    # Set default password for admin user.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${admin_user}
    ...   body={'Password': '${default_adminuser_passwd}'}  valid_status_codes=[${HTTP_OK}]
    # Verify that admin user is able to run Redfish command using default password.
    Redfish.Logout


Set Password Via Redfish
    [Documentation]  Set new password via redfish.
    [Arguments]  ${new_password}  ${expect_result}

    # Description of argument(s):
    # new_password        New password set.
    # expect_result       Expected result (eg:true or false).

    ${status}= Run Keyword And Return Status
    ... Redfish.Patch /redfish/v1/AccountService/Accounts/${admin_user}
    ... body={'Password': '${new_password}'}

    Should be Equal  ${status}  ${expect_result}
