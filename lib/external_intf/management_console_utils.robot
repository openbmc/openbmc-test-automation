*** Settings ***
Documentation    Management console utilities keywords.

Resource         ../../lib/bmc_redfish_utils.robot
Library          ../../lib/gen_robot_valid.py
Library          Collections
Library          ../../lib/bmc_ssh_utils.py
Library          SSHLibrary

*** Variables ***
&{daemon_command}  start=systemctl start avahi-daemon
                  ...  stop=systemctl stop avahi-daemon
                  ...  status=systemctl status avahi-daemon -l
&{daemon_message}  start=Active: active (running)
                  ...  stop=Active: inactive (dead)

*** Keywords ***

Set AvahiDaemon Service
    [Documentation]  To enable or disable avahi service.
    [Arguments]  ${command}

    # Description of argument(s):
    # command  Get command from dictionary.

    ${service_command}=  Get From Dictionary  ${daemon_command}  ${command}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Be Equal As Integers  ${rc}  0


Verify AvahiDaemon Service Status
    [Documentation]  To check for avahi service.
    [Arguments]  ${message}

    # Description of argument(s):
    # message  Get status message from dictionary.

    ${service_command}=  Get From Dictionary  ${daemon_command}  status
    ${service_message}=  Get From Dictionary  ${daemon_message}  ${message}
    ${resp}  ${stderr}  ${rc}=  BMC Execute Command  ${service_command}  print_out=1
    Should Contain  ${resp}  ${service_message}


Create Session With ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    ${session_info}=  Create Dictionary
    ${session_resp}=  Redfish Login  kwargs= "Oem":{"OpenBMC" : {"ClientID":"${client_id}"}}

    Set To Dictionary  ${session_info}  SessionIDs  ${session_resp['Id']}
    Set To Dictionary  ${session_info}  ClientID  ${session_resp["Oem"]["OpenBMC"]["ClientID"]}
    Set To Dictionary  ${session_info}  SessionToken  ${XAUTH_TOKEN}
    Set To Dictionary  ${session_info}  SessionResp  ${session_resp}

    [Return]  ${session_info}


Create Session With List Of ClientID
    [Documentation]  Create redifish session with client id.
    [Arguments]  ${client_id}

    # Description of argument(s):
    # client_id    This client id can contain string value
    #              (e.g. 12345, "EXTERNAL-CLIENT").

    @{session_dict_list}=  Create List
    &{session_dict}=  Create Dictionary

    FOR  ${client}  IN  @{client_id}
      ${session_dict}=  Create Session With ClientID  ${client}
      Append To List  ${session_dict_list}  ${session_dict}
    END

    [Return]  ${session_dict_list}


Verify A Session Created With ClientID
    [Documentation]  Verify the session is created.
    [Arguments]  ${client_id}  ${session_ids}

    # Description of argument(s):
    # client_id    External client name.
    # session_id   This value is a session id.

    # {
    #   "@odata.id": "/redfish/v1/SessionService/Sessions/H8q2ZKucSJ",
    #   "@odata.type": "#Session.v1_0_2.Session",
    #   "Description": "Manager User Session",
    #   "Id": "H8q2ZKucSJ",
    #   "Name": "User Session",
    #   "Oem": {
    #   "OpenBMC": {
    #  "@odata.type": "#OemSession.v1_0_0.Session",
    #  "ClientID": "",
    #  "ClientOriginIP": "::ffff:x.x.x.x"
    #       }
    #     },
    #   "UserName": "root"
    # }

    FOR  ${client}  ${session}  IN ZIP  ${client_id}  ${session_ids}
      ${session_resp}=  Redfish.Get Properties  /redfish/v1/SessionService/Sessions/${session["SessionIDs"]}
      Rprint Vars  session_resp
      @{words} =  Split String  ${session_resp["ClientOriginIPAddress"]}  :
      ${ip_address}=  Get Running System IP
      Set Test Variable  ${temp_ipaddr}  ${words}[-1]
      Valid Value  client  ['${session_resp["Oem"]["OpenBMC"]["ClientID"]}']
      Valid Value  session["SessionIDs"]  ['${session_resp["Id"]}']
      Valid Value  temp_ipaddr  ${ip_address}
    END


Get Lock Resource Information
    [Documentation]  Get lock resource information.

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${resource_lock_json}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/resource_lock_table.json'))  modules=json
    Rprint Vars  resource_lock_json

    [Return]  ${resource_lock_json}
