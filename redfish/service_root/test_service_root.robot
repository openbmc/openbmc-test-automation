*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot

Suite Teardown   redfish.Logout


*** Test Cases ***

Login And Logout BMCweb
    [Documentation]  Login to BMCweb and then logout.
    [Tags]  Login_And_Logout_BMCweb

    redfish.Login
    redfish.Logout


GET BMCweb Hypermedia Without Login
    [Documentation]  GET /redfish/v1 without login.
    [Tags]  GET_BMCweb_Hypermedia_Without_Login

    redfish.Logout
    ${resp}=  redfish.Get  ${EMPTY}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}


GET SessionService Resource With Login
    [Documentation]  Login to BMCweb and get /redfish/v1/SessionService.
    [Tags]  GET_SessionService_Resource_With_Login

    redfish.Login
    ${resp}=  redfish.Get  SessionService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}


GET SessionService Without Login
    [Documentation]  Get /redfish/v1/SessionService without login
    [Tags]  GET_SessionService_Without_Login

    redfish.Logout
    ${resp}=  redfish.Get  SessionService
    Should Be Equal As Strings  ${resp.status}  ${HTTP_UNAUTHORIZED}


Login Using Invalid Token
    [Documentation]  Login to BMCweb with invalid token.
    [Tags]  Login_Using_Invalid_Token

    redfish.Logout

    Create Session  openbmc  ${AUTH_URI}

    # Example: "X-Auth-Token: 3la1JUf1vY4yN2dNOwun"
    ${headers}=  Create Dictionary  Content-Type=application/json
    ...  X-Auth-Token=deadbeef

    ${resp}=  Get Request
    ...  openbmc  /redfish/v1/SessionService/Sessions  headers=${headers}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_UNAUTHORIZED}


Delete Session Using Valid login
    [Documentation]  Delete a session using valid login.
    [Tags]  Delete_Session_Using_Valid_Login

    redfish.Login

    # Example o/p:
    # [{'@odata.id': '/redfish/v1/SessionService/Sessions/bOol3WlCI8'},
    #  {'@odata.id': '/redfish/v1/SessionService/Sessions/Yu3xFqjZr1'}]
    ${resp_list}=  redfish.Get  SessionService/Sessions

    redfish.Delete  ${resp_list.dict["Members"][0]["@odata.id"]}

    ${resp}=  redfish.Get  SessionService/Sessions
    Should Not Contain  ${resp.dict["Members"]}  ${resp_list.dict["Members"][0]["@odata.id"]}

