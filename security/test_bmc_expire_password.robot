*** Settings ***
Documentation     Test root user expire password.

Resource          ../lib/resource.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/ipmi_client.robot
Library           ../lib/bmc_ssh_utils.py
Library           SSHLibrary

Test Setup        Test Setup Execution
Test Teardown     Test Teardown Execution

*** Test Cases ***

Expire Root Credential And IPMI Access Fail
    [Documentation]   Expire root user password and expect an error while access via IPMI.
    [Tags]  Expire_Root_Credential_And_IPMI_Access_Fail

    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${OPENBMC_USERNAME}
    Should Contain  ${output}  password expiry information changed

    ${status}=  Run Keyword And Return Status   Run External IPMI Standard Command  lan print -v
    Should Be Equal  ${status}  ${False}


*** Keywords ***

Test Setup Execution
   [Documentation]  Test setup  execution.

   Redfish.login
   Valid Length  OPENBMC_PASSWORD  min_length=8

Test Teardown Execution
   [Documentation]  Test teardown execution.

   Wait Until Keyword Succeeds  1 min  10 sec
   ...  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
   ...   body={'Password': '${OPENBMC_PASSWORD}'}

   SSHLibrary.Close Connection
   Redfish.Logout
