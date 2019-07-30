*** Settings ***
Documentation   Redfish BMC and PNOR software utilities keywords.

Library         code_update_utils.py
Library         gen_robot_valid.py
Resource        bmc_redfish_utils.robot

*** Keywords ***

Get Software Functional State
    [Documentation]  Return functional or active state of the software (i.e. True/False).
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id   The image ID (e.g. "acc9e073").

    ${image_info}=  Redfish.Get Properties  /redfish/v1/UpdateService/FirmwareInventory/${image_id}

    ${sw_functional}=  Run Keyword If  '${image_info["Description"]}' == 'BMC update'
    ...    Redfish.Get Attribute  /redfish/v1/Managers/bmc  FirmwareVersion
    ...  ELSE
    ...    Redfish.Get Attribute  /redfish/v1/Systems/system  BiosVersion

    ${functional}=  Run Keyword And Return Status
    ...   Should Be Equal  ${sw_functional}  ${image_info["Version"]}

    [Return]  ${functional}


Get Software Inventory State
    [Documentation]  Return dictionary of the image type, version and functional state
    ...  of the software objects active on the system.

    # User defined state for software objects.
    # Note: "Functional" term refers to firmware which system is currently booted with.
    # sw_inv_dict:
    #   [ace821ef]:
    #     [image_type]:                 Host update
    #     [image_id]:                   ace821ef
    #     [functional]:                 True
    #     [version]:                    witherspoon-xx.xx.xx.xx
    #   [b9101858]:
    #     [image_type]:                 BMC update
    #     [image_id]:                   b9101858
    #     [functional]:                 True
    #     [version]:                    2.8.0-dev-150-g04508dc9f
    #   [c45eafa5]:
    #     [image_type]:                 BMC update
    #     [image_id]:                   c45eafa5
    #     [functional]:                 False
    #     [version]:                    2.8.0-dev-149-g1a8df5077

    ${sw_member_list}=  Redfish_Utils.Get Member List  /redfish/v1/UpdateService/FirmwareInventory
    &{sw_inv_dict}=  Create Dictionary

    # sw_member_list:
    #   [0]:                            /redfish/v1/UpdateService/FirmwareInventory/98744d76
    #   [1]:                            /redfish/v1/UpdateService/FirmwareInventory/9a8028ec
    #   [2]:                            /redfish/v1/UpdateService/FirmwareInventory/acc9e073

    FOR  ${uri_path}  IN  @{sw_member_list}
        &{tmp_dict}=  Create Dictionary
        ${image_info}=  Redfish.Get Properties  ${uri_path}
        Set To Dictionary  ${tmp_dict}  image_type  ${image_info["Description"]}
        Set To Dictionary  ${tmp_dict}  image_id  ${uri_path.split("/")[-1]}
        ${functional}=  Get Software Functional State  ${uri_path.split("/")[-1]}
        Set To Dictionary  ${tmp_dict}  functional  ${functional}
        Set To Dictionary  ${tmp_dict}  version  ${image_info["Version"]}
        Set To Dictionary  ${sw_inv_dict}  ${uri_path.split("/")[-1]}  ${tmp_dict}
    END

    [Return]  &{sw_inv_dict}


Get Software Inventory State By Version
    [Documentation]  Return dictionary of the software version inventory state.
    [Arguments]  ${software_version}

    # Description of argument(s):
    # software_version     A BMC or Host version (e.g "2.8.0-dev-150-g04508dc9f").

    ${sw_inv_dict}=  Get Software Inventory State

    # Software image id list:
    # dict_keys:
    #  [0]:          1e662ba8
    #  [1]:          98744d76
    #  [2]:          9a8028ec

    ${dict_keys}=  Get Dictionary Keys  ${sw_inv_dict}

    # Returns the dictionary of the version if software version exist:
    # sw_version:
    #   [image_type]:              BMC update
    #   [image_id]:                1e662ba8
    #   [functional]:              True
    #   [version]:                 2.8.0-dev-150-g04508dc9f

    FOR  ${image_id}  IN  @{dict_keys}
        Return From Keyword If  '${sw_inv_dict['${image_id}']['version']}' == '${software_version}'
        ...  ${sw_inv_dict['${image_id}']}
    END
