*** Settings ***
Documentation    Test root user expire password.

Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot
Library          SSHLibrary

Test Setup       Redfish.Login
Test Teardown    Redfish.Logout

*** Variables ***


*** Test Cases ***
Change Root User Password Via Redfish And Verify
   [Documentation]   Change root user password via Redfish and verify.
   [Tags]  Change_Root_User_Password_Via_Redfish_And_Verify
   [Teardown]  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...   body={'Password': '${OPENBMC_PASSWORD}'}

   SSHLibrary.Open Connection  ${OPENBMC_HOST}
   SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
   ${output}=  SSHLibrary.Execute Command  passwd --expire ${OPENBMC_USERNAME}

   # Change to a valid password.
   Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}  body={'Password': '0penBmc123'}
   Redfish.Logout
   # Verify login with the new password.
   Redfish.Login  ${OPENBMC_USERNAME}  0penBmc123
