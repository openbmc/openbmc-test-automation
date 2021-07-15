*** Settings ***

Documentation     Redfish request library which provide keywords for creating session,
...               sending POST, PUT, DELETE, PATCH, GET etc. request using redfish_request.py
...               library file. It also contain other keywords which uses redfish_request.py
...               libarary infrastructure.

Resource          openbmc_ffdc.robot
Resource          bmc_redfish_resource.robot
Resource          rest_response_code.robot
Library           redfish_request.py

*** Keywords ***

Redfish Generic Login Request
    [Documentation]  Do Redfish login request.
    [Arguments]  ${user_name}  ${password}

    # Description of argument(s):
    # user_name   User name of BMC.
    # password    Password of BMC.

    ${client_id}=  Create Dictionary  ClientID=None
    ${oem_data}=  Create Dictionary  OpenBMC=${client_id}
    ${data}=  Create Dictionary  UserName=${user_name}  Password=${password}  Oem=${oem_data}

    Set Test Variable  ${uri}  /redfish/v1/SessionService/Sessions
    ${resp}=  Request_Login  headers=None  url=${uri}  credential=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_CREATED}

    [Return]  ${resp}


Redfish Generic Session Request
    [Documentation]  Do Redfish login request and store the session details.
    [Arguments]  ${user_name}  ${password}

    # Description of argument(s):
    # user_name   User name of BMC.
    # password    Password of BMC.

    ${session_dict}=   Create Dictionary
    ${session_resp}=   Redfish Generic Login Request  ${user_name}  ${password}

    ${auth_token}=  Create Dictionary  X-Auth-Token  ${session_resp.headers['X-Auth-Token']}

    Set To Dictionary  ${session_dict}  headers  ${auth_token}
    Set To Dictionary  ${session_dict}  Location  ${session_resp.headers['Location']}

    ${content}=  To JSON  ${session_resp.content}

    Set To Dictionary  ${session_dict}  Content  ${content}

    Set Global Variable  ${active_session_info}  ${session_dict}
    Append To List  ${session_dict_list}  ${session_dict}

    [Return]  ${session_dict}


Verify Redfish Generic Session Request
    [Documentation]  Verify the Redfish session existence.
    [Arguments]  ${session_dict}

    # Description of argument(s):
    # session_dict    Session dictionary contains information related to session attributes
    #                 like auth-token, location, client-id, headers.
    #                 As part of verification following are verified,
    #                 session id, client id and client origin IP.

    Set Test Variable  ${uri}  ${session_dict["Location"]}
    ${session_resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
    Rprint Vars  session_resp

    @{words} =  Split String  ${session_resp["ClientOriginIPAddress"]}  :
    Set Test Variable  ${session_resp_ip}  ${words}[-1]
    ${ip_address}=  Get Running System IP

    Valid Value
    session_dict["Content"]["Oem"]["OpenBMC"]["ClientID"]  ['${session_resp["Oem"]["OpenBMC"]["ClientID"]}']
    Valid Value  session_dict["Content"]["Id"]  ['${session_resp["Id"]}']
    Valid Value  session_resp_ip  ${ip_address}
