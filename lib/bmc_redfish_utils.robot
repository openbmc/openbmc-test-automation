*** Settings ***
Documentation   BMC redfish utils.

Resource        lib/resource.txt
Resource        lib/bmc_redfish_resource.robot

*** Keywords ***

Redfish Power Operations
    [Documentation]  Do Redfish power operations.
    [Arguments]      ${rest_type}
    # Description of arguments:
    # rest_type    On/ForceOff/GracefulRestart/GracefulShutdown

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
    ${payload}=  Create Dictionary  ResetType=${rest_type}
    ${resp}=  redfish.Post  Systems/1/Actions/ComputerSystem.Reset  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    redfish.Logout
