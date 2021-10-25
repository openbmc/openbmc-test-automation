*** Settings ***
Documentation   BMC and PNOR update utilities keywords.

Library         code_update_utils.py
Library         OperatingSystem
Library         String
Library         utilities.py
Library         gen_robot_valid.py
Variables       ../data/variables.py
Resource        boot_utils.robot
Resource        rest_client.robot
Resource        openbmc_ffdc.robot

*** Variables ***
${ignore_err}    ${0}

*** Keywords ***

Get Software Objects
    [Documentation]  Get the host software objects and return as a list.
    [Arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    # Example:
    # "data": [
    #      "/xyz/openbmc_project/software/f3b29aa8",
    #      "/xyz/openbmc_project/software/e49bc78e",
    # ],
    # Iterate the list and return the host object name path list.

    ${host_list}=  Create List
    ${sw_list}=  Read Properties  ${SOFTWARE_VERSION_URI}

    FOR  ${index}  IN  @{sw_list}
      ${attr_purpose}=  Read Software Attribute  ${index}  Purpose
      Continue For Loop If  '${attr_purpose}' != '${version_type}'
      Append To List  ${host_list}  ${index}
    END

    [Return]  ${host_list}


Read Software Attribute
    [Documentation]  Return software attribute data.
    [Arguments]  ${software_object}  ${attribute_name}

    # Description of argument(s):
    # software_object   Software object path.
    #                   (e.g. "/xyz/openbmc_project/software/f3b29aa8").
    # attribute_name    Software object attribute name.

    ${resp}=  OpenBMC Get Request  ${software_object}/attr/${attribute_name}
    ...  quiet=${1}
    Return From Keyword If  ${resp.status_code} != ${HTTP_OK}
    ${content}=  To JSON  ${resp.content}
    [Return]  ${content["data"]}


Get Software Objects Id
    [Documentation]  Get the software objects id and return as a list.
    [Arguments]  ${version_type}=${VERSION_PURPOSE_HOST}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #              (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #               "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    ${sw_id_list}=  Create List
    ${sw_list}=  Get Software Objects  ${version_type}

    FOR  ${index}  IN  @{sw_list}
        Append To List  ${sw_id_list}  ${index.rsplit('/', 1)[1]}
    END
    [Return]  ${sw_id_list}


Get Host Software Property
    [Documentation]  Return a dictionary of host software properties.
    [Arguments]  ${host_object}

    # Description of argument(s):
    # host_object  Host software object path.
    #             (e.g. "/xyz/openbmc_project/software/f3b29aa8").

    ${sw_attributes}=  Read Properties  ${host_object}
    [return]  ${sw_attributes}

Get Host Software Objects Details
    [Documentation]  Return software object details as a list of dictionaries.
    [Arguments]  ${quiet}=${QUIET}

    ${software}=  Create List

    ${pnor_details}=  Get Software Objects  ${VERSION_PURPOSE_HOST}
    FOR  ${pnor}  IN  @{pnor_details}
        ${resp}=  OpenBMC Get Request  ${pnor}  quiet=${1}
        ${json}=  To JSON  ${resp.content}
        Append To List  ${software}  ${json["data"]}
    END
    [Return]  ${software}

Set Host Software Property
    [Documentation]  Set the host software properties of a given object.
    [Arguments]  ${host_object}  ${sw_attribute}  ${data}

    # Description of argument(s):
    # host_object   Host software object name.
    # sw_attribute  Host software attribute name.
    #               (e.g. "Activation", "Priority", "RequestedActivation" etc).
    # data          Value to be written.

    ${args}=  Create Dictionary  data=${data}
    Write Attribute  ${host_object}  ${sw_attribute}  data=${args}
    # Sync time for software updater manager to update.
    Sleep  10s


Set Property To Invalid Value And Verify No Change
    [Documentation]  Attempt to set a property and check that the value didn't
    ...              change.
    [Arguments]  ${property}  ${version_type}

    # Description of argument(s):
    # property      The property to attempt to set.
    # version_type  Either BMC or host version purpose.
    #               By default host version purpose string.
    #  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    ${software_objects}=  Get Software Objects  version_type=${version_type}
    ${prev_properties}=  Get Host Software Property  @{software_objects}[0]
    Run Keyword And Expect Error  500 != 200
    ...  Set Host Software Property  @{software_objects}[0]  ${property}  foo
    ${cur_properties}=  Get Host Software Property  @{software_objects}[0]
    Should Be Equal As Strings  &{prev_properties}[${property}]
    ...  &{cur_properties}[${property}]


Set Priority To Invalid Value And Expect Error
    [Documentation]  Set the priority of an image to an invalid value and
    ...              check that an error was returned.
    [Arguments]  ${version_type}  ${priority}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.
    #               (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #                     "xyz.openbmc_project.Software.Version.VersionPurpose.Host").
    # priority      The priority value to set. Should be an integer outside of
    #               the range of 0 through 255.

    ${images}=  Get Software Objects  version_type=${version_type}
    ${num_images}=  Get Length  ${images}
    Should Be True  0 < ${num_images}

    Run Keyword And Expect Error  403 != 200
    ...  Set Host Software Property  @{images}[0]  Priority  ${priority}


Redfish Upload Image
    [Documentation]  Upload an image to the BMC via redfish.
    [Arguments]  ${uri}  ${image_file_path}

    # Description of argument(s):
    # uri                 URI for uploading image via redfish.
    # image_file_path     The path to the image tarball.

    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}

    Wait Until Keyword Succeeds  2 times  240 sec
    ...  Upload Image To BMC  ${uri}  timeout=${240}  data=${image_data}


