*** Settings ***
Documentation   BMC and host redfish utility keywords.

Resource        resource.robot
Resource        bmc_redfish_resource.robot


*** Keywords ***

Redfish Power Operation
    [Documentation]  Do Redfish host power operation.
    [Arguments]      ${reset_type}

    # Description of arguments:
    # reset_type     Type of power operation.
    #                (e.g. On/ForceOff/GracefulRestart/GracefulShutdown)

    # Example:
    # "Actions": {
    # "#ComputerSystem.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "On",
    #    "ForceOff",
    #    "ForceOn",
    #    "ForceRestart",
    #    "GracefulRestart",
    #    "GracefulShutdown"
    #    "PowerCycle",
    #    "Nmi"
    #  ],
    #  "target": "/redfish/v1/Systems/system/Actions/ComputerSystem.Reset"
    #  }
    # }

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/${SYSTEM_ID}/  ComputerSystem.Reset
    ${payload}=  Create Dictionary  ResetType=${reset_type}
    ${header}=  Create Dictionary  Content-Type=application/json
    ${resp}=  Redfish.Post  ${target}  body=&{payload}  headers=&{header}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Redfish BMC Reset Operation
    [Documentation]  Do Redfish BMC reset operation.
    [Arguments]  ${reset_type}=GracefulRestart

    # Example:
    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart",
    #    "ForceRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/${MANAGER_ID}/Actions/Manager.Reset"
    # }

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Managers/${MANAGER_ID}/  Manager.Reset
    ${payload}=  Create Dictionary  ResetType=${reset_type}
    Redfish.Post  ${target}  body=&{payload}


Reset BIOS Via Redfish
    [Documentation]  Do BIOS reset through Redfish.

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/${SYSTEM_ID}/Bios/  Bios.ResetBios
    Redfish.Post  ${target}  valid_status_codes=[${HTTP_OK}]


Set Redfish Delete Session Flag
    [Documentation]  Disable or enable delete redfish while performing the power operation keyword.
    [Arguments]  ${set_flag}

    # Description of argument(s):
    # set_flag    Set user specified enable(1) or disable(0).

    Set Suite Variable  ${REDFISH_DELETE_SESSIONS}  ${set_flag}


Redfish Delete Session
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

    Redfish.Delete  /redfish/v1/SessionService/Sessions/${session_info["SessionIDs"]}


Redfish Delete List Of Session
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
      Redfish.Delete  /redfish/v1/SessionService/Sessions/${session_record["SessionIDs"]}
    END


Delete All Redfish Sessions
    [Documentation]  Delete all active redfish sessions.

    ${saved_session_info}=  Redfish_Utils.Get Redfish Session Info

    ${resp_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/SessionService/Sessions

    # Remove the current login session from the list.
    Remove Values From List  ${resp_list}  ${saved_session_info["location"]}

    # Remove session with client_id populated from the list.
    ${client_id_list}=  Get Session With Client Id  ${resp_list}
    Log To Console  Client sessions skip list: ${client_id_list}
    FOR  ${client_session}  IN  @{client_id_list}
        Remove Values From List  ${resp_list}  ${client_session}
    END

    FOR  ${session}  IN  @{resp_list}
        Run Keyword And Ignore Error  Redfish.Delete  ${session}
    END


Get Session With Client Id
    [Documentation]  Iterate through the active sessions and return sessions
    ...              populated with Context.
    [Arguments]  ${session_list}

    # Description of argument(s):
    # session_list   Active session list from SessionService.

    # "@odata.type": "#Session.v1_5_0.Session",
    # "ClientOriginIPAddress": "xx.xx.xx.xx",
    # "Context": "MYID-01"

    ${client_id_sessions}=  Create List
    FOR  ${session}  IN  @{session_list}
        ${resp}=  Redfish.Get  ${session}   valid_status_codes=[200,404]
        # This prevents dictionary KeyError exception when the Context
        # attribute is not populated in generic session response.
        ${context_var}=  Get Variable Value  ${resp.dict["Context"]}  ${EMPTY}
        # Handle backward compatibility for OEM.
        ${oem_var}=  Get Variable Value  ${resp.dict["Oem"]["OpenBMC"]["ClientID"]}  ${EMPTY}
        Run Keyword If  '${context_var}' != '${EMPTY}'
        ...    Append To List  ${client_id_sessions}  ${session}
        Run Keyword If  '${oem_var}' != '${EMPTY}'
        ...    Append To List  ${client_id_sessions}  ${session}
    END

    [Return]  ${client_id_sessions}


Get Valid FRUs
    [Documentation]  Return a dictionary containing all of the valid FRU records for the given fru_type.
    [Arguments]  ${fru_type}

    # NOTE: A valid FRU record will have a "State" key of "Enabled" and a "Health" key of "OK".

    # Description of argument(s):
    # fru_type  The type of fru (e.g. "Processors", "Memory", etc.).

    ${fru_records}=  Redfish_Utils.Enumerate Request
    ...  /redfish/v1/Systems/${SYSTEM_ID}/${fru_type}  return_json=0
    ${fru_records}=  Filter Struct  ${fru_records}  [('State', 'Enabled'), ('Health', 'OK')]

    [Return]  ${fru_records}


Get Num Valid FRUs
    [Documentation]  Return the number of valid FRU records for the given fru_type.
    [Arguments]  ${fru_type}

    # Description of argument(s):
    # fru_type  The type of fru (e.g. "Processors", "Memory", etc.).

    ${fru_records}=  Get Valid FRUs  ${fru_type}
    ${num_valid_frus}=  Get length  ${fru_records}

    [Return]  ${num_valid_frus}


Verify Valid Records
    [Documentation]  Verify all records retrieved with the given arguments are valid.
    [Arguments]  ${record_type}  ${redfish_uri}  ${reading_type}

    # Description of Argument(s):
    # record_type    The sensor record type (e.g. "PowerSupplies")
    # redfish_uri    The power supply URI (e.g. /redfish/v1/Chassis/chassis/Power)
    # reading_type   The power watt readings (e.g. "PowerInputWatts")

    # A valid record will have "State" key "Enabled" and "Health" key "OK".
    ${records}=  Redfish.Get Attribute  ${redfish_uri}  ${record_type}

    Rprint Vars  records

    # Example output:
    # records:
    #   [0]:
    #     [@odata.id]:                 /redfish/v1/Chassis/chassis/Power#/PowerControl/0
    #     [@odata.type]:               #Power.v1_0_0.PowerControl
    #     [MemberId]:                  0
    #     [Name]:                      Chassis Power Control
    #     [PowerConsumedWatts]:        264.0
    #     [PowerLimit]:
    #       [LimitInWatts]:            None
    #     [PowerMetrics]:
    #       [AverageConsumedWatts]:    325
    #       [IntervalInMin]:           3
    #       [MaxConsumedWatts]:        538
    #     [Status]:
    #       [Health]:                  OK
    #       [State]:                   Enabled

    ${invalid_records}=  Filter Struct  ${records}
    ...  [('Health', '^OK$'), ('State', '^Enabled$'), ('${reading_type}', '')]  regex=1  invert=1
    Valid Length  invalid_records  max_length=0

    [Return]  ${records}


Redfish Create User
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

    ${curr_role}=  Run Keyword And Ignore Error  Get User Role  ${user_name}
    # Ex: ${curr_role} = ('PASS', 'Administrator')

    ${user_exists}=  Run Keyword And Return Status  Should Be Equal As Strings  ${curr_role}[0]  PASS

    # Delete user account when force is True.
    Run Keyword If  ${force} == ${True}  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${user_name}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user when force is True or User does not exist.
    ${payload}=  Create Dictionary
    ...  UserName=${user_name}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}

    Run Keyword If  ${force} == ${True} or ${user_exists} == ${False}
    ...  Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]


