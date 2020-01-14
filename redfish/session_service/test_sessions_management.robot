*** Settings ***

Documentation    Test Redfish SessionService.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Create Session And Verify Response Code Using Different Credentails
    [Documentation]  Create session and verify response code using different credentials.
    [Tags]  Create_Session_And_Verify_Response_Code_Using_Different_Credentails
    [Template]  Create Session And Verify Response Code

    #username      password    valid_status_codes
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${HTTP_CREATED}
    r00t                 ${OPENBMC_PASSWORD}  ${HTTP_FORBIDDEN}
    ${OPENBMC_USERNAME}  password             ${HTTP_FORBIDDEN}
    r00t                 password             ${HTTP_FORBIDDEN}
    admin_user           TestPwd123           ${HTTP_CREATED}
    operator_user        TestPwd123           ${HTTP_CREATED}

    ## NOTE: Uncomment these users accout creation when SW482962 is fixed
    #user_user            TestPwd123           ${HTTP_CREATED}
    #callback_user        TestPwd123           ${HTTP_CREATED}


Verify SessionService Defaults
    [Documentation]  Verify SessionService default property values.
    [Tags]  Verify_SessionService_Defaults

    ${session_service}=  Redfish.Get Properties  /redfish/v1/SessionService
    Rprint Vars  session_service

    Valid Value  session_service['@odata.context']  ['/redfish/v1/$metadata#SessionService.SessionService']
    Valid Value  session_service['@odata.id']  ['/redfish/v1/SessionService/']
    Valid Value  session_service['Description']  ['Session Service']
    Valid Value  session_service['Id']  ['SessionService']
    Valid Value  session_service['Name']  ['Session Service']
    Valid Value  session_service['ServiceEnabled']  [True]
    Valid Value  session_service['SessionTimeout']  [3600]
    Valid Value  session_service['Sessions']['@odata.id']  ['/redfish/v1/SessionService/Sessions']


Verify Sessions Defaults
    [Documentation]  Verify Sessions default property values.
    [Tags]  Verify_Sessions_Defaults

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions
    Rprint Vars  sessions
    ${sessions_count}=  Get length  ${sessions['Members']}

    Valid Value  sessions['@odata.context']  ['/redfish/v1/$metadata#SessionCollection.SessionCollection']
    Valid Value  sessions['@odata.id']  ['/redfish/v1/SessionService/Sessions/']
    Valid Value  sessions['Description']  ['Session Collection']
    Valid Value  sessions['Name']  ['Session Collection']
    Valid Value  sessions['Members@odata.count']  [${sessions_count}]


Verify Current Session Defaults
    [Documentation]  Verify Current session default property values.
    [Tags]  Verify_Current_Session_Defaults

    ${session_location}=  Redfish.Get Session Location
    ${session_id}=  Evaluate  os.path.basename($session_location)  modules=os
    ${session_properties}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session_id}
    Rprint Vars  session_location  session_id  session_properties

    Valid Value  session_properties['@odata.context']  ['/redfish/v1/$metadata#Session.Session']
    Valid Value  session_properties['@odata.id']  ['/redfish/v1/SessionService/Sessions/${session_id}']
    Valid Value  session_properties['Description']  ['Manager User Session']
    Valid Value  session_properties['Name']  ['User Session']
    Valid Value  session_properties['Id']  ['${session_id}']
    Valid Value  session_properties['UserName']  ['${OPENBMC_USERNAME}']


*** Keywords ***

Create Session And Verify Response Code
    [Documentation]  Create Session And Verify Response Code
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${valid_status_codes}=${HTTP_CREATED}

    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body={'UserName':'${username}', 'Password': '${password}'}
    ...  valid_status_codes=[${valid_status_codes}]

    Return From Keyword If  ${valid_status_codes} != ${HTTP_CREATED}

    ${headers}=  Key Value List To Dict  ${resp.getheaders()}

    ##  We need these tokens in future testcases (Yet to be automated)
    Set Suite Variable  ${${username}_key}  ${headers['X-Auth-Token']}
    Set Suite Variable  ${${username}_loc}  ${headers['Location']}


Create Users With Different Roles
    [Documentation]  Create users with different roles.

    Create User Of Given Role  admin_user     TestPwd123  Administrator   ${True}
    Create User Of Given Role  operator_user  TestPwd123  Operator        ${True}

    ## NOTE: Uncomment these users accout creation when SW482962 is fixed
    #Create User Of Given Role  user_user      TestPwd123  User            ${True}
    #Create User Of Given Role  callback_user  TestPwd123  Callback        ${True}


Create User Of Given Role
    [Documentation]  Create user of given role.
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).

    # Make sure the user account in question does not already exist.
    Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${userName}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login
    Create Users With Different Roles