Redfish Verify BMC Version
    [Documentation]  Verify that the version on the BMC is the same as the
    ...              version in the given image via Redfish.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    # Extract the version from the image tarball on our local system.
    ${tar_version}=  Get Version Tar  ${image_file_path}
    ${bmc_version}=  Redfish Get BMC Version

    Valid Value  bmc_version  valid_values=['${tar_version}']


Redfish Verify Host Version
    [Documentation]  Verify that the version of the PNOR image that is on the
    ...              BMC is the same as the one in the given image via Redfish.
    [Arguments]      ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the image tarball.

    # Extract the version from the image tarball on our local system.
    ${tar_version}=  Get Version Tar  ${image_file_path}
    ${host_version}=  Redfish Get Host Version

    Valid Value  host_version  valid_values=['${tar_version}']


Upload And Activate Image
    [Documentation]  Upload an image to the BMC and activate it with REST.
    [Arguments]  ${image_file_path}  ${wait}=${1}  ${skip_if_active}=false

    # Description of argument(s):
    # image_file_path     The path to the image tarball to upload and activate.
    # wait                Indicates that this keyword should wait for host or
    #                     BMC activation is completed.
    # skip_if_active      If set to true, will skip the code update if this
    #                     image is already on the BMC.

    OperatingSystem.File Should Exist  ${image_file_path}
    ${image_version}=  Get Version Tar  ${image_file_path}

    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}

    Wait Until Keyword Succeeds  3 times  120 sec
    ...   Upload Image To BMC  /upload/image  timeout=${90}  data=${image_data}
    ${ret}  ${version_id}=  Verify Image Upload  ${image_version}
    Should Be True  ${ret}

    # Verify the image is 'READY' to be activated or if it's already active,
    # set priority to 0 and reboot the BMC.
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    ${activation}=  Set Variable  ${software_state}[Activation]

    Run Keyword If
    ...  '${skip_if_active}' == 'true' and '${activation}' == '${ACTIVE}'
    ...  Run Keywords
    ...      Set Host Software Property  ${SOFTWARE_VERSION_URI}${version_id}
    ...      Priority  ${0}
    ...    AND
    ...      Return From Keyword

    Should Be Equal As Strings  ${software_state}[Activation]  ${READY}

    # Request the image to be activated.
    ${args}=  Create Dictionary  data=${REQUESTED_ACTIVE}
    Write Attribute  ${SOFTWARE_VERSION_URI}${version_id}
    ...  RequestedActivation  data=${args}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  ${software_state}[RequestedActivation]
    ...  ${REQUESTED_ACTIVE}

    # Does caller want to wait for activation to complete?
    Return From Keyword If  '${wait}' == '${0}'  ${version_id}

    # Verify code update was successful and Activation state is Active.
    Wait For Activation State Change  ${version_id}  ${ACTIVATING}
    ${software_state}=  Read Properties  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  ${software_state}[Activation]  ${ACTIVE}

    # Uploaded and activated image should have priority set to 0. Due to timing
    # contention, it may take up to 10 seconds to complete updating priority.
    Wait Until Keyword Succeeds  10 sec  5 sec
    ...  Check Software Object Attribute  ${version_id}  Priority  ${0}

    [Return]  ${version_id}


