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

Expire Root Password And Check IPMI Access Fails
    [Documentation]   Expire root user password and expect an error while access via IPMI.
    [Tags]  Expire_Root_Password_And_Check_IPMI_Access_Fails
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Wait Until Keyword Succeeds  1 min  10 sec
    ...  Restore Default Password For Root User

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

Restore Default Password For Root User
    [Documentation]  Restore default password for root user (i.e. 0penBmc).

    # Set default password for root user.
    ${result}=  Redfish.Patch  /redfish/v1/AccountService/Accounts/${OPENBMC_USERNAME}
    ...   body={'Password': '${OPENBMC_PASSWORD}'}
    # Verify that root user is able to run Redfish command using default password.
    Redfish.login 
