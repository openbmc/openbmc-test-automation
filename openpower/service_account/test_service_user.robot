*** Settings ***
Documentation    This suite is to test service user functionality via Redfish.

Resource         ../../lib/connection_client.robot 
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify service user availability
    [Documentation]  Verify service user avalability.

    # Verify that service user has administrator privilege.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/service  RoleId

    Should Be Equal  Administrator  ${role_config}


Verify Service Cannot Not Be Created
    [Documentation]  Verify that sevice account cannot be created

    ${payload}=  Create Dictionary
    ...  UserName=service Password=TestPwd1  RoleId=Operator  Enabled=${True}
    ${returnVal}=   Run Keyword And Return Status  Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    Should Be True  ${returnVal} == False


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