Attempt To Reboot BMC During Image Activation
    [Documentation]  Attempt to reboot the BMC while an image is activating and
    ...              check that the BMC ignores the reboot command and finishes
    ...              activation.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path  Path to the image to update to.

    # Attempt to reboot during activation.
    ${version_id}=  Upload And Activate Image  ${image_file_path}
    ...  wait=${0}
    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    OBMC Reboot (off)

    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Activate Image And Verify No Duplicate Priorities
    [Documentation]  Upload an image, and then check that no images have the
    ...              same priority.
    [Arguments]  ${image_file_path}  ${image_purpose}

    # Description of argument(s):
    # image_file_path  The path to the image to upload.
    # image_purpose    The purpose in the image's MANIFEST file.

    Upload And Activate Image  ${image_file_path}  skip_if_active=true
    Verify No Duplicate Image Priorities  ${image_purpose}


Set Same Priority For Multiple Images
    [Documentation]  Find two images, set the priorities to be the same, and
    ...              verify that the priorities are not the same.
    [Arguments]  ${version_purpose}

    # Description of argument(s):
    # version_purpose  Either BMC or host version purpose.
    #                  (e.g. "xyz.openbmc_project.Software.Version.VersionPurpose.BMC"
    #                        "xyz.openbmc_project.Software.Version.VersionPurpose.Host").

    # Make sure we have more than two images.
    ${software_objects}=  Get Software Objects  version_type=${version_purpose}
    ${num_images}=  Get Length  ${software_objects}
    Should Be True  1 < ${num_images}
    ...  msg=Only found one image on the BMC with purpose ${version_purpose}.

    # Set the priority of the second image to the priority of the first.
    ${properties}=  Get Host Software Property  @{software_objects}[0]
    Set Host Software Property  @{software_objects}[1]  Priority
    ...  &{properties}[Priority]
    Verify No Duplicate Image Priorities  ${version_purpose}

    # Set the priority of the first image back to what it was before
    Set Host Software Property  @{software_objects}[0]  Priority
    ...  &{properties}[Priority]


Delete Software Object
    [Documentation]  Deletes an image from the BMC.
    [Arguments]  ${software_object}

    # Description of argument(s):
    # software_object  The URI to the software image to delete.

    ${arglist}=  Create List
    ${args}=  Create Dictionary  data=${arglist}
    ${resp}=  OpenBMC Post Request  ${software_object}/action/Delete
    ...  data=${args}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete Image And Verify
    [Documentation]  Delete an image from the BMC and verify that it was
    ...              removed from software and the /tmp/images directory.
    [Arguments]  ${software_object}  ${version_type}

    # Description of argument(s):
    # software_object        The URI of the software object to delete.
    # version_type  The type of the software object, e.g.
    #               xyz.openbmc_project.Software.Version.VersionPurpose.Host
    #               or xyz.openbmc_project.Software.Version.VersionPurpose.BMC.

    Log To Console  Deleting ${software_object}

    # Delete the image.
    Delete Software Object  ${software_object}

    # Verify that it's gone from software.
    ${software_objects}=  Get Software Objects  version_type=${version_type}
    Should Not Contain  ${software_objects}  ${software_object}

    # Check that there is no file in the /tmp/images directory.
    ${image_id}=  Fetch From Right  ${software_object}  /
    BMC Execute Command
    ...  [ ! -d "/tmp/images/${image_id}" ]


Delete All Non Running BMC Images
    [Documentation]  Delete all BMC images that are not running on the BMC.

    @{datalist}=  Create List
    ${data}=  Create Dictionary  data=@{datalist}
    Call Method  ${SOFTWARE_VERSION_URI}  DeleteAll  data=${data}


Check Error And Collect FFDC
    [Documentation]  Collect FFDC if error log exists.

    ${status}=  Run Keyword And Return Status  Error Logs Should Not Exist
    Run Keyword If  '${status}' == 'False'  FFDC
    Delete Error Logs


