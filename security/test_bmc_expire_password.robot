*** Settings ***
Documentation     Test root user expire password.

Resource          ../lib/resource.robot
Resource          ../gui/lib/resource.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/ipmi_client.robot
Library           ../lib/bmc_ssh_utils.py
Library           SSHLibrary

Suite Setup       Suite Setup Execution
Suite Teardown    Suite Teardown Execution

Test Teardown     Test Teardown Execution

*** Test Cases ***

Expire Root Password And Check IPMI Access Fails
    [Documentation]   Expire root user password and expect an error while access via IPMI.
    [Tags]  Expire_Root_Password_And_Check_IPMI_Access_Fails

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

    ${status}=  Run Keyword And Return Status   Run External IPMI Standard Command  lan print -v
    Should Be Equal  ${status}  ${False}


Expire Root Password And Check SSH Access Fails
    [Documentation]   Expire root user password and expect an error while access via SSH.
    [Tags]  Expire_Root_Password_And_Check_SSH_Access_Fails

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

    ${status}=  Run Keyword And Return Status
    ...  Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Should Be Equal  ${status}  ${False}


Expire And Change Root User Password And Access Via SSH
    [Documentation]   Expire and change root user password and access via SSH.
    [Tags]  Expire_Root_User_Password_And_Access_Via_SSH
    [Teardown]  Run Keywords  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Restore Default Password For Root User  AND  FFDC On Test Case Fail

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

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

   Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
   ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
   Should Contain  ${output}  password expiry information changed

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

   Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

   ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
   Should Contain  ${output}  password expiry information changed


   Redfish.Login
   Verify Root Password Expired
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

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

    Verify Root Password Expired
    Redfish.Login
    ${payload}=  Create Dictionary
    ...  UserName=admin_user  Password=TestPwd123  RoleId=Administrator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Expire And Change Root Password Via GUI
    [Documentation]  Expire and change root password via GUI.
    [Tags]  Expire_And_Change_Root_Password_Via_GUI
    [Setup]  Run Keywords  Launch Browser And Login OpenBMC GUI
    [Teardown]  Run Keywords  Logout And Close Browser
    ...  AND  Restore Default Password For Root User  AND  FFDC On Test Case Fail

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

    Click Button  ${xpath_button_user_action}
    Click Element  ${xpath_button_profile_settings}
    Page Should Contain  Change password
    Sleep  2s
    # Change valid password.
    Input Text  ${xpath_input_password}  0penBmc123
    Input Text  ${xpath_input_confirm_password}  0penBmc123
    Click Button  ${xpath_submit_button}

    # Verify valid password.
    Open Browser With URL  ${obmc_gui_url}
    Login OpenBMC GUI  ${OPENBMC_USERNAME}  0penBmc123
    Redfish.Login  ${OPENBMC_USERNAME}  0penBmc123


*** Keywords ***

Suite Setup Execution
   [Documentation]  Suite setup  execution.

   Redfish.login
   Redfish.Patch  /redfish/v1/AccountService/  body={"AccountLockoutThreshold": 0}
   Valid Length  OPENBMC_PASSWORD  min_length=8
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
    FFDC On Test Case Fail


Suite Teardown Execution
    [Documentation]  Do suite teardown task.

    Redfish.login
    Redfish.Patch  /redfish/v1/AccountService/  body={"AccountLockoutThreshold": 5}
    Redfish.Logout

Verify Root Password Expired
    [Documentation]  Checking whether root password expired or not.

    Create Session  openbmc  ${AUTH_URI}
    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${data}=  Create Dictionary  data=@{credentials}
    ${resp}=  Post Request  openbmc  /login  data=${data}  headers=${headers}
    ${json}=  To JSON  ${resp.content}
    Should Contain  ${json["extendedMessage"]}  POST the new password
