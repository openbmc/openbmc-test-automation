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
    #    "GracefulRestart",
    #    "GracefulShutdown"
    #  ],
    #  "target": "/redfish/v1/Systems/system/Actions/ComputerSystem.Reset"
    #  }
    # }

    Redfish.Login
    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/system/  ComputerSystem.Reset
    ${payload}=  Create Dictionary  ResetType=${reset_type}
    ${resp}=  Redfish.Post  ${target}  body=&{payload}
    Redfish.Logout


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

    Redfish.Login
    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Managers/bmc/  Manager.Reset
    ${payload}=  Create Dictionary  ResetType=GracefulRestart
    ${resp}=  Redfish.Post  ${target}  body=&{payload}
    # The logout may very well fail because the system was just asked to
    # reset itself.
    Run Keyword And Ignore Error  Redfish.Logout


Delete All Redfish Sessions
    [Documentation]  Delete all active redfish sessions.

    Redfish.Login
    ${saved_session_info}=  Get Redfish Session Info

    ${resp_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/SessionService/Sessions

    # Remove the current login session from the list.
    Remove Values From List  ${resp_list}  ${saved_session_info["location"]}

    :FOR  ${session}  IN  @{resp_list}
    \  Redfish.Delete  ${session}

    Redfish.Logout


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
    [Arguments]   ${username}  ${password}  ${role_id}  ${enabled}  ${force}=${False}

    # Description of argument(s):
    # username            The username to be created.
    # password            The password to be assigned.
    # role_id             The role ID of the user to be created
    #                     (e.g. "Administrator", "Operator", etc.).
    # enabled             Indicates whether the username being created
    #                     should be enabled (${True}, ${False}).
    # force               Delete user account and re-create if force is True

    Redfish.Login

    # Delete and re-create user account if force is True
    Run Keyword If  ${force} == ${True}  Redfish.Delete  ${REDFISH_ACCOUNTS_URI}${userName}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NOT_FOUND}]

    # Create specified user.
    ${payload}=  Create Dictionary
    ...  UserName=${username}  Password=${password}  RoleId=${role_id}  Enabled=${enabled}
    Redfish.Post  ${REDFISH_ACCOUNTS_URI}  body=&{payload}
    ...  valid_status_codes=[${HTTP_CREATED}]

    # Validate Role ID of created user.
    ${role_config}=  Redfish_Utils.Get Attribute
    ...  ${REDFISH_ACCOUNTS_URI}${username}  RoleId
    Should Be Equal  ${role_id}  ${role_config}


Create Users With Different Roles
    [Documentation]  Create users with different roles.
    [Arguments]  ${users}

    # Ex:  {'Administrator': '[admin_user, TestPwd123]', 'Operator': '[operator_user, TestPwd123]'}
    :FOR    ${role}  IN  @{users}
    \  Log To Console  ${role}  ${users['${role}']}[0]  ${users['${role}']}[1]
    \  Redfish Create User  ${users['${role}'][0]}  ${users['${role}']}[1]  ${role}  ${True}  ${True}

#    Redfish Create User  admin_user  TestPwd123  Administrator  ${True}  ${True}
#    Redfish Create User  operator_user  TestPwd123  Operator  ${True}  ${True}


