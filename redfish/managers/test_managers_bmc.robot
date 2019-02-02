*** Settings ***
Resource         ../../lib/resource.txt
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot

Suite Teardown   redfish.Logout

*** Test Cases ***

Verify BMC Firmware Version
    [Documentation]  Get firmware version from BMC manager.
    [Tags]  Verify_BMC_Firmware_Version

    redfish.Login
    ${resp}=  redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    ${bmc_version}=  Get BMC Version
    Should Be Equal As Strings
    ...  ${resp.dict["FirmwareVersion"]}  ${bmc_version.strip('"')}
    redfish.Logout


Verify BMC Manager Properties
    [Documentation]  Verify BMC managers resource properties.
    [Tags]  Verify_BMC_Manager_Properties

    redfish.Login
    ${resp}=  redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    # Example:
    #  "Description": "Baseboard Management Controller"
    #  "Id": "bmc"
    #  "Model": "OpenBmc",
    #  "Name": "OpenBmc Manager",
    #  "UUID": "xxxxxxxx-xxx-xxx-xxx-xxxxxxxxxxxx"
    #  "PowerState": "On"

    Should Be Equal As Strings
    ...  ${resp.dict["Description"]}  Baseboard Management Controller
    Should Be Equal As Strings  ${resp.dict["Id"]}  bmc
    Should Be Equal As Strings  ${resp.dict["Model"]}  OpenBmc
    Should Be Equal As Strings  ${resp.dict["Name"]}  OpenBmc Manager
    Should Not Be Empty  ${resp.dict["UUID"]}
    Should Be Equal As Strings  ${resp.dict["PowerState"]}  On
    redfish.Logout


Test BMC Manager GracefulRestart
    [Documentation]  BMC graceful restart.
    [Tags]  Test_BMC_Manager_GracefulRestart

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

    # TODO: Add logic to ping and check BMC online state



