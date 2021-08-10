*** Settings ***
Documentation    Verify that Redfish software inventory can be collected.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/redfish_code_update_utils.robot
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


Verify Redfish Software Hex ID
    [Documentation]  Verify BMC images have valid 8-digit hex IDs.
    [Tags]  Verify_Redfish_Software_Hex_ID

    ${sw_inv_dict}=  Get Software Inventory State

    FOR  ${id_key}  IN  @{sw_inv_dict}
      ${sw_inv}=  Get From Dictionary  ${sw_inv_dict}  ${id_key}
      Should Be Equal As Strings  ${id_key}  ${sw_inv['image_id']}
      Length Should Be  ${sw_inv['image_id']}  ${8}
      Should Match Regexp  ${sw_inv['image_id']}  [0-9a-f]*
    END


Verify Redfish FirmwareInventory Is Updateable
    [Documentation]  Verify the redfish firmware inventory path is updateable.
    [Tags]  Verify_Redfish_FirmwareInventory_Is_Updateable

    ${sw_member_list}=  Redfish_Utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory

    # sw_member_list:
    #   [0]:                            /redfish/v1/UpdateService/FirmwareInventory/98744d76
    #   [1]:                            /redfish/v1/UpdateService/FirmwareInventory/9a8028ec
    #   [2]:                            /redfish/v1/UpdateService/FirmwareInventory/acc9e073

    FOR  ${sw_member}  IN  @{sw_member_list}
      ${resp}=  Redfish.Get Attribute  ${sw_member}  Updateable

      # Example:
      # "Updateable": true,

      Should Be Equal As Strings  ${resp}  True
    END


Check Redfish Functional Image Version Is Same
    [Documentation]  Verify functional image version is same as in Redfish managers.
    [Tags]  Check_Redfish_Functional_Image_Version_Is_Same
    [Template]  Verify Redfish Functional Image Version Is Same

    # image
    functional_image
    backup_image


Check Redfish Backup Image Version Is Same
    [Documentation]  Switch to backup image and then verify functional image version
    ...  is same as in Redfish managers..
    [Tags]  Check_Redfish_Backup_Image_Version_Is_Same
    [Template]  Verify Redfish Functional Image Version Is Same

    # image
    switch_backup_image


Verify Redfish Software Image And Firmware Inventory Are Same
    [Documentation]  Verify the firmware software inventory is same as software images of managers.
    [Tags]  Verify_Redfish_Software_Image_And_Firmware_Inventory_Are_Same

    # SoftwareImages
    # /redfish/v1/UpdateService/FirmwareInventory/632c5114
    # /redfish/v1/UpdateService/FirmwareInventory/e702a011

    ${firmware_inv_path}=  Redfish.Get Properties  ${REDFISH_BASE_URI}Managers/bmc
    ${firmware_inv_path}=  Get From Dictionary  ${firmware_inv_path}  Links
    ${sw_image}=  Get From Dictionary  ${firmware_inv_path}  SoftwareImages

    ${sw_member_list}=  Redfish_Utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory

    FOR  ${sw_inv_path}  IN  @{sw_image}
      List Should Contain Value  ${sw_member_list}  ${sw_inv_path['@odata.id']}
    END

    ${num_records_sw_image}=  Get Length  ${sw_image}
    ${num_records_sw_inv}=  Get Length  ${sw_member_list}
    Should Be Equal  ${num_records_sw_image}  ${num_records_sw_inv}


Check If Firmware Image Is Same In Firmware Inventory And Redfish Read Operation
    [Documentation]  Check the Redfish firmware inventory path is same as in
    ...  active software image of Redfish managers and firmware inventory of update service.
    [Tags]  Check_If_Firmware_Image_Is_Same_In_Firmware_Inventory_And_Redfish_Read_Operation

    Verify Active Software Image And Firmware Inventory Is Same


Check If Backup Firmware Image Is Same In Firmware Inventory And Redfish Read Operation
    [Documentation]  Check the Redfish backup image firmware inventory path is same as in
    ...  active software image of Redfish managers and firmware inventory of update service.
    [Tags]  Check_If_Backup_Firmware_Image_Is_Same_In_Firmware_Inventory_And_Redfish_Read_Operation

    Verify Active Software Image And Firmware Inventory Is Same
    Set Backup Firmware Image As Functional
    Verify Active Software Image And Firmware Inventory Is Same
    Set Backup Firmware Image As Functional
    Verify Active Software Image And Firmware Inventory Is Same


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


