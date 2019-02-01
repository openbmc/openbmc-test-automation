*** Settings ***
Documentation   BMC redfish utils

Resource        lib/resource.txt
Resource        lib/bmc_redfish_resource.robot
Resource        lib/common_utils.robot


*** Keywords ***

Redfish Power Operations
    [Documentation]  Do Redfish power operations
    [Arguments]      ${input_cmd}
    # Description of arguments:
    # input_cmd    On/ForceOff/GracefulRestart/GracefulShutdown

    redfish.Login
    ${payload}=  Create Dictionary  ResetType=${input_cmd}
    ${resp}=  redfish.Post  Systems/1/Actions/ComputerSystem.Reset  body=&{payload}
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
