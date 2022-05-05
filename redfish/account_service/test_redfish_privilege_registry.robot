*** Settings ***
Documentation    Script To Test Redfish Privilege Registry.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Suite Teardown   Delete Created Redfish Users Except Default Admin
Test Teardown    FFDC On Test Case Fail

*** Variables ***

${test_user}           testuser
${test_password}       testpassword
${admin_user}          testadmin
${admin_password}      adminpassword
${operator_user}       testoperator
${operator_password}   operatorpassword
${readonly_user}       testreadonly
${readonly_password}   readonlypassword
${patched_user}        patchuser
${post_user}           postuser
${post_password}       postpassword
${account_service}     ${2}

** Test Cases **

Verify Redfish Privilege Registry Properties
    [Documentation]  Verify the Redfish Privilege Registry properties.
    [Tags]  Verify_Redfish_Privilege_Registry_Properties

    Redfish.Login

    # Get the complete Privilege Registry URL
    ${url}=   Get Redfish Privilege Registry json URL
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

    # The standard roles are:

    # | Role name | Assigned privileges.
    # | Administrator | Login, ConfigureManager, ConfigureUsers, ConfigureComponents, ConfigureSelf.
    # | Operator | Login, ConfigureComponents, ConfigureSelf.
    # | ReadOnly | Login, ConfigureSelf.

    # Get the complete Privilege Registry URL.
    ${url}=   Get Redfish Privilege Registry json URL
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

Create And Verify Test User For Patch Test
    [Documentation]  Creates a Redfish test user.
    [Tags]  Create_And_Verify_Test_User_For_Patch_Test

    Redfish.Login
    Redfish Create User   ${test_user}  ${test_password}  Operator  ${true}
    Redfish Verify User   ${test_user}  ${test_password}  Operator
    Redfish.Logout

Create And Verify Redfish Administrator
    [Documentation]  Creates a Redfish Admin user.
    [Tags]  Create_And_Verify_Redfish_Administrator

    Redfish.Login
    Redfish Create User   ${admin_user}  ${admin_password}  Administrator  ${true}
    Redfish Verify User   ${admin_user}  ${admin_password}  Administrator
    Redfish.Logout

Verify Admin User Privileges Via Redfish
    [Documentation]  Verify Admin user privileges via Redfish.
    [Tags]  Verify_Admin_User_Privileges_Via_Redfish

    Redfish.Login   ${admin_user}   ${admin_password}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    ${patched_user_status}=   Redfish.Get Attribute  ${REDFISH_ACCOUNTS_URI}${patched_user}  UserName
    Should Be Equal  ${patched_user_status}  ${patched_user}

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    Redfish.Logout

Create And Verify Redfish Operator
    [Documentation]  Create a Redfish Operator user.
    [Tags]  Create_And_Verify_Redfish_Operator

    Redfish.Login
    Redfish Create User   ${operator_user}  ${operator_password}  Operator  ${true}
    Redfish Verify User   ${operator_user}  ${operator_password}  Operator
    Redfish.Logout

Verify Operator User Privileges Via Redfish
    [Documentation]  Verify Operator user privileges via Redfish.
    [Tags]  Verify_Operator_User_Privileges_Via_Redfish

    Redfish.Login   ${operator_user}   ${operatorpassword}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Get   ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Logout

Create And Verify Redfish ReadOnly
    [Documentation]  Create a Redfish ReadOnly user.
    [Tags]  Create_And_Verify_Redfish_ReadOnly

    Redfish.Login
    Redfish Create User   ${readonly_user}  ${readonlypassword}  ReadOnly  ${true}
    Redfish Verify User   ${readonly_user}  ${readonlypassword}  ReadOnly
    Redfish.Logout

Verify ReadOnly User Privileges Via Redfish
    [Documentation]  Verify ReadOnly user privileges via Redfish.
    [Tags]  Verify_ReadOnly_User_Privileges_Via_Redfish

    Redfish.Login   ${readonly_user}   ${readonlypassword}

    ${payload}=  Create Dictionary
    ...  UserName=${post_user}  Password=${post_password}  RoleId=Operator  Enabled=${true}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    ${data}=  Create Dictionary  UserName=${patched_user}
    Redfish.patch  ${REDFISH_ACCOUNTS_URI}${test_user}  body=&{data}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Get  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${patched_user}
    ...  valid_status_codes=[${HTTP_FORBIDDEN}]

    Redfish.Logout


*** Keywords ***

Get Redfish Privilege Registry json URL
    [Documentation]  Return the complete Privilege Registry json URL.

    # Get Privilege Registry version json path in redfish.
    # Example: Redfish_1.1.0_PrivilegeRegistry.json
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Registries/PrivilegeRegistry/
    @{location}=  Get From Dictionary  ${resp.dict}  Location
    ${uri}=   Set Variable   ${location[0]['Uri']}
    [Return]   ${uri}

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

Delete Created Redfish Users Except Default Admin
    [Documentation]  Delete the created test users.
    [Tags]  Delete_Created_Redfish_Users_Except_Default_Admin

    Redfish.Login
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${admin_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${operator_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${readonly_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${post_user}
    ...  valid_status_codes=[${HTTP_OK}]