Verify Running BMC Image
    [Documentation]  Verify that the version on the BMC is the same as the
    ...              version in the given image.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the BMC image tarball.

    ${tar_version}=  Get Version Tar  ${image_file_path}
    ${bmc_version}=  Get BMC Version
    ${bmc_version}=  Remove String  ${bmc_version}  "
    Should Be Equal  ${tar_version}  ${bmc_version}


Verify Running Host Image
    [Documentation]  Verify that the version of the PNOR image that is on the
    ...              BMC is the same as the one in the given image.
    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path   Path to the PNOR image tarball.

    ${tar_version}=  Get Version Tar  ${image_file_path}
    ${pnor_version}=  Get PNOR Version
    Should Be Equal  ${tar_version}  ${pnor_version}


Get Least Value Priority Image
    [Documentation]  Find the least value in "Priority" attribute and return.
    [Arguments]  ${version_type}

    # Description of argument(s):
    # version_type  Either BMC or host version purpose.

    ${priority_value_list}=  Create List
    ${sw_list}=  Get Software Objects  version_type=${version_type}

    FOR  ${index}  IN  @{sw_list}
        ${priority_value}=
        ...  Read Software Attribute  ${index}  Priority
        Append To List  ${priority_value_list}  ${priority_value}
    END
    ${min_value}=  Min List Value  ${priority_value_list}

    [Return]  ${min_value}


Enable Field Mode And Verify Unmount
    [Documentation]  Enable field mode and check that /usr/local is unmounted.

    # After running, /xyz/openbmc_project/software should look like this:
    # /xyz/openbmc_project/software
    # {
    #     "FieldModeEnabled": 1,
    #     "associations": [
    #         [
    #             "active",
    #             "software_version",
    #             "/xyz/openbmc_project/software/fcf8e182"
    #         ],
    #         [
    #             "functional",
    #             "functional",
    #             "/xyz/openbmc_project/software/fcf8e182"
    #         ]
    #     ]
    # }

    ${args}=  Create Dictionary  data=${1}
    Write Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled  data=${args}
    Sleep  5s
    BMC Execute Command  [ ! -d "/usr/local/share" ]


Disable Field Mode And Verify Unmount
    [Documentation]  Disable field mode, unmask usr local mount and reboot.

    BMC Execute Command  /sbin/fw_setenv fieldmode
    BMC Execute Command  /bin/systemctl unmask usr-local.mount
    OBMC Reboot (off)  stack_mode=normal
    BMC Execute Command  [ -d "/usr/local/share" ]


Field Mode Should Be Enabled
    [Documentation]  Check that field mode is enabled.

    ${value}=  Read Attribute  ${SOFTWARE_VERSION_URI}  FieldModeEnabled
    Should Be True  ${value}  ${1}

List Installed Images
    [Documentation]  List all the installed images.
    [Arguments]  ${image_type}

    # Description of argument(s):
    # image_type  Either "BMC" or "PNOR".

    # List the installed images.
    ${installed_images}=  Get Software Objects
    ...  ${SOFTWARE_PURPOSE}.${image_type}

    Run Keyword If  ${installed_images} != []
    ...  Get List of Images  ${installed_images}
    ...  ELSE  Log  No ${image_type} images are present.

Get List of Images
    [Documentation]  Get List of Images
    [Arguments]  ${installed_images}

    FOR  ${uri}  IN  @{installed_images}
      ${resp}=  OpenBMC Get Request  ${uri}
      ${json}=  To JSON  ${resp.content}
      Log  ${json["data"]}
    END


Check Software Object Attribute
    [Documentation]  Get the software property of a given object and verify.
    [Arguments]  ${image_object}  ${sw_attribute}  ${value}

    # Description of argument(s):
    # image_object  Image software object name.
    # sw_attribute  Software attribute name.
    #               (e.g. "Activation", "Priority", "RequestedActivation" etc).
    # value         Software attribute value to compare.

    ${data}=  Read Attribute
    ...  ${SOFTWARE_VERSION_URI}${image_object}  ${sw_attribute}

    Should Be True  ${data} == ${value}
    ...  msg=Given attribute value ${data} mismatch ${value}.


