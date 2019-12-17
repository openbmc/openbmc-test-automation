
*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Resource        ../../lib/bmc_redfish_utils.robot

*** Variables ***




*** Test Cases **


Redfish System Reset Bios Operation

    [Documentation]  Do Redfish System  reset Bios  operation.
    # Example
    #"Actions": {"
    #Bios.ResetBios": {"
    #target": "/redfish/v1/Systems/system/Bios/Actions/Bios.ResetBios"
    # }
                
    Redfish.Login
    ${target}=  redfish_utils.Get Target Actions  /redfish/v1/Systems/system/Bios  Bios.ResetBios
    ${payload}=  Create Dictionary  ResetType=GracefulRestart
    ${resp}=  Redfish.Post  ${target}  body=&{payload}
    Redfish.Logout
