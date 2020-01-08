*** Settings ***
Documentation    Test Redfish SessionService.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot

Suite Setup      Redfish.Login
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

Verify HTTP_CREATED response from session creation request
    [Documentation]  Verify HTTP_CREATED response from session creation request.
    [Tags]  Session_Creation_Request_Response

    ${payload}=  Create Dictionary  UserName=${OPENBMC_USERNAME}
    ...  Password=${OPENBMC_PASSWORD}
    ${resp}=  Redfish.Post  /redfish/v1/SessionService/Sessions
    ...  body=&{payload}  valid_status_codes=[${HTTP_CREATED}]


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
