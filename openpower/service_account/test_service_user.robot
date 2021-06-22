*** Settings ***
Documentation    This suite is to test service user functionality via Redfish.

Resource         ../lib/connection_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_redfish_utils.robot

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


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
