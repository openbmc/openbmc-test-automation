*** Settings ***
Documentation    Script To Test Redfish Privilege Registry.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_redfish_utils.robot

Test Teardown    Redfish Test Teardown Execution

*** Variables ***

${test_user}           testuser
${test_password}       testpassword
${admin_user}          testadmin
${admin_password}      adminpassword
${operator_user}       testoperator
${operator_password}   operatorpassword
${readonly_user}       testreadonly
${readonly_password}   readonlypassword
${patched_user}        UserID
${post_user}           postuser
${post_password}       postpassword
${account_service}     ${2}

** Test Cases **

Verify Redfish Privilege Registry Properties
    [Documentation]  Verify the Redfish Privilege Registry properties.
    [Tags]  Verify_Redfish_Privilege_Registry_Properties

    Redfish.Login

    # Get the complete Privilege Registry URL
    ${url}=   Redfish Privilege Registry json URL
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

Verify Redfish Privilege Registry Mappings Property Populated For Account Service
    [Documentation]  Verify Privilege Registry Account Service Mappings resource properties.
    [Tags]  Verify_Redfish_Privilege_Registry_Mappings_Property_Populated_For_Account_Service

    # "Mappings": [
    #    {
    #        "Entity": "AccountService",
    #        "OperationMap": {
    #            "GET": [
    #                {
    #                    "Privilege": [
    #                        "Login"
    #                    ]
    #                }
    #            ],
    #            "HEAD": [
    #                {
    #                    "Privilege": [
    #                        "Login"
    #                    ]
    #                }
    #            ],
    #            "PATCH": [
    #                {
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]
    #                }
    #            ],
    #            "PUT": [
    #                {
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]
    #                }
    #            ],
    #            "DELETE": [
    #                {
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]
    #                }
    #            ],
    #            "POST": [
    #                {
    #                    "Privilege": [
    #                        "ConfigureUsers"
    #                    ]
    #                }
    #            ]
    #        }
    #    },

    # The standard roles are:

    # | Role name | Assigned privileges.
    # | Administrator | Login, ConfigureManager, ConfigureUsers, ConfigureComponents, ConfigureSelf.
    # | Operator | Login, ConfigureComponents, ConfigureSelf.
    # | ReadOnly | Login, ConfigureSelf.

    # Get the complete Privilege Registry URL.
    ${url}=   Redfish Privilege Registry json URL
    ${resp}=   Redfish.Get  ${url}

    # Get mappings properties for Entity: Account Service.
    @{mappings}=  Get From Dictionary  ${resp.dict}  Mappings

    Should Be Equal   ${mappings[${account_service}]['OperationMap']['GET'][0]['Privilege'][0]}   Login
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['HEAD'][0]['Privilege'][0]}   Login
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['PATCH'][0]['Privilege'][0]}   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['PUT'][0]['Privilege'][0]}   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['DELETE'][0]['Privilege'][0]}   ConfigureUsers
    Should Be Equal   ${mappings[${account_service}]['OperationMap']['POST'][0]['Privilege'][0]}   ConfigureUsers

Create Redfish Test User For Privilege Testing
    [Documentation]  Creates a Redfish test user.
    [Tags]  Create_Redfish_Test_User_For_Privilege_Testing

    Redfish Create User   ${test_user}  ${test_password}  Operator  ${true}

Verify Redfish Test User For Privilege Testing
    [Documentation]  Verifies the Redfish test user.
    [Tags]  Verify_Redfish_Test_User_For_Privilege_Testing

    Redfish Verify User   ${test_user}  ${test_password}  Operator  ${true}

Logout Redfish User
    [Documentation]  Logout Redfish User user.
    [Tags]  Logout_Redfish_User

    Redfish.Logout

Login Redfish Default Admin User
    [Documentation]  Login Redfish Default Admin user.
    [Tags]  Login_Redfish_Default_Admin_User

    Redfish.Login

