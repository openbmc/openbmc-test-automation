*** Settings ***

Documentation    Test Redfish SessionService.

Resource         ../../lib/bmc_redfish_utils.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Suite Teardown   Suite Teardown Execution
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Variables ***

@{ADMIN}       admin_user  TestPwd123
@{OPERATOR}    operator_user  TestPwd123
# User-driven input parameter to skip operator user.
# -v SKIP_OPERATOR_USER:1  to skip from CLI.
${SKIP_OPERATOR_USER}    ${0}


*** Test Cases ***

Create Session And Verify Response Code Using Different Credentials
    [Documentation]  Create session and verify response code using different credentials.
    [Tags]  Create_Session_And_Verify_Response_Code_Using_Different_Credentials
    [Template]  Create Session And Verify Response Code

    # username           password             valid_status_code
    ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  ${HTTP_CREATED}
    r00t                 ${OPENBMC_PASSWORD}  ${HTTP_UNAUTHORIZED}
    ${OPENBMC_USERNAME}  password             ${HTTP_UNAUTHORIZED}
    r00t                 password             ${HTTP_UNAUTHORIZED}
    admin_user           TestPwd123           ${HTTP_CREATED}


Create Session And Verify Response Code Using Operator Credentials
    [Documentation]  Create session and verify response code using operator credentials.
    [Tags]  Create_Session_And_Verify_Response_Code_Using_Operator_Credentials
    [Template]  Create Session And Verify Response Code

    # username           password             valid_status_code
    operator_user        TestPwd123           ${HTTP_CREATED}


Set Session Timeout And Verify Response Code
    [Documentation]  Set Session Timeout And Verify Response Code.
    [Tags]  Set_Session_Timeout_And_Verify_Response_Code
    [Template]  Set Session Timeout And Verify
    [Teardown]  Set Session Timeout And Verify  ${Default_Timeout_Value}  ${HTTP_OK}

    # The minimum & maximum allowed values for session timeout are 30
    # seconds and 86400 seconds respectively as per the session service
    # schema mentioned at
    # https://redfish.dmtf.org/schemas/v1/SessionService.v1_1_7.json

    # value             valid_status_code
    ${25}               ${HTTP_BAD_REQUEST}
    ${30}               ${HTTP_OK}
    ${3600}             ${HTTP_OK}
    ${86400}            ${HTTP_OK}
    ${86500}            ${HTTP_BAD_REQUEST}


Set Session Timeout And Verify Session After Timeout
    [Documentation]  Set timeout for session service and verify session is deleted after timeout.
    [Tags]  Set_Session_Timeout_And_Verify_Session_After_Timeout
    [Teardown]  Set Session Timeout And Verify   ${Default_Timeout_Value}  ${HTTP_OK}
    [Template]  Set Session Timeout And Verify Session Deleted After Timeout

    #timeout Value
    ${30}
    ${300}


Verify Session Login And Logout For Newly Created User
    [Documentation]  Verify able to login and logout using the session created for new user.
    [Tags]  Verify_Session_Login_And_Logout_For_Newly_Created_User
    [Teardown]  Redfish.Login

    # Logout already created redfish session.
    Redfish.Logout
    Redfish.Login  ${ADMIN}[0]  ${ADMIN}[1]
    ${systems}=  Redfish.Get Properties  /redfish/v1/Systems
    Rprint Vars  systems
    Redfish.Logout
    ${systems}=  Redfish.Get  /redfish/v1/Systems
    ...  valid_status_codes=[${HTTP_UNAUTHORIZED}]


Verify SessionService Defaults
    [Documentation]  Verify SessionService default property values.
    [Tags]  Verify_SessionService_Defaults

    ${session_service}=  Redfish.Get Properties  /redfish/v1/SessionService
    Rprint Vars  session_service

    Valid Value  session_service['@odata.id']  ['/redfish/v1/SessionService/']
    Valid Value  session_service['Description']  ['Session Service']
    Valid Value  session_service['Id']  ['SessionService']
    Valid Value  session_service['Name']  ['Session Service']
    Valid Value  session_service['ServiceEnabled']  [True]
    Valid Value  session_service['SessionTimeout']  [${Default_Timeout_Value}]
    Valid Value  session_service['Sessions']['@odata.id']  ['/redfish/v1/SessionService/Sessions']


Verify Sessions Defaults
    [Documentation]  Verify Sessions default property values.
    [Tags]  Verify_Sessions_Defaults

    ${sessions}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions
    Rprint Vars  sessions
    ${sessions_count}=  Get length  ${sessions['Members']}

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

    Valid Value  session_properties['@odata.id']  ['/redfish/v1/SessionService/Sessions/${session_id}']
    Valid Value  session_properties['Description']  ['Manager User Session']
    Valid Value  session_properties['Name']  ['User Session']
    Valid Value  session_properties['Id']  ['${session_id}']
    Valid Value  session_properties['UserName']  ['${OPENBMC_USERNAME}']


Verify Managers Defaults
    [Documentation]  Verify managers defaults.
    [Tags]  Verify_Managers_Defaults

    ${managers}=  Redfish.Get Properties  /redfish/v1/Managers
    Rprint Vars  managers
    ${managers_count}=  Get Length  ${managers['Members']}

    Valid Value  managers['Name']  ['Manager Collection']
    Valid Value  managers['@odata.id']  ['/redfish/v1/Managers']
    Valid Value  managers['Members@odata.count']  [${managers_count}]

    # Members can be one or more, hence checking in the list.
    Valid List  managers['Members']  required_values=[{'@odata.id': '/redfish/v1/Managers/${MANAGER_ID}'}]


