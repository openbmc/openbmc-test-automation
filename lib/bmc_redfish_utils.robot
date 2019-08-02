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
    ${resp}=  Redfish.Post  ${target}  body=&{payload}
    # The logout may very well fail because the system was just asked to
    # reset itself.


Delete All Redfish Sessions
    [Documentation]  Delete all active redfish sessions.

    ${saved_session_info}=  Get Redfish Session Info

    ${resp_list}=  Redfish_Utils.Get Member List
    ...  /redfish/v1/SessionService/Sessions

    # Remove the current login session from the list.
    Remove Values From List  ${resp_list}  ${saved_session_info["location"]}

    :FOR  ${session}  IN  @{resp_list}
    \  Redfish.Delete  ${session}


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
