*** Settings ***
Documentation    Test Redfish user account.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution



*** Test Cases ***

Verify HTTP_CREATED response from session creation request
    [Documentation]  Verify HTTP_CREATED response from session creation request
    [Tags]  Session_Creation_Request_Response

    ${payload}=  Create Dictionary  UserName=${OPENBMC_USERNAME}
    ...  Password=${OPENBMC_PASSWORD}
    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body=&{payload}  valid_status_codes=[${HTTP_CREATED}]


Verify SessionService parameters default values
    [Documentation]  Verify SessionService parameters default values
    [Tags]  Verify_SessionService_Parameters

    ${sess_serv_props}=  Redfish.Get Properties  /redfish/v1/SessionService
    ...  valid_status_codes=[${HTTP_OK}]

    ${sessions}=  Get From Dictionary  ${sess_serv_props}  Sessions

    ## ${sessions} will have a value like
    ## "Sessions": { '@odata.id': '/redfish/v1/SessionService/Sessions'}
    ##  Replace ' with " in ${sessions} to make it as a json string

    ${sessions}=  evaluate  json.dumps(${sessions}).replace("'", '"')  json
    ${sess_dict}=  evaluate  json.loads('''${sessions}''')  json

    Should Be Equal As Strings  ${sess_serv_props["@odata.context"]}
    ...  /redfish/v1/$metadata#SessionService.SessionService
    Should Be Equal As Strings  ${sess_serv_props["@odata.id"]}
    ...  /redfish/v1/SessionService/
    Should Be Equal As Strings  ${sess_serv_props["Description"]}
    ...  Session Service
    Should Be Equal As Strings  ${sess_serv_props["Id"]}
    ...  SessionService
    Should Be Equal As Strings  ${sess_serv_props["Name"]}
    ...  Session Service
    Should Be Equal As Strings  ${sess_serv_props["ServiceEnabled"]}
    ...  ${True}
    Should Be Equal As Strings  ${sess_serv_props["SessionTimeout"]}
    ...  ${3600}
    Should Be Equal As Strings  ${sess_dict["@odata.id"]}
    ...  /redfish/v1/SessionService/Sessions


Verify Sessions parameters default values
    [Documentation]  Verify Sessions parameters default values
    [Tags]  Verify_Sessions_Parameters

    ${sess_props}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions
    ...  valid_status_codes=[${HTTP_OK}]

    Should Be Equal As Strings  ${sess_props["@odata.context"]}
    ...  /redfish/v1/$metadata#SessionCollection.SessionCollection
    Should Be Equal As Strings  ${sess_props["@odata.id"]}
    ...  /redfish/v1/SessionService/Sessions/
    Should Be Equal As Strings  ${sess_props["Description"]}
    ...  Session Collection
    Should Be Equal As Strings  ${sess_props["Name"]}
    ...  Session Collection

    ${sessions_count}=  Get length  ${sess_props["Members"]}
    Should Be Equal As Strings  ${sess_props["Members@odata.count"]}
    ...  ${sessions_count}
    Log To Console  There are ${sessions_count} active sessions at this time


Verify Current session parameters default values
    [Documentation]  Verify Current session parameters default values
    [Tags]  Verify_Current_Session_Parameters

    ${session_dict}=  Get Redfish Session Info
    ${session_id}=  Fetch From Right  ${session_dict["location"]}  Sessions/

    ${sess_props}=  Redfish.Get Properties
    ...  /redfish/v1/SessionService/Sessions/${session_id}
    ...  valid_status_codes=[${HTTP_OK}]

    Should Be Equal As Strings  ${sess_props["@odata.context"]}
    ...  /redfish/v1/$metadata#Session.Session
    Should Be Equal As Strings  ${sess_props["@odata.id"]}
    ...  /redfish/v1/SessionService/Sessions/${session_id}
    Should Be Equal As Strings  ${sess_props["Description"]}
    ...  Manager User Session
    Should Be Equal As Strings  ${sess_props["Name"]}
    ...  User Session
    Should Be Equal As Strings  ${sess_props["Id"]}
    ...  ${session_id}
    Should Be Equal As Strings  ${sess_props["UserName"]}
    ...  ${OPENBMC_USERNAME}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Create A Session
    [Documentation]  Create A Session
    [Arguments]   ${username}  ${password}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    #FFDC On Test Case Fail
    Redfish.Logout
