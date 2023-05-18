*** Settings ***
Documentation   Redfish BMC and PNOR software utilities keywords.

Library         code_update_utils.py
Library         gen_robot_valid.py
Library         tftp_update_utils.py
Resource        bmc_redfish_utils.robot
Resource        boot_utils.robot

*** Keywords ***

Get Software Functional State
    [Documentation]  Return functional or active state of the software (i.e. True/False).
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id   The image ID (e.g. "acc9e073").

    ${resp}=  Redfish.Get  /redfish/v1/UpdateService/FirmwareInventory/${image_id}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_INTERNAL_SERVER_ERROR}]
    ${image_info}  Set Variable  ${resp.dict}

    ${sw_functional}=  Run Keyword If
    ...   '${image_info["Description"]}' == 'BMC image' or '${image_info["Description"]}' == 'BMC update'
    ...    Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  FirmwareVersion
    ...  ELSE
    ...    Redfish.Get Attribute  /redfish/v1/Systems/system  BiosVersion

    ${functional}=  Run Keyword And Return Status
    ...   Should Be Equal  ${sw_functional}  ${image_info["Version"]}

    # If they are not same, return from here.
    Return From Keyword If  '${functional}' == 'False'  ${functional}

    # WHen the functional and backup firmware versions are same, this ensure, we rightly set the
    # test inventory dictionary for the firmware functional status.
    Run Keyword If
    ...   '${image_info["Description"]}' == 'BMC image' or '${image_info["Description"]}' == 'BMC update'
    ...   Run Keyword And Return  Find Active Software Image  ${image_id}

    [Return]  ${functional}


Find Active Software Image
    [Documentation]  Match the firmware id of ActiveSoftwareImage attribute with the input id.
    ...              The ActiveSoftwareImage id is the current functional BMC firmware.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id   The image ID (e.g. "acc9e073").

    # This attribute tells which is the firmware version currently functional.
    # "ActiveSoftwareImage": {
    #         "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/5ca9fec0"
    #     },
    ${active_sw_img}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  Links

    ${active_id}=  Set Variable  ${active_sw_img["ActiveSoftwareImage"]["@odata.id"].split("/")[-1]}

    ${matched_functional}=  Run Keyword And Return Status
    ...  Should Be Equal As Strings  ${image_id}  ${active_id}

    # Returns True if matched else False.
    [Return]  ${matched_functional}


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

        ${resp}=  Redfish.Get  ${uri_path}  valid_status_codes=[${HTTP_OK}, ${HTTP_INTERNAL_SERVER_ERROR}]
        ${image_info}  Set Variable  ${resp.dict}

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


Get BMC Functional Firmware
    [Documentation]  Get BMC functional firmware details.

    ${sw_inv}=  Get Functional Firmware  BMC update
    ${sw_inv}=  Get Non Functional Firmware  ${sw_inv}  True

    [Return]  ${sw_inv}


Get Functional Firmware
    [Documentation]  Get all the BMC firmware details.
    [Arguments]  ${image_type}

    # Description of argument(s):
    # image_type    Image value can be either BMC update or Host update.

    ${software_inventory}=  Get Software Inventory State
    ${bmc_inv}=  Get BMC Firmware  ${image_type}  ${software_inventory}

    [Return]  ${bmc_inv}


Get Non Functional Firmware
    [Documentation]  Get BMC non functional firmware details.
    [Arguments]  ${sw_inv}  ${functional_state}

    # Description of argument(s):
    # sw_inv            This dictionary contains all the BMC firmware details.
    # functional_state  Functional state can be either True or False.

    ${resp}=  Filter Struct  ${sw_inv}  [('functional', ${functional_state})]

    ${num_records}=  Get Length  ${resp}
    Set Global Variable  ${num_records}
    Return From Keyword If  ${num_records} == ${0}  ${EMPTY}

    ${list_inv_dict}=  Get Dictionary Values  ${resp}

    [Return]  ${list_inv_dict}[0]


Get Non Functional Firmware List
    [Documentation]  Get BMC non functional firmware details.
    [Arguments]  ${sw_inv}  ${functional_state}

    # Description of argument(s):
    # sw_inv            This dictionary contains all the BMC firmware details.
    # functional_state  Functional state can be either True or False.

    ${list_inv}=  Create List

    FOR  ${key}  IN  @{sw_inv.keys()}
      Run Keyword If  '${sw_inv['${key}']['functional']}' == '${functional_state}'
      ...  Append To List  ${list_inv}  ${sw_inv['${key}']}
    END

    [Return]  ${list_inv}


Redfish Upload Image And Check Progress State
    [Documentation]  Code update with ApplyTime.
    [Arguments]  ${uri}=${REDFISH_BASE_URI}UpdateService

    # Description of argument(s):
    # uri    Code update URI,
    #        default value is ${REDFISH_BASE_URI}UpdateService.

    Log To Console   Start uploading image to BMC.
    Redfish Upload Image  ${uri}  ${IMAGE_FILE_PATH}
    Log To Console   Completed image upload to BMC.

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    # We have noticed firmware inventory state Enabled quickly as soon the image
    # is uploaded via redfish.
    Wait Until Keyword Succeeds  2 min  05 sec
    ...  Check Image Update Progress State  match_state='Disabled', 'Updating', 'Enabled'  image_id=${image_id}

    Wait Until Keyword Succeeds  8 min  10 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${image_id}


