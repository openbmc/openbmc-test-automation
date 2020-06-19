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

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/system/  ComputerSystem.Reset
    ${payload}=  Create Dictionary  ResetType=${reset_type}
    ${resp}=  Redfish.Post  ${target}  body=&{payload}


Redfish BMC Reset Operation
    [Documentation]  Do Redfish BMC reset operation.

    # Example:
    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
    # }

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Managers/bmc/  Manager.Reset
    ${payload}=  Create Dictionary  ResetType=GracefulRestart
    Redfish.Post  ${target}  body=&{payload}


Reset BIOS Via Redfish
    [Documentation]  Do BIOS reset through Redfish.

    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/system/Bios/  Bios.ResetBios
    Redfish.Post  ${target}  valid_status_codes=[${HTTP_OK}]


Delete All Redfish Sessions
    [Documentation]  Delete all active redfish sessions.

    ${saved_session_info}=  Get Redfish Session Info

    ${resp_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/SessionService/Sessions

    # Remove the current login session from the list.
    Remove Values From List  ${resp_list}  ${saved_session_info["location"]}

    FOR  ${session}  IN  @{resp_list}
        Redfish.Delete  ${session}
    END

Get Valid FRUs
    [Documentation]  Return a dictionary containing all of the valid FRU records for the given fru_type.
    [Arguments]  ${fru_type}

    # NOTE: A valid FRU record will have a "State" key of "Enabled" and a "Health" key of "OK".

    # Description of argument(s):
    # fru_type  The type of fru (e.g. "Processors", "Memory", etc.).

    ${fru_records}=  Redfish_Utils.Enumerate Request
    ...  /redfish/v1/Systems/system/${fru_type}  return_json=0
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
    # users    Dictionary of roles and user credentails to be created.
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

