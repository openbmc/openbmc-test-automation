*** Settings ***
Documentation    Verify that Redfish software inventory can be collected.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Library          ../../lib/gen_robot_valid.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

*** Test Cases ***

Verify Redfish Update Service Enabled
    [Documentation]  Verify "ServiceEnabled" is enabled.
    [Tags]  Verify_Update_Service_Enabled

    # Example:
    # "HttpPushUri": "/redfish/v1/UpdateService",
    # "Id": "UpdateService",
    # "Name": "Update Service",
    # "ServiceEnabled": true

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService
    Should Be Equal As Strings  ${resp.dict["ServiceEnabled"]}  ${True}


Verify Redfish Software Inventory Collection
    [Documentation]  Verify software inventory collection member and object entries.
    [Tags]  Verify_Redfish_Software_Inventory_Collection

    # Example:
    # {
    #    "@odata.type": "#SoftwareInventoryCollection.SoftwareInventoryCollection",
    #    "Members": [
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a3522998"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/a7c79f71"
    #      },
    #      {
    #        "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/ace821ef"
    #      }
    #   ],
    #   "Members@odata.count": 3,
    #   "Name": "Software Inventory Collection"
    # }

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory

    Should Be True  ${resp.dict["Members@odata.count"]} >= ${1}
    Length Should Be  ${resp.dict["Members"]}  ${resp.dict["Members@odata.count"]}


Redfish Software Inventory Status Check
    [Documentation]  Get firmware inventory entries and do health check status.
    [Tags]  Redfish_Software_Inventory_Status_Check

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory

    # Entries "Members@odata.count": 3,
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a3522998'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a7c79f71'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/ace821ef'}

    FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
      ${resp_resource}=  Redfish.Get  ${resp.dict["Members"][${entry}]["@odata.id"]}
    # Example:
    # "Status": {
    #     "Health": "OK",
    #     "HealthRollup": "OK",
    #     "State": "Enabled"
    # },
      Should Be Equal As Strings  ${resp_resource.dict["Status"]["Health"]}  OK
      Should Be Equal As Strings  ${resp_resource.dict["Status"]["HealthRollup"]}  OK
      Should Be Equal As Strings  ${resp_resource.dict["Status"]["State"]}  Enabled
    END


Verify BMC Version Matches With FirmwareInventory
    [Documentation]  Verify BMC version from FirmwareInventory same as in manager.
    [Tags]  Verify_BMC_Version_Matches_With_FirmwareInventory

    ${bmc_manager}=  Redfish.Get  /redfish/v1/Managers/bmc
    ${manager_bmc_version}=  Get BMC Version
    # Check for manager version and cat /etc/os-release.
    Should Be Equal As Strings
    ...  ${bmc_manager.dict["FirmwareVersion"]}  ${manager_bmc_version.strip('"')}

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory

    # Entries "Members@odata.count": 3,
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a3522998'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/a7c79f71'}
    # {'@odata.id': '/redfish/v1/UpdateService/FirmwareInventory/ace821ef'}

    ${actual_count}=  Evaluate  ${resp.dict["Members@odata.count"]}-1
    FOR  ${entry}  IN RANGE  0  ${resp.dict["Members@odata.count"]}
      ${resp_resource}=  Redfish.Get  ${resp.dict["Members"][${entry}]["@odata.id"]}
    # 3rd comparison of BMC version and verify FirmwareInventory bmc version.
    # Example:
    # "Version": 2.7.0-dev-19-g9b44ea7
      Exit For Loop If  '${resp_resource.dict["Version"]}' == '${manager_bmc_version.strip('"')}'
      Run Keyword If  '${entry}' == '${actual_count}'  Fail  BMC version not there in Firmware Inventory
    END

Verify UpdateService Supports TransferProtocol TFTP
    [Documentation]  Verify update service supported values have TFTP protocol.
    [Tags]  Verify_UpdateService_Supports_TransferProtocol_TFTP

    # Example:
    #   "Actions": {
    #     "#UpdateService.SimpleUpdate": {
    #       "TransferProtocol@Redfish.AllowableValues": [
    #         "TFTP"
    #       ],
    #       "target": "/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate"
    #     }
    #  },

    ${allowable_values}=  Redfish.Get Attribute  /redfish/v1/UpdateService  Actions

    Valid Value
    ...  allowable_values["#UpdateService.SimpleUpdate"]["TransferProtocol@Redfish.AllowableValues"][0]
    ...  valid_values=['TFTP']
    Valid Value  allowable_values["#UpdateService.SimpleUpdate"]["target"]
    ...  valid_values=['/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate']


Verify Redfish BIOS Version
    [Documentation]  Get host firmware version from system inventory.
    [Tags]  Verify_Redfish_BIOS_Version

    ${bios_version}=  Redfish.Get Attribute  /redfish/v1/Systems/system/  BiosVersion
    ${pnor_version}=  Get PNOR Version
    Should Be Equal  ${pnor_version}  ${bios_version}


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Redfish.Logout
