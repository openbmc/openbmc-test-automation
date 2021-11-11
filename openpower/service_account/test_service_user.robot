*** Settings ***
Documentation    This suite is to test service user functionality via Redfish.

Resource         ../../lib/connection_client.robot 
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify Service User Availability
    [Documentation]  Verify service user avalability.
    [Tags]  Verify_Service_User_Availability

    # Verify that service user has administrator privilege.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/service  RoleId

    Should Be Equal  Administrator  ${role_config}


Verify Creating User With Service Username
    [Documentation]  Verify that user with service username can not be created.
    [Tags]  Verify_Creating_User_With_Service_Username

    ${payload}=  Create Dictionary
    ...  UserName=service Password=TestPwd1  RoleId=Operator  Enabled=${True}
    Redfish.Post  /redfish/v1/AccountService/Accounts/  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify Modifying Service User Password
     [Documentation]  Verify error while modifying service user password in Redfish.
     [Tags]  Verify_Modifying_Service_User_Password

     ${payload}=  Create Dictionary  Password=NewTestPwd123
     # Modification of service user password is not allowed via Redfish API.
     Redfish.Patch  /redfish/v1/AccountService/Accounts/service  body=&{payload}
     ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify Renaming Service User
     [Documentation]  Verify error while renaming service user via Redfish.
     [Tags]  Verify_Renaming_Service_User

     ${payload}=  Create Dictionary  UserName=new_service
     Redfish.Patch  /redfish/v1/AccountService/Accounts/service  body=&{payload}
     ...  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify Deleting Service User
     [Documentation]  Verify error while deleting service user via Redfish.
     [Tags]  Verify_Deleting_Service_User

     Redfish.Delete  /redfish/v1/AccountService/Accounts/service  valid_status_codes=[${HTTP_FORBIDDEN}]


Verify Modifying Service User Role
     [Documentation]  Verify error while modifyig service user role via Redfish.
     [Tags]  Verify_Modifying_Service_User_Role

     ${payload}=  Create Dictionary  RoleId=Operator
     Redfish.Patch  /redfish/v1/AccountService/Accounts/service  body=&{payload}
     ...  valid_status_codes=[${HTTP_FORBIDDEN}]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    Redfish.Login
