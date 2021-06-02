*** Settings ***

Documentation     Redfish request library.

Resource          openbmc_ffdc.robot
Resource          bmc_redfish_resource.robot
Resource          rest_response_code.robot

*** Variables ***
#${active_session_info}
#@{session_dict_list}

*** Keywords ***

Redfish Login Request
     [Documentation]  Do BMC web-based login.

     ${temp}=  Create Dictionary  ClientID=None
     ${temp}=  Create Dictionary  OpenBMC=${temp}
     ${data}=  Create Dictionary  UserName=${OPENBMC_USERNAME}  Password=${OPENBMC_PASSWORD}  Oem=${temp}

     ${resp}=  redfish_request_utils.RequestLoginMethod  ${data}
     Should Be Equal As Strings  ${resp.status_code}  ${HTTP_CREATED}
     #Log  ${resp.headers}
     #Log  ${resp.status_code}

     ${content}=  To JSON  ${resp.content}
     #Log  ${content}
     

     [Return]  ${resp}


Redfish Session Request
     [Documentation]

     ${session_dict}=   Create Dictionary
     ${session_resp}=   Redfish Login Request
     #Log  ${session_resp}
     #Log  ${session_resp.headers}
    
     ${temp}=  Create Dictionary  X-Auth-Token  ${session_resp.headers['X-Auth-Token']}
     Set To Dictionary  ${session_dict}  headers  ${temp}
     Set To Dictionary  ${session_dict}  Location  ${session_resp.headers['Location']}
     ${content}=  To JSON  ${session_resp.content}
     Set To Dictionary  ${session_dict}  Content  ${content}
 
     Log  ${session_dict}
     #Set Global Variable  ${active_session}  ${session_info['sessionid_1']}[-1]
     #Set Global Variable  ${session_info}

     [Return]  ${session_dict}


Redfish Generic Login Request
     [Documentation]  Do BMC web-based login.
     [Arguments]   ${user_name}  ${password}

     ${temp}=  Create Dictionary  ClientID=None
     ${temp}=  Create Dictionary  OpenBMC=${temp}
     ${data}=  Create Dictionary  UserName=${user_name}  Password=${password}  Oem=${temp}

     ${resp}=  redfish_request_utils.RequestLoginMethod  headers=None  url=/redfish/v1/SessionService/Sessions  credential=${data}
     Should Be Equal As Strings  ${resp.status_code}  ${HTTP_CREATED}

    [Return]  ${resp}


Redfish Generic Session Request
    [Documentation]  Do BMC web-based login.
    [Arguments]   ${user_name}  ${password}

    ${session_dict}=   Create Dictionary
    ${session_resp}=   Redfish Generic Login Request  ${user_name}  ${password}

    ${temp}=  Create Dictionary  X-Auth-Token  ${session_resp.headers['X-Auth-Token']}
    Set To Dictionary  ${session_dict}  headers  ${temp}
    Set To Dictionary  ${session_dict}  Location  ${session_resp.headers['Location']}
    ${content}=  To JSON  ${session_resp.content}
    Set To Dictionary  ${session_dict}  Content  ${content}
    Set Global Variable  ${active_session_info}  ${session_dict}
    Append To List  ${session_dict_list}  ${session_dict}   
    

    [Return]  ${session_dict}