Image Should Be Signed
    [Documentation]  Fail if the image is not signed.

    Directory Should Exist  ${ACTIVATION_DIR_PATH}
    ...  msg=${ACTIVATION_DIR_PATH} does not exist. Therefore, the image is not signed.


Get Latest Image ID
    [Documentation]  Return the ID of the most recently extracted image.
    # Note: This keyword will fail if there is no such file.

    # Example: # ls /tmp/images/
    #            1b714fb7
    ${image_id}=  Get Latest File  /tmp/images/

    Return From Keyword If  '${image_id}' != '${EMPTY}'  ${image_id}

    ${image_id}=   Get Image Id   Updating
    [Return]  ${image_id}


Check Image Update Progress State
    [Documentation]  Check that the image update progress state matches the specified state.
    [Arguments]  ${match_state}  ${image_id}

    # Description of argument(s):
    # match_state    The expected state. This may be one or more comma-separated values
    #                (e.g. "Disabled", "Disabled, Updating"). If the actual state matches
    #                any of the states named in this argument, this keyword passes.
    # image_id       The image ID (e.g. "1b714fb7").

    ${state}=  Get Image Update Progress State  image_id=${image_id}
    Valid Value  state  valid_values=[${match_state}]


Get All Task
    [Documentation]  Get all the active tasks.
    [Arguments]  ${target_uri}  ${match_status}  ${match_state}

    # Description of argument(s):
    # target_uri      Target URI.
    # match_status    The expected status. The value is (e.g. OK). If the actual state matches
    #                 any of the states named in this argument, this keyword passes.
    # match_state     The expected state. This may be one or more comma-separated values
    #                 (e.g. Running, Completed). If the actual state matches
    #                 any of the states named in this argument, this keyword passes.

    ${task_list}=  Redfish.Get Members List  /redfish/v1/TaskService/Tasks
    ${num_records}=  Get Length  ${task_list}
    Return From Keyword If  ${num_records} == ${0}  ${EMPTY

    ${task_dict}=  Get Task Objects  ${task_list}

    ${task_inventory}=  Check Task Attribute  ${target_uri}  ${match_status}  ${match_state}  ${task_dict}

    ${num_records}=  Get Length  ${task_inventory}
    Return From Keyword If  ${num_records} == ${0}  ${EMPTY}

    [Return]  ${task_inventory}


Get Task Objects
    [Documentation]  Check all the task to filter update service target URI and
    ...  return the task attributes as dictionary.
    [Arguments]  ${task_list}

    # Description of argument(s):
    # task_list  List of all active task.

    &{task_inv_dict}=  Create Dictionary

    FOR  ${task_id}  IN  @{task_list}
      &{tmp_dict}=  Create Dictionary
      ${task_payload}=  Redfish.Get Attribute  ${task_id}  Payload
      Set To Dictionary  ${tmp_dict}  TargetUri  ${task_payload['TargetUri']}

      ${task_state}=  Redfish.Get Attribute  ${task_id}  TaskState
      Set To Dictionary  ${tmp_dict}  TaskState  ${task_state}

      ${task_status}=  Redfish.Get Attribute  ${task_id}  TaskStatus
      Set To Dictionary  ${tmp_dict}  TaskStatus  ${task_status}
      Set To Dictionary  ${task_inv_dict}  ${task_id.split("/")[-1]}  ${tmp_dict}
    END

    [Return]  ${task_inv_dict}


Check Task Attribute
    [Documentation]  Get the active task progress state.
    [Arguments]  ${target_uri}  ${match_status}  ${match_state}  ${task_dict}

    # Description of argument(s):
    # target_uri      Active task which has update service target URI.
    # match_status    The expected status. The value is (e.g. OK). If the actual state matches
    #                 any of the states named in this argument, this keyword passes.
    # match_state     The expected state. This may be one or more comma-separated values
    #                 (e.g. Running, Completed). If the actual state matches
    #                 any of the states named in this argument, this keyword passes.
    # task_dict       Task inventory.

    Return From Keyword If  ${target_uri} == '' or ${target_uri} == None  ${task_dict}
    Return From Keyword If  ${match_state} == '' or ${match_state} == None  ${task_dict}

    FOR  ${task_ins}  IN  @{task_dict.items()}
      &{tmp_dict}=  Create Dictionary
      Set To Dictionary  ${tmp_dict}  ${task_ins[0]}  ${task_ins[1]}
      Return From Keyword If
      ...  ${target_uri} == '${task_ins[1]['TargetUri']}' and ${match_state} == '${task_ins[1]['TaskState']}'
      ...  ${tmp_dict}
    END

    [Return]  ${EMPTY}


Check Task Progress State
    [Documentation]  Check that the task update progress state matches the specified state.
    [Arguments]  ${task_inv_dict}  ${match_status}  ${match_state}

    # Description of argument(s):
    # task_inv_dict    Task inventory dictionary.
    # match_status     The expected state. The value is (e.g. OK). If the actual state matches
    #                  any of the states named in this argument, this keyword passes.
    # match_state      The expected state. This may be one or more comma-separated values
    #                  (e.g. Running, Completed). If the actual state matches
    #                  any of the states named in this argument, this keyword passes.

    FOR  ${task_ins}  IN  @{task_inv_dict.items()}
      ${task_state}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks/${task_ins}[0]  TaskState
      ${task_status}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks/${task_ins}[0]  TaskStatus
      ${task_payload}=  Redfish.Get Attribute  /redfish/v1/TaskService/Tasks/${task_ins}[0]  Payload

      Rprint Vars  task_state
      Rprint Vars  task_status
      Rprint Vars  task_payload['TargetUri']

      Valid Value  task_state  valid_values=[${match_state}]
      Valid Value  task_status  valid_values=[${match_status}]
    END


Get Image Id
    [Documentation]  Get image id.
    [Arguments]  ${match_state}

    # Description of argument(s):
    # match_state    The expected state. This may be one or more comma-separated values
    #                (e.g. "Disabled", "Disabled, Updating"). If the actual state matches
    #                any of the states named in this argument, this keyword passes.

    ${sw_member_list}=  Redfish.Get Members List  /redfish/v1/UpdateService/FirmwareInventory

    FOR  ${sw_member}  IN  @{sw_member_list}
      ${status}=  Redfish.Get Attribute  ${sw_member}  Status
      Return From Keyword If  '${status['State']}' == ${match_state}  ${sw_member.split('/')[-1]}
    END

    [Return]  None


Get Image Update Progress State
    [Documentation]  Return the current state of the image update.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id         The image ID (e.g. "1b714fb7").

    # In this example, this keyword would return the value "Enabled".
    #  "Status": {
    #              "Health": "OK",
    #              "HealthRollup": "OK",
    #              "State": "Enabled"
    #            },
    ${status}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Status
    Rprint Vars  status

    [Return]  ${status["State"]}


Get Firmware Image Version
    [Documentation]  Get the version of the currently installed firmware and return it.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id      The image ID (e.g. "1b714fb7").

    # Example of a version returned by this keyword:
    # 2.8.0-dev-19-g6d5764b33
    ${version}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Version
    Rprint Vars  version

    [Return]  ${version}


Get ApplyTime
    [Documentation]  Get the firmware "ApplyTime" policy.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${system_applytime}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}UpdateService  HttpPushUriOptions

    [Return]  ${system_applytime["HttpPushUriApplyTime"]["ApplyTime"]}


Verify Get ApplyTime
    [Documentation]  Get and verify the firmware "ApplyTime" policy.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${system_applytime}=  Get ApplyTime  ${policy}
    Rprint Vars  system_applytime
    Valid Value  system_applytime  ['${policy}']


Set ApplyTime
    [Documentation]  Set and verify the firmware "ApplyTime" policy.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService
    ...  body={'HttpPushUriOptions' : {'HttpPushUriApplyTime' : {'ApplyTime' : '${policy}'}}}
    Verify Get ApplyTime  ${policy}


Get Image Version From TFTP Server
    [Documentation]  Get and return the image version
    ...  from the TFTP server.
    [Arguments]  ${server_host}  ${image_file_name}

    # Description of argument(s):
    # server_host   The host name or IP address of the TFTP server.
    # image_file_name  The file name of the image.

    Shell Cmd
    ...  curl -s tftp://${server_host}/${image_file_name} > tftp_image.tar
    ${version}=  Get Version Tar  tftp_image.tar
    OperatingSystem.Remove File  tftp_image.tar

    [Return]  ${version}