Get User Role
    [Documentation]  Get User Role.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name    User name to get it's role.

    ${role_config}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_URI}${user_name}  RoleId

    [Return]  ${role_config}


Create Users With Different Roles
    [Documentation]  Create users with different roles.
    [Arguments]  ${users}  ${force}=${False}

    # Description of argument(s):
    # users    Dictionary of roles and user credentials to be created.
    #          Ex:  {'Administrator': '[admin_user, TestPwd123]', 'Operator': '[operator_user, TestPwd123]'}
    # force    Delete given user account if already exists when force is True.

    FOR  ${role}  IN  @{users}
      Redfish Create User  ${users['${role}'][0]}  ${users['${role}']}[1]  ${role}  ${True}  ${force}
    END


Delete BMC Users Via Redfish
    [Documentation]  Delete BMC users via redfish.
    [Arguments]  ${users}

    # Description of argument(s):
    # users    Dictionary of roles and user credentials to be deleted.

    FOR  ${role}  IN  @{users}
        Redfish.Delete  /redfish/v1/AccountService/Accounts/${users['${role}'][0]}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]
    END


Expire And Update New Password Via Redfish
    [Documentation]  Expire and change password and verify using password.
    [Arguments]  ${username}  ${password}  ${new_password}

    # Description of argument(s):
    # username        The username to be used to login to the BMC.
    # password        The password to be used to login to the BMC.
    # new_password    The new password to be used to update password.

    # Expire admin password using ssh.
    Open Connection And Log In  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  passwd --expire ${username}
    Should Contain Any  ${output}  password expiry information changed
    ...  password changed

    # Verify user password expired using Redfish
    Verify User Password Expired Using Redfish  ${username}  ${password}

    # Change user password.
    Redfish.Patch  /redfish/v1/AccountService/Accounts/${username}
    ...  body={'Password': '${new_password}'}
    Redfish.Logout


Verify User Password Expired Using Redfish
    [Documentation]  Checking whether user password expired or not using redfish.
    [Arguments]  ${username}  ${password}  ${expected_result}=${True}

    # Description of argument(s):
    # username        The username to be used to login to the BMC.
    # password        The password to be used to login to the BMC.

    Redfish.Login  ${username}  ${password}
    ${resp}=  Redfish.Get  /redfish/v1/AccountService/Accounts/${username}
    Should Be Equal  ${resp.dict["PasswordChangeRequired"]}  ${expected_result}


Is BMC LastResetTime Changed
    [Documentation]  Return fail if BMC last reset time is not changed.
    [Arguments]  ${reset_time}

    # Description of argument(s):
    # reset_time  Last BMC reset time.

    ${last_reset_time}=  Get BMC Last Reset Time
    Should Not Be Equal  ${last_reset_time}  ${reset_time}


Redfish BMC Reboot
    [Documentation]  Use Redfish API reboot BMC and wait for BMC ready.

    #  Get BMC last reset time for compare
    ${last_reset_time}=  Get BMC Last Reset Time

    # Reboot BMC by Redfish API
    Redfish BMC Reset Operation

    # Wait for BMC real reboot and Redfish API ready
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC LastResetTime Changed  ${last_reset_time}


Get BMC Last Reset Time
    [Documentation]  Return BMC LastResetTime.

    ${last_reset_time}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  LastResetTime

    [Return]  ${last_reset_time}