Get Host Power State
    [Documentation]  Get host power state.
    [Arguments]  ${quiet}=0

    # Description of arguments:
    # quiet    Indicates whether results should be printed.

    ${state}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Systems/system  PowerState
    Rqprint Vars  state

    [Return]  ${state}


Check Host Power State
    [Documentation]  Check that the machine's host state matches
    ...  the caller's required host state.
    [Arguments]  ${match_state}

    # Description of argument(s):
    # match_state    The expected state. This may be one or more
    #                comma-separated values (e.g. "On", "Off").
    #                If the actual state matches any of the
    #                states named in this argument,
    #                this keyword passes.

    ${state}=  Get Host Power State
    Rvalid Value  state  valid_values=[${match_state}]


Get System Firmware Details
    [Documentation]  Return dictionary of system firmware details.

    # {
    #    FirmwareVersion: 2.8.0-dev-1067-gdc66ce1c5,
    #    BiosVersion: witherspoon-XXX-XX.X-X
    # }

    ${firmware_version}=  Redfish Get BMC Version
    ${bios_version}=  Redfish Get Host Version

    &{sys_firmware_dict}=  Create Dictionary
    Set To Dictionary
    ...  ${sys_firmware_dict}  FirmwareVersion  ${firmware_version}  BiosVersion  ${bios_version}
    Rprint Vars  sys_firmware_dict

    [Return]  &{sys_firmware_dict}


Switch Backup Firmware Image To Functional
   [Documentation]  Switch the backup firmware image to make functional.

   ${sw_inv}=  Get Functional Firmware  BMC image
   ${nonfunctional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  False

   ${firmware_inv_path}=
   ...  Set Variable  /redfish/v1/UpdateService/FirmwareInventory/${nonfunctional_sw_inv['image_id']}

   # Below URI, change to backup image and reset the BMC.
   Redfish.Patch  /redfish/v1/Managers/${MANAGER_ID}
   ...  body={'Links': {'ActiveSoftwareImage': {'@odata.id': '${firmware_inv_path}'}}}


Create List Of Task
    [Documentation]  Return list of task id(s) from provided list of dictionary.
    [Arguments]  ${task_dict_list}

    # Description of argument(s):
    # task_dict_list    Task id dictionary list.

    # '@odata.id': '/redfish/v1/TaskService/Tasks/0'

    ${task_list}=  Create List

    FOR  ${task_dict}  IN  @{task_dict_list}
      Append To List  ${task_list}  ${task_dict['@odata.id']}
    END

    [Return]  ${task_list}


Create Initiated Task State Dict
    [Documentation]  Create active task inventory dictionary as certain URI create task
    ...  to serve the user request.
    [Arguments]  ${task_obj}

    # Description of argument(s):
    # task_obj    Task dictionary.

    # task_inv
    # TargetUri     /redfish/v1/UpdateService
    # TaskIdURI     /redfish/v1/TaskService/Tasks/0
    # TaskState     Starting
    # TaskStatus    OK

    ${task_inv}=  Create Dictionary
    Set To Dictionary  ${task_inv}  TargetUri  ${task_obj['Payload']['TargetUri']}
    Set To Dictionary  ${task_inv}  TaskIdURI  ${task_obj['@odata.id']}
    Set To Dictionary  ${task_inv}  TaskState  ${task_obj['TaskState']}
    Set To Dictionary  ${task_inv}  TaskStatus  ${task_obj['TaskStatus']}

    [Return]  ${task_inv}


Match Target URI
    [Documentation]  Match target uri from task list.
    [Arguments]  ${task_list}  ${target_uri}

    # Description of argument(s):
    # task_list    Task id list.
    # target_uri   Task created for target URI.

    # target_uri   /redfish/v1/UpdateService

    FOR  ${task_id}  IN  @{task_list}
      ${task_payload}=  Redfish.Get Properties  ${task_id}
      Run Keyword And Return If  '${task_payload['Payload']['TargetUri']}' == '${target_uri}'  Create Initiated Task State Dict  ${task_payload}
    END


Check Task With Match TargetUri
    [Documentation]  Create task state dictionary.
    [Arguments]  ${target_uri}=/redfish/v1/TaskService/Tasks

    # Description of argument(s):
    # target_uri    Target URI for which task is initiated.

    ${task_dict_list}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks  Members

    ${task_list}=  Create List Of Task  ${task_dict_list}

    ${task_inv}=  Match Target URI  ${task_list}  ${target_uri}

    [Return]  ${task_inv}


Verify Task Progress State
    [Documentation]  Verify task progress matches the user expected task state.
    [Arguments]  ${task_inv}  ${task_state}

    # Description of argument(s):
    # task_inv      Initiated task inventory dict information.
    # task_state    Expected task state, user reference from data/task_state.json.

    # task_inv
    # TaskIdURI     /redfish/v1/TaskService/Tasks/0
    # TaskState     Starting
    # TaskStatus    OK

    ${task_payload}=  Redfish.Get Properties   ${task_inv['TaskIdURI']}

    ${temp_task_inv}=  Create Dictionary
    Set To Dictionary  ${temp_task_inv}  TaskState  ${task_payload['TaskState']}
    Set To Dictionary  ${temp_task_inv}  TaskStatus  ${task_payload['TaskStatus']}

    Rprint Vars  temp_task_inv

    Should Be Equal As Strings  ${task_state['TaskState']}  ${task_payload['TaskState']}
    Should Be Equal As Strings  ${task_state['TaskStatus']}  ${task_payload['TaskStatus']}

