*** Settings ***
Documentation   Redfish BMC and PNOR software utilities keywords.

Library         code_update_utils.py
Library         gen_robot_valid.py
Resource        bmc_redfish_utils.robot

*** Keywords ***

Get Software Functional State
    [Documentation]  Return functional or active state of the software.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id   The image ID (e.g. "acc9e073").

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory/${image_id}

    ${version_functional}=  Run Keyword If  '${resp.dict["Description"]}' == 'BMC update'
    ...    Redfish.Get Attribute  /redfish/v1/Managers/bmc  FirmwareVersion
    ...  ELSE
    ...    Redfish.Get Attribute  /redfish/v1/Systems/system  BiosVersion

    ${functional}=  Run Keyword And Return Status
    ...   Should Be Equal  ${version_functional}  ${resp.dict["Version"]}

    [Return]  ${functional}


Get Software Inventory State
    [Documentation]  Return dictionary of the image type, version and functional state
    ...  of the software objects active on the system.

    # User defined state for software objects.
    # Note: "Functional" term refers to firmware which system is currently booted with.
    # sw_inv_dict:
    #   [ace821ef]:
    #     [image_type]:                 Host update
    #     [version]:                    witherspoon-xx.xx.xx.xx
    #     [functional]:                 True
    #   [b9101858]:
    #     [image_type]:                 BMC update
    #     [version]:                    2.8.0-dev-150-g04508dc9f
    #     [functional]:                 True
    #   [c45eafa5]:
    #     [image_type]:                 BMC update
    #     [version]:                    2.8.0-dev-149-g1a8df5077
    #     [functional]:                 False

    ${sw_member_list}=  Redfish_Utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    &{sw_inv_dict}=  Create Dictionary

    # sw_member_list:
    #   [0]:                            /redfish/v1/UpdateService/FirmwareInventory/98744d76
    #   [1]:                            /redfish/v1/UpdateService/FirmwareInventory/9a8028ec
    #   [2]:                            /redfish/v1/UpdateService/FirmwareInventory/acc9e073

    FOR  ${uri_path}  IN  @{sw_member_list}
        &{tmp_dict}=  Create Dictionary
        ${resp}=  Redfish.Get  ${uri_path}
        Set To Dictionary  ${tmp_dict}  image_type  ${resp.dict["Description"]}
        Set To Dictionary  ${tmp_dict}  version  ${resp.dict["Version"]}
        ${functional}=  Get Software Functional State  ${uri_path.split("/")[-1]}
        Set To Dictionary  ${tmp_dict}  functional  ${functional}
        Set To Dictionary  ${sw_inv_dict}  ${uri_path.split("/")[-1]}  ${tmp_dict}
    END

    [Return]  &{sw_inv_dict}
