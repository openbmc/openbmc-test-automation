*** Settings ***
Documentation     Test root user expire password.

Resource          ../lib/resource.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/ipmi_client.robot
Library           ../lib/bmc_ssh_utils.py
Library           SSHLibrary

Suite Setup       Redfish.Login
Suite Teardown    Redfish.Logout

*** Variables ***


*** Test Cases ***

Expire Root User Password And Try To Access Via IPMI
   [Documentation]   Expire root user password and expect an error while access via IPMI.
   [Tags]  Expire_Root_User_Password_And_Try_To_Access_Via_IPMI
   [Setup]  Valid Length  OPENBMC_PASSWORD  min_length=8
   [Teardown]  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...   body={'Password': '${OPENBMC_PASSWORD}'}

   Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

   ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
   Should Contain  ${output}  password expiry information changed

   ${status}=  Run Keyword And Return Status   Run External IPMI Standard Command  lan print -v
   Should Be Equal  ${status}  ${False}

   SSHLibrary.Close Connection
