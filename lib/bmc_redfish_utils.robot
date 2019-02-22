*** Settings ***
Documentation   BMC redfish utils.

Resource        resource.robot
Resource        bmc_redfish_resource.robot


*** Keywords ***

Redfish Power Operation
    [Documentation]  Do Redfish power operation.
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
    #  "target": "/redfish/v1/Systems/motherboard/Actions/ComputerSystem.Reset"
    #  }}

    redfish.Login
    ${payload}=  Create Dictionary  ResetType=${reset_type}
    ${resp}=  redfish.Post  Systems/1/Actions/ComputerSystem.Reset  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    redfish.Logout


Redfish BMC Reset Operation
    [Documentation]  Do Redfish reset operation.

    # Example:
    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
    # }

    redfish.Login
    ${payload}=  Create Dictionary  ResetType=GracefulRestart
    ${resp}=  redfish.Post  Managers/bmc/Actions/Manager.Reset  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