Verify Chassis Defaults
    [Documentation]  Verify chassis defaults.
    [Tags]  Verify_Chassis_Defaults

    ${chassis}=  Redfish.Get Properties  /redfish/v1/Chassis
    Rprint Vars  chassis
    ${chassis_count}=  Get Length  ${chassis['Members']}

    Valid Value  chassis['Name']  ['Chassis Collection']
    Valid Value  chassis['@odata.id']  ['/redfish/v1/Chassis']
    Valid Value  chassis['Members@odata.count']  [${chassis_count}]
    Valid Value  chassis['Members@odata.count']  [${chassis_count}]

    # Members can be one or more, hence checking in the list.
    Valid List  chassis['Members']
    ...  required_values=[{'@odata.id': '/redfish/v1/Chassis/${CHASSIS_ID}'}]


Verify Systems Defaults
    [Documentation]  Verify systems defaults.
    [Tags]  Verify_Systems_Defaults

    ${systems}=  Redfish.Get Properties  /redfish/v1/Systems
    Rprint Vars  systems
    ${systems_count}=  Get Length  ${systems['Members']}
    Valid Value  systems['Name']  ['Computer System Collection']
    Valid Value  systems['@odata.id']  ['/redfish/v1/Systems']
    Valid Value  systems['Members@odata.count']  [${systems_count}]
    Valid Value  systems['Members@odata.count']  [${systems_count}]
    # Members can be one or more, hence checking in the list.
    Valid List  systems['Members']  required_values=[{'@odata.id': '/redfish/v1/Systems/system'}]


Verify Session Persistency After BMC Reboot
    [Documentation]  Verify session persistency after BMC reboot.
    [Tags]  Verify_Session_Persistency_After_BMC_Reboot

    # Note the current session location.
    ${session_location}=  Redfish.Get Session Location

    Redfish OBMC Reboot (off)  stack_mode=normal

    # Check for session persistency after BMC reboot.
    # sessions here will have list of all sessions location.
    ${sessions}=  Redfish.Get Attribute  /redfish/v1/SessionService/Sessions  Members
    ${payload}=  Create Dictionary  @odata.id=${session_location}

    List Should Contain Value  ${sessions}  ${payload}

*** Keywords ***

Create Session And Verify Response Code
    [Documentation]  Create session and verify response code.
    [Arguments]  ${username}=${OPENBMC_USERNAME}  ${password}=${OPENBMC_PASSWORD}
    ...  ${valid_status_code}=${HTTP_CREATED}

    # Description of argument(s):
    # username            The username to create a session.
    # password            The password to create a session.
    # valid_status_code   Expected response code, default is ${HTTP_CREATED}.

    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body={'UserName':'${username}', 'Password': '${password}'}
    ...  valid_status_codes=[${valid_status_code}]


Set Session Timeout And Verify
    [Documentation]  Set Session Timeout And Verify.
    [Arguments]  ${value}=3600  ${valid_status_code}=${HTTP_OK}

    # Description of argument(s):
    # value               The value to patch session timeout.
    # valid_status_code   Expected response code, default is ${HTTP_OK}.

    Redfish.Login
    ${data}=  Create Dictionary  SessionTimeout=${value}
    Redfish.Patch  ${REDFISH_BASE_URI}SessionService
    ...  body=&{data}
    ...  valid_status_codes=[${valid_status_code}]

    ${session_timeout}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}SessionService  SessionTimeout

    Run Keyword If  ${valid_status_code}==${HTTP_OK}
    ...  Valid Value  session_timeout  [${value}]


Create Session And Check Session Timeout
    [Documentation]  Create session and check session timeout.
    [Arguments]  ${value}

    # Description of argument(s):
    # value   timeout value in integer to be configured.

    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body={'UserName':'${OPENBMC_USERNAME}', 'Password': '${OPENBMC_PASSWORD}'}
    ...  valid_status_codes=[${HTTP_CREATED}]
    ${session_id}=  Set Variable  ${resp.dict['@odata.id']}
    Sleep  ${value}s

    Redfish.Get  ${REDFISH_SESSION}  valid_status_codes=[${HTTP_UNAUTHORIZED}]
    # Since sessions will deleted so logging again.
    Redfish.login
    ${session_list}=  Redfish.Get Members List  /redfish/v1/SessionService/Sessions

    List Should Not Contain Value  ${session_list}  ${session_id}


Set Session Timeout And Verify Session Deleted After Timeout
    [Documentation]  Set timeout for session service and verify session is deleted after timeout.
    [Arguments]  ${timeout_value}

    # Description of argument(s):
    # timeout_value   timeout value in integer to be configured.

    ${data}=  Create Dictionary  SessionTimeout=${timeout_value}
    ${resp_patch}=  Redfish.Patch  /redfish/v1/SessionService
    ...  body=&{data}  valid_status_codes=[${HTTP_OK}]
    Create Session And Check Session Timeout  ${timeout_value}


Get Default Timeout Value
    [Documentation]  Get default session timeout value and set as a suite variable.

    ${Default_Timeout_Value}=  Redfish.Get Attribute  /redfish/v1/SessionService  SessionTimeout
    Set Suite Variable   ${Default_Timeout_Value}


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    Redfish.Login

    # Skip operator user if SKIP_OPERATOR_USER is 1.
    Run Keyword If
    ...  ${SKIP_OPERATOR_USER} == ${1}
    ...  Set Suite Variable  &{USERS}  Administrator=${ADMIN}
    ...  ELSE
    ...  Set Suite Variable  &{USERS}  Administrator=${ADMIN}  Operator=${OPERATOR}

    Create Users With Different Roles  users=${USERS}  force=${True}
    Get Default Timeout Value


Suite Teardown Execution
    [Documentation]  Suite teardown execution.

    Delete BMC Users Via Redfish  users=${USERS}
    Run Keyword And Ignore Error  Delete All Redfish Sessions
    Redfish.Logout
