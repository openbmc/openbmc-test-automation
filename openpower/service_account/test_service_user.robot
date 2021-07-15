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
    [Tags]  Verify_service_user_availability

    # Verify that service user has administrator privilege.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/service  RoleId

    Should Be Equal  Administrator  ${role_config}


Verify Creating User With Service Username
    [Documentation]  Verify that user with service username can not be created.
    [Tags]  Verify_Creatig_User_With_Service_Username

    ${payload}=  Create Dictionary
    ...  UserName=service Password=TestPwd1  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_BAD_REQUEST}]


Verify Modifying Service User Password
     [Documentation]  Verify modifying service user password in redfish.
     [Tags]  Verify_Modifying_Service_User_Password

     ${payload}=  Create Dictionary  Password=NewTestPwd123
     Redfish.Patch  /redfish/v1/AccountService/Accounts/service  body=&{payload}
     ...  valid_status_codes=[${HTTP_BAD_REQUEST}]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