Verify Redfish Generic Session
    [Documentation]  Verify
    [Arguments]  ${session_dict}

    #Log  ${active_session_info}
    #Log  ${active_session_info['headers']}
    #${head}=  Get From Dictionary  ${active_session_info}  headers
    #Log  ${head}
    Set Test Variable  ${uri}  ${session_dict["Location"]}
    ${session_resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
    Log  ${session_resp}
    Rprint Vars  session_resp
    @{words} =  Split String  ${session_resp["ClientOriginIPAddress"]}  :
    ${ip_address}=  Get Running System IP
    Set Test Variable  ${temp_ipaddr}  ${words}[-1]
    Valid Value  session_dict["Content"]["Oem"]["OpenBMC"]["ClientID"]  ['${session_resp["Oem"]["OpenBMC"]["ClientID"]}']
    Valid Value  session_dict["Content"]["Id"]  ['${session_resp["Id"]}']
    Valid Value  temp_ipaddr  ${ip_address}
    

Redfish Request Delete Session
    [Documentation]  Verify
    [Arguments]  ${session_dict}

    Set Test Variable  ${uri}  ${session_dict["Location"]}
    ${session_resp}=  Redfish DELETE Request URI  ${active_session_info['headers']}  ${uri}


Redfish GET Request URI
     [Documentation]  Do REST GET request and return the result.
     [Arguments]  ${headers}  ${uri}  ${timeout}=10  ${status_code}=${HTTP_OK}

     # Description of argument(s):
     # headers  Pass the headers.
     # uri      The URI to establish connection with
     #          (e.g. '/xyz/openbmc_project/software/').
     # timeout  Timeout in seconds to establish connection with URI

     Log  ${active_session_info}
     ${resp}=  redfish_request_utils.RequestGetMethod  ${active_session_info['headers']}  ${uri}  ${timeout}
     Should Be Equal As Strings  ${resp.status_code}  ${status_code}
     #Rprint Vars  ${resp}
     ${content}=  To JSON  ${resp.content}
     #Print Timen  ${content}
     [Return]  ${content}


Redfish POST Request URI
     [Documentation]  Do REST POST request and return the result.

     [Arguments]  ${headers}  ${uri}  ${data}  ${timeout}=10  ${status_code}=${HTTP_OK}

     # Description of argument(s):
     # headers  Pass the headers.
     # uri      The URI to establish connection with
     #          (e.g. '/xyz/openbmc_project/software/').
     # timeout  Timeout in seconds to establish connection with URI

     #Log  ${uri}
     ${resp}=  redfish_request_utils.RequestPostMethod  ${active_session_info['headers']}  ${uri}  ${data}
     Should Be Equal As Strings  ${resp.status_code}  ${status_code}
     Log  ${resp}
     ${content}=  To JSON  ${resp.content}
     [Return]  ${resp}


Redfish DELETE Request URI
     [Documentation]  Do REST POST request and return the result.

     [Arguments]  ${headers}  ${uri}  ${data}=None  ${timeout}=10  ${status_code}=${HTTP_OK}

     # Description of argument(s):
     # headers  Pass the headers.
     # uri      The URI to establish connection with
     #          (e.g. '/xyz/openbmc_project/software/').
     # timeout  Timeout in seconds to establish connection with URI


     ${resp}=  redfish_request_utils.RequestDeleteMethod  ${active_session_info['headers']}  ${uri}
     Should Be Equal As Strings  ${resp.status_code}  ${status_code}
     Log  ${resp}


Redfish GET Target Attributes
     [Documentation]
     [Arguments]  ${attribute}  ${uri}

     ${resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
     Log  ${resp}
     ${resp}=  redfish_request_utils.GetTargetActions  ${attribute}  ${uri}  ${resp}
     Log  ${resp}
     [Return]  ${resp}

Redfish Request BMC Reset Operation
     [Documentation]  Do Redfish BMC reset operation.
     # Example:
     # "Actions": {
     # "#Manager.Reset": {
     #  "ResetType@Redfish.AllowableValues": [
     #    "GracefulRestart"
     #  ],
     #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
     # }

     ${payload}=  Create Dictionary  ResetType=GracefulRestart
     ${target}=  Redfish GET Target Attributes  Manager.Reset  /redfish/v1/Managers/bmc/
     Log  ${target}
     ${resp}=  Redfish POST Request URI  ${active_session_info['headers']}  ${target}  ${payload}

Redfish Request Get BMC State
    [Documentation]  Return BMC health state.

    # "Enabled" ->  BMC Ready, "Starting" -> BMC NotReady

    # Example:
    # "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "Enabled"
    # },


    Set Test Variable  ${uri}  /redfish/v1/Managers/bmc
    ${resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}  timeout=30
   
    ${status}=  redfish_request_utils.GetAttribute  Status  ${resp}
    [Return]  ${status["State"]}


Redfish Request Get Host State
    [Documentation]  Return host power and health state.
    # Refer: http://redfish.dmtf.org/schemas/v1/Resource.json#/definitions/Status

    # Example:
    # "PowerState": "Off",
    # "Status": {
    #    "Health": "OK",
    #    "HealthRollup": "OK",
    #    "State": "StandbyOffline"
    # },

    Set Test Variable  ${uri}  /redfish/v1/Chassis/chassis
    ${resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
    ${chassis}=  redfish_request_utils.Get Attribute  Status  ${resp}
    ${power_state}=  redfish_request_utils.Get Attribute  PowerState  ${resp}
    Log  ${power_state}
    [Return]  ${power_state}  ${chassis["State"]}


Redfish Request Get Boot Progress
    [Documentation]  Return boot progress state.
    # Example: /redfish/v1/Systems/system/
    # "BootProgress": {
    #    "LastState": "OSRunning"
    # },

    Set Test Variable  ${uri}  /redfish/v1/Systems/system/
    ${resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
    ${boot_progress}=  redfish_request_utils.Get Attribute  Status  ${resp}
    ${last_state}=  redfish_request_utils.Get Attribute  BootProgress  ${resp}
    [Return]  ${last_state["LastState"]}  ${boot_progress["State"]}


Redfish Get BMC And Host States
    [Documentation]  Return all the BMC and host states in dictionary.

    ${bmc_state}=  Redfish Request Get BMC State
    ${chassis_state}  ${chassis_status}=  Redfish Request Get Host State
    ${boot_progress}  ${host_state}=  Redfish Request Get Boot Progress

    ${states}=  Create Dictionary
    ...  bmc=${bmc_state}
    ...  chassis=${chassis_state}
    ...  host=${host_state}
    ...  boot_progress=${boot_progress}

    # Disable loggoing state to prevent huge log.html record when boot
    # test is run in loops.
    # Log  ${states}

    [Return]  ${states}

Check BMC At Standby
    [Documentation]  Check if BMC is ready and host at standby.

    ${standby_states}=  Create Dictionary
    ...  bmc=Enabled
    ...  chassis=Off
    ...  host=Disabled
    ...  boot_progress=None

    Wait Until Keyword Succeeds  3 min  10 sec  Redfish Get BMC And Host States

    Wait Until Keyword Succeeds  1 min  10 sec  Match State  ${standby_states}


No Redfish Request Delete Session
    [Documentation]  Redfish delete session.
    [Arguments]  ${session_info}

    # Description of argument(s):
    # session_info      Session information are stored in dictionary.

    # ${session_info} = {
    #     'SessionIDs': 'XXXXXXXXX',
    #     'ClientID': 'XXXXXX',
    #     'SessionToken': 'XXXXXXXXX',
    #     'SessionResp': session response from redfish login
    # }

    # SessionIDs   : Session IDs
    # ClientID     : Client ID
    # SessionToken : Session token
    # SessionResp  : Response of creating an redfish login session

    Set Test Variable  ${uri}  /redfish/v1/SessionService/Sessions/${session_info["SessionIDs"]}
    ${session_resp}=  Redfish DELETE Request URI  ${active_session_info['SessionResp']['headers']}  ${uri}


Redfish Request Delete List Of Session
    [Documentation]  Redfish delete session from list of session records, individual session information
    ...              are stored in dictionary.
    [Arguments]  ${session_info_list}

    # Description of argument(s):
    # session_info_list    List contains individual session record are stored in dictionary.

    # ${session_info_list} = [{
    #     'SessionIDs': 'XXXXXXXXX',
    #     'ClientID': 'XXXXXX',
    #     'SessionToken': 'XXXXXXXXX',
    #     'SessionResp': session response from redfish login
    # }]

    # SessionIDs   : Session IDs
    # ClientID     : Client ID
    # SessionToken : Session token
    # SessionResp  : Response of creating an redfish login session

    FOR  ${session_record}  IN  @{session_info_list}
      Set Test Variable  ${uri}  /redfish/v1/SessionService/Sessions/${session_record["SessionIDs"]}
      ${session_resp}=  Redfish DELETE Request URI  ${active_session_info['SessionResp']['headers']}  ${uri}
    END


Redfish Request Get User Role
    [Documentation]  Get User Role.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name    User name to get it's role.

    Set Test Variable  ${uri}  ${REDFISH_ACCOUNTS_URI}${user_name}
    ${resp}=  Redfish GET Request URI  ${active_session_info['headers']}  ${uri}
    ${role_config}=  redfish_request_utils.Get Attribute  RoleId  ${resp}
    Log  ${role_config}
    [Return]  ${role_config}


Redfish Request Create User
    [Documentation]  Redfish create user.
    [Arguments]   ${user_name}  ${password}  ${role_id}  ${enabled}  ${force}=${False}

    # Description of argument(s):
    # user_name           The user name to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created.
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created.
    #                     should be enabled (${True}, ${False}).
    # force               Delete user account and re-create if force is True.

    ${curr_role}=  Run Keyword And Ignore Error  Redfish Request Get User Role  ${user_name}
    # Ex: ${curr_role} = ('PASS', 'Administrator')

    ${user_exists}=  Run Keyword And Return Status  Should Be Equal As Strings  ${curr_role}[0]  PASS

    # Delete user account when force is True.
    Run Keyword If  ${user_exists} == ${True}
    ...  Run Keywords  Set Test Variable  ${uri}  ${REDFISH_ACCOUNTS_URI}${user_name}  AND
    ...  Redfish DELETE Request URI  ${active_session_info['headers']}  ${uri}


    ${curr_role}=  Run Keyword And Ignore Error  Redfish Request Get User Role  ${user_name}
    ${user_exists}=  Run Keyword And Return Status  Should Be Equal As Strings  ${curr_role}[0]  PASS

    # Create specified user when force is True or User does not exist.
    ${payload}=  Create Dictionary
    ...  UserName=${user_name}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}

    Set Test Variable  ${uri}  ${REDFISH_ACCOUNTS_URI}

    Run Keyword If  ${force} == ${True} or ${user_exists} == ${False}
    ...  Redfish POST Request URI  ${active_session_info['headers']}  ${uri}  ${payload}  status_code=${HTTP_CREATED}

