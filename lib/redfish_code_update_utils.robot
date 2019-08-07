*** Settings ***
Documentation   Redfish BMC and PNOR software utilities keywords.

Library         code_update_utils.py
Library         gen_robot_valid.py
Library         tftp_update_utils.py
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
    [Documentation]  Return the software inventory record that matches the given software version.
    [Arguments]  ${software_version}

    # If no matchine record can be found, return ${EMPTY}.

    # Example of returned data:
    # software_inventory_record:
    #   [image_type]:      BMC update
    #   [image_id]:        1e662ba8
    #   [functional]:      True
    #   [version]:         2.8.0-dev-150-g04508dc9f

    # Description of argument(s):
    # software_version     A BMC or Host version (e.g "2.8.0-dev-150-g04508dc9f").

    ${software_inventory}=  Get Software Inventory State
    # Filter out entries that don't match the criterion..
    ${software_inventory}=  Filter Struct  ${software_inventory}  [('version', '${software_version}')]
    # Convert from dictionary to list.
    ${software_inventory}=  Get Dictionary Values  ${software_inventory}
    ${num_records}=  Get Length  ${software_inventory}

    Return From Keyword If  ${num_records} == ${0}  ${EMPTY}

    # Return the first list entry.
    [Return]  ${software_inventory}[0]


Redfish Upload Image And Check Progress State
    [Documentation]  Code update with ApplyTime.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    Set ApplyTime  policy=${apply_Time}
    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State
    ...  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Wait a few seconds to check if the update progress started.
    Sleep  5s
    Check Image Update Progress State
    ...  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${image_id}


Reboot BMC And Verify BMC Image
    [Documentation]  Reboot or wait for BMC standby post reboot and
    ...  verify installed image is functional.
    [Arguments]  ${apply_time}  ${start_boot_seconds}

    # Description of argument(s):
    # policy                ApplyTime allowed values
    #                       (e.g. "OnReset", "Immediate").
    # start_boot_seconds    See 'Wait For Reboot' for details.

    Run Keyword if  'OnReset' == '${apply_time}'
    ...  Run Keyword
    ...      Redfish OBMC Reboot (off)
    ...  ELSE
    ...    Run Keyword
    ...        Wait For Reboot  start_boot_seconds=${start_boot_seconds}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