Verify Firmware Version Same In Firmware Inventory And Managers
    [Documentation]  Verify the Redfish firmware inventory path version is same as Redfish managers.

    # User defined state for software objects.
    # Note: "Functional" term refers to firmware which system is currently booted with.

    # sw_inv_dict:
    #   [b9101858]:
    #     [image_type]:                 BMC update
    #     [image_id]:                   b9101858
    #     [functional]:                 True
    #     [version]:                    2.8.0-dev-150-g04508dc9f

    ${sw_inv_list}=  Get Functional Firmware  BMC image
    ${sw_inv_dict}=  Get Non Functional Firmware  ${sw_inv_list}  True

    # /redfish/v1/Managers/bmc
    # "FirmwareVersion": "2.8.0-dev-150-g04508dc9f"

    ${firmware_version}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Managers/bmc  FirmwareVersion

    Should Be Equal  ${sw_inv_dict['version']}  ${firmware_version}


Verify Firmware Version Is Not Same In Firmware Inventory And Managers
    [Documentation]  Verify the Redfish firmware inventory path version is not same as
    ...  Redfish managers for backup image.

    # User defined state for software objects.
    # Note: "Functional" term refers to firmware which system is currently booted with.

    # sw_inv_dict:
    #   [b9101858]:
    #     [image_type]:                 BMC update
    #     [image_id]:                   b9101858
    #     [functional]:                 True
    #     [version]:                    2.8.0-dev-150-g04508dc9f

    ${sw_inv_list}=  Get Functional Firmware  BMC image
    ${sw_inv_list}=  Get Non Functional Firmware List  ${sw_inv_list}  False

    # /redfish/v1/Managers/bmc
    # "FirmwareVersion": "2.8.0-dev-150-g04508dc9f"

    ${firmware_version}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Managers/bmc  FirmwareVersion

    FOR  ${sw_inv}  IN  @{sw_inv_list}
      Should Not Be Equal  ${sw_inv['version']}  ${firmware_version}
    END


Set Backup Firmware Image As Functional
    [Documentation]  Switch to the backup firmware image to make functional.

    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Switch Backup Firmware Image To Functional
    Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}


Verify Redfish Functional Image Version Is Same
    [Documentation]  Verify the functional image version is same as in firmware inventory and managers.
    [Arguments]  ${image}

    # Description of argument(s):
    # image           Fucntional Image or Backup Image

    Verify Firmware Version Same In Firmware Inventory And Managers

    Run Keyword If  'backup_image' == '${image}'
    ...  Verify Firmware Version Is Not Same In Firmware Inventory And Managers

    Run Keyword If  'switch_backup_image' == '${image}'
    ...  Run Keywords  Set Backup Firmware Image As Functional  AND
    ...    Verify Firmware Version Same In Firmware Inventory And Managers  AND
    ...    Set Backup Firmware Image As Functional  AND
    ...    Verify Firmware Version Same In Firmware Inventory And Managers


Verify Active Software Image And Firmware Inventory Is Same
    [Documentation]  Verify Redfish firmware inventory path and active software image is same.

    # ActiveSoftwareImage
    # /redfish/v1/UpdateService/FirmwareInventory/632c5114

    # Firmware Inventory
    # /redfish/v1/UpdateService/FirmwareInventory
    # /redfish/v1/UpdateService/FirmwareInventory/632c5114
    # /redfish/v1/UpdateService/FirmwareInventory/632c5444

    ${firmware_inv_path}=  Redfish.Get Properties  ${REDFISH_BASE_URI}Managers/bmc
    ${firmware_inv_path}=  Get From Dictionary  ${firmware_inv_path}  Links
    ${active_sw_image}=  Get From Dictionary  ${firmware_inv_path}  ActiveSoftwareImage
    ${active_sw_image}=  Get From Dictionary  ${active_sw_image}  @odata.id

    ${sw_member_list}=  Redfish_Utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    List Should Contain Value  ${sw_member_list}  ${active_sw_image}