Create Redfish Administrator
    [Documentation]  Creates a Redfish Admin user.
    [Tags]  Create_Redfish_Administrator

    Redfish Create User   ${admin_user}  ${admin_password}  Administrator  ${true}

Verify Redfish Administrator
    [Documentation]  Verify Redfish Administrator user.
    [Tags]  Verify_Redfish_Administrator

    Redfish Verify User   ${admin_user}  ${admin_password}  Administrator  ${true}

Logout Of Redfish Admin
    [Documentation]  Logout Redfish Admin user.
    [Tags]  Logout_Of_Redfish_Admin

    Redfish.Logout

Perform Admin Post/Patch/Get/Delete
    [Documentation]  Verify Admin user privileges via Redfish.
    [Tags]  Perform_Admin_Post/Patch/Get/Delete

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

Create Redfish Operator
    [Documentation]  Create a Redfish Operator user.
    [Tags]  Create_Redfish_Operator

    Redfish.Login
    Redfish Create User   ${operator_user}  ${operator_password}  Operator  ${true}

Verify Redfish Operator
    [Documentation]  Verify Redfish Operator user.
    [Tags]  Verify_Redfish_Operator

    Redfish Verify User   ${operator_user}  ${operator_password}  Operator  ${true}

Perform Operator Post/Patch/Get/Delete
    [Documentation]  Verify Operator user privileges via Redfish.
    [Tags]  Perform_Operator_Post/Patch/Get/Delete

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

Logout Of Redfish Operator User
    [Documentation]  Logout Redfish Operator user.
    [Tags]  Logout_Of_Redfish_Operator_User

    Redfish.Logout

Create Redfish ReadOnly
    [Documentation]  Create a Redfish ReadOnly user.
    [Tags]  Create_Redfish_ReadOnly

    Redfish.Login
    Redfish Create User   ${readonly_user}  ${readonlypassword}  ReadOnly  ${true}

Verify Redfish ReadOnly
    [Documentation]  Verify Redfish ReadOnly user.
    [Tags]  Verify_Redfish_ReadOnly

    Redfish Verify User   ${readonly_user}  ${readonlypassword}  ReadOnly  ${true}

Perform ReadOnly Post/Patch/Get/Delete
    [Documentation]  Verify ReadOnly user privileges via Redfish.
    [Tags]  Perform_ReadOnly_Post/Patch/Get/Delete

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

Logout Redfish ReadOnly User
    [Documentation]  Logout Redfish ReadOnly user.
    [Tags]  Logout_Redfish_ReadOnly_User

    Redfish.Logout

Login Redfish Default Admin User
    [Documentation]  Login Redfish Admin User.
    [Tags]  Login_Redfish_Default_Admin_User

    Redfish.Login

Delete Created Redfish Users Except Default Admin
    [Documentation]  Delete the created test users.
    [Tags]  Delete_Created_Redfish_Users_Except_Default_Admin

    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${admin_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${operator_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${readonly_user}
    ...  valid_status_codes=[${HTTP_OK}]
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${post_user}
    ...  valid_status_codes=[${HTTP_OK}]

*** Keywords ***

Redfish Privilege Registry json URL
    [Documentation]  Return the complete Privilege Registry json URL.

    # Get Privilege Registry version json path in redfish.
    # Example: Redfish_1.1.0_PrivilegeRegistry.json
    ${resp}=  Redfish.Get
    ...  /redfish/v1/Registries/PrivilegeRegistry/
    @{location}=  Get From Dictionary  ${resp.dict}  Location
    ${uri}=   Set Variable   ${location[0]['Uri']}
    [Return]   ${uri}

Redfish Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail

Redfish Verify User
    [Documentation]  Verify Redfish user verification.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    Run Keyword And Ignore Error  Redfish.Logout
    ${status}=  Run Keyword And Return Status  Redfish.Login  ${username}  ${password}
    # Validate Role Id of user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  /redfish/v1/AccountService/Accounts/${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}
