*** Settings ***
Documentation    Script to test Redfish privilege registry with various users
...  such as test, admin, operator, readonly, patched.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Suite Setup      Create And Verify Various Privilege Users
Suite Teardown   Delete Created Redfish Users Except Default Admin
Test Teardown    Redfish.Logout

Test Tags        Redfish_Privilege_Registry

*** Variables ***

${test_user}           testuser
${test_password}       testpassword123
${admin_user}          testadmin
${admin_password}      adminpassword123
${operator_user}       testoperator
${operator_password}   operatorpassword123
${readonly_user}       testreadonly
${readonly_password}   readonlypassword123
${patched_user}        patchuser
${post_user}           postuser
${post_password}       postpassword123
${account_service}     ${2}

*** Test Cases ***

Verify Redfish Privilege Registry Properties
    [Documentation]  Verify the Redfish Privilege Registry properties.
    [Tags]  Verify_Redfish_Privilege_Registry_Properties

    Redfish.Login

    # Get the complete Privilege Registry URL
    ${url}=   Get Redfish Privilege Registry Json URL
    ${resp}=   Redfish.Get  ${url}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}

    # Verify the Privilege Registry Resource.
    # Example:
    #  "Id": "Redfish_1.1.0_PrivilegeRegistry",
    #  "Name": "Privilege Mapping array collection",
    #  "PrivilegesUsed": [
    #     "Login",
    #     "ConfigureManager",
    #     "ConfigureUsers",
    #     "ConfigureComponents",
    #     "ConfigureSelf"
    #  ],

    Should Be Equal As Strings  ${resp.dict["Id"]}  Redfish_1.1.0_PrivilegeRegistry
    Should Be Equal As Strings  ${resp.dict["Name"]}  Privilege Mapping array collection
    Should Be Equal As Strings  ${resp.dict["PrivilegesUsed"][0]}  Login
    Should Be Equal As Strings  ${resp.dict["PrivilegesUsed"][1]}  ConfigureManager
    Should Be Equal As Strings  ${resp.dict["PrivilegesUsed"][2]}  ConfigureUsers
    Should Be Equal As Strings  ${resp.dict["PrivilegesUsed"][3]}  ConfigureComponents
    Should Be Equal As Strings  ${resp.dict["PrivilegesUsed"][4]}  ConfigureSelf

Verify Redfish Privilege Registry Mappings Properties For Account Service
    [Documentation]  Verify Privilege Registry Account Service Mappings resource properties.
    [Tags]  Verify_Redfish_Privilege_Registry_Mappings_Properties_For_Account_Service

    # Below is the mapping for Redfish Privilege Registry property for
    # Account Service.

    # "Mappings": [
    #    {
    #        "Entity": "AccountService",
    #        "OperationMap": {
    #            "GET": [{
    #                    "Privilege": [
    #                        "Login"
    #                    ]}],
    #            "HEAD": [{
    #                    "Privilege": [
    #                        "Login"
    #                    ]}],
    #            "PATCH": [{
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]}],
    #            "PUT": [{
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]}],
    #            "DELETE": [{
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]}],
    #            "POST": [{
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]}]}
    #    }

    # | ROLE NAME     | ASSIGNED PRIVILEGES
    # |---------------|--------------------
    # | Administrator | Login, ConfigureManager, ConfigureUsers, ConfigureComponents, ConfigureSelf.
    # | Operator      | Login, ConfigureComponents, ConfigureSelf.
    # | ReadOnly      | Login, ConfigureSelf.

    # Get the complete Privilege Registry URL.
    ${url}=   Get Redfish Privilege Registry Json URL
    ${resp}=   Redfish.Get  ${url}

    # Get mappings properties for Entity: Account Service.
    @{mappings}=  Get From Dictionary  ${resp.dict}  Mappings

    Should Be Equal   ${mappings[${account_service}]['OperationMap']['GET'][0]['Privilege'][0]}
    ...   Login
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['HEAD'][0]['Privilege'][0]}
    ...   Login
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['PATCH'][0]['Privilege'][0]}
    ...   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['PUT'][0]['Privilege'][0]}
    ...   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['DELETE'][0]['Privilege'][0]}
    ...   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['POST'][0]['Privilege'][0]}
    ...   ConfigureUsers

Verify Admin User Privileges Via Redfish
    [Documentation]  Verify Admin user privileges via Redfish.
    [Tags]  Verify_Admin_User_Privileges_Via_Redfish

    Redfish.Login   ${admin_user}   ${admin_password}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${patched_user_name}=   Redfish.Get Attribute  ${REDFISH_ACCOUNTS_URI}${patched_user}  UserName
    Should Be Equal  ${patched_user_name}  ${patched_user}

Verify Operator User Privileges Via Redfish
    [Documentation]  Verify Operator user privileges via Redfish.
    [Tags]  Verify_Operator_User_Privileges_Via_Redfish

    Redfish.Login   ${operator_user}   ${operator_password}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Get   ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

Verify ReadOnly User Privileges Via Redfish
    [Documentation]  Verify ReadOnly user privileges via Redfish.
    [Tags]  Verify_ReadOnly_User_Privileges_Via_Redfish

    Redfish.Login   ${readonly_user}   ${readonly_password}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.Patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Get  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]


*** Keywords ***

Get Redfish Privilege Registry Json URL
    [Documentation]  Return the complete Privilege Registry Json URL.

    # Get Privilege Registry version Json path in redfish.
    # Example: Redfish_1.1.0_PrivilegeRegistry.json

    ${resp}=  Redfish.Get
    ...  /redfish/v1/Registries/PrivilegeRegistry/
    @{location}=  Get From Dictionary  ${resp.dict}  Location
    ${uri}=   Set Variable   ${location[0]['Uri']}
    RETURN   ${uri}

Create And Verify Various Privilege Users
    [Documentation]  Create and verify admin, test, operator, and readonly users.

    Redfish Create User   ${test_user}  ${test_password}  Operator  ${true}
    Redfish Create User   ${admin_user}  ${admin_password}  Administrator  ${true}
    Redfish Create User   ${operator_user}  ${operator_password}  Operator  ${true}
    Redfish Create User   ${readonly_user}  ${readonly_password}  ReadOnly  ${true}

    Redfish Verify User   ${test_user}  ${test_password}  Operator
    Redfish Verify User   ${admin_user}  ${admin_password}  Administrator
    Redfish Verify User   ${operator_user}  ${operator_password}  Operator
    Redfish Verify User   ${readonly_user}  ${readonly_password}  ReadOnly

Redfish Verify User
    [Documentation]  Verify Redfish user with given credentials.
    [Arguments]   ${username}  ${password}  ${role_id}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).

    Run Keyword And Ignore Error  Redfish.Logout
    Redfish.Login  ${username}  ${password}

    # Validate Role Id of user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}
    Redfish.Logout

Delete Created Redfish Users Except Default Admin
    [Documentation]  Delete the admin, patched, operator, readonly, and post users.

    Redfish.Login
    Run Keyword And Ignore Error  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${admin_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Run Keyword And Ignore Error  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Run Keyword And Ignore Error  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${operator_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Run Keyword And Ignore Error  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${readonly_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Run Keyword And Ignore Error  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${post_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Logout
