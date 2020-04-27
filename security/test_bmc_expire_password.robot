*** Settings ***
Documentation    Test root user expire password.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Library          ../lib/bmc_ssh_utils.py
Library          SSHLibrary

Suite Setup       Redfish.Login
Suite Teardown    Redfish.Logout

*** Variables ***


*** Test Cases ***
Expire And Change Root User Password Via Redfish And Verify
   [Documentation]   Expire and change root user password via Redfish and verify.
   [Tags]  Expire_And_Change_Root_User_Password_Via_Redfish_And_Verify
   [Teardown]  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...   body={'Password': '${OPENBMC_PASSWORD}'}

   SSHLibrary.Open Connection  ${OPENBMC_HOST}
   SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

   # User input password should be minimum 8 characters long.
   Valid Length  OPENBMC_PASSWORD  min_length=8

   ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
   Should Contain  ${output}  password expiry information changed

   # Change to a valid password.
   Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}  body={'Password': '0penBmc123'}
   Redfish.Logout
   # Verify login with the new password.
   Redfish.Login  ${OPENBMC_USERNAME}  0penBmc123
