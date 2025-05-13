*** Settings ***
Documentation     Update the PNOR code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v DELETE_OLD_PNOR_IMAGES:<"true" or "false">
...               -v IMAGE_FILE_PATH:<path/*.tar>
...               -v ALTERNATE_IMAGE_FILE_PATH:<path/*.tar>
...               host_code_update.robot
...
...               Code update method BMC
...               Update work flow sequence:
...                 - Upload image via REST
...                 - Verify that the file exists on the BMC
...                 - Check that software "Activation" is set to "Ready"
...                 - Set "Requested Activation" to "Active"
...                 - Wait for code update to complete
...                 - Verify the new version

Library           ../../lib/bmc_ssh_utils.py
Library           ../../lib/code_update_utils.py
Library           ../../lib/gen_robot_keyword.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/state_manager.robot
Resource          ../../lib/dump_utils.robot

Test Teardown     Code Update Test Teardown

Test Tags        Host_Code_Update

*** Variables ***

${QUIET}                         ${1}
${IMAGE_FILE_PATH}               ${EMPTY}
${DELETE_OLD_PNOR_IMAGES}        false
${DELETE_OLD_GUARD_FILE}         false
${ALTERNATE_IMAGE_FILE_PATH}     ${EMPTY}
${SKIP_UPDATE_IF_ACTIVE}         false
${cache_files_dir_path}          /var/lib/phosphor-software-manager/pnor/prsv/

*** Test Cases ***

REST Host Code Update
    [Documentation]  Do a PNOR code update by uploading image on BMC via REST.
    # 1. Delete error logs if there is any.
    # 1. Do code update.
    # 2. Do post update the following:
    #    - Collect FFDC if error log exist and delete error logs.
    [Tags]  REST_Host_Code_Update
    [Setup]  Code Update Setup

    Run Keyword And Ignore Error  List Installed Images  Host

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    ...  skip_if_active=${SKIP_UPDATE_IF_ACTIVE}
    OBMC Reboot (off)


Post Update Boot To OS
    [Documentation]  Boot the host OS
    [Tags]  Post_Update_Boot_To_OS
    [Setup]  Start SOL Console Logging
    [Teardown]  Run Keywords  Stop SOL Console Logging
    ...         AND  Code Update Test Teardown

    IF  '${PREV_TEST_STATUS}' == 'FAIL'
        Fail  Code update failed. No need to boot to OS.
    END
    Delete All Error Logs
    REST Power On
    Verify Running Host Image  ${IMAGE_FILE_PATH}


Test Boot With No VPD Cache
    [Documentation]  After having done a PNOR update and
    ...  booted the OS in the tests above, remove the cached
    ...  VPD files and verify that the OS can still boot.
    [Tags]  Test_Boot_With_No_VPD_Cache
    [Setup]  Start SOL Console Logging
    [Teardown]  Run Keywords  Stop SOL Console Logging
    ...         AND  Code Update Test Teardown

    ${num_vpd_files}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls ${cache_files_dir_path} | grep VPD -c
    # Typically, vpd files = "CVPD DJVPD MVPD NVRAM".
    Should Be Equal As Integers  ${num_vpd_files}  ${3}
    ...  msg=Missing VPD files at ${cache_files_dir_path}.

    # Delete the *VPD* files.
    BMC Execute Command  rm -f ${xxx_dir_path}*VPD*

    REST Power On

    # After powering-on the system, the VPD files should be present.
    ${num_vpd_files}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls ${cache_files_dir_path} | grep VPD -c
    Should Be Equal As Integers  ${num_vpd_files}  ${3}
    ...  msg=Three VPD files expected at ${cache_files_dir_path}.

    # Power off.  The next test case will boot the OS with the new VPD files.
    REST Power Off


REST Host Code Update While OS Is Running
    [Documentation]  Do a PNOR code update while the host is running.
    [Tags]  REST_Host_Code_Update_While_OS_Is_Running
    [Teardown]  Run Keywords  REST Power Off  stack_mode=skip
    ...         AND  Code Update Test Teardown

    IF  '${PREV_TEST_STATUS}' == 'FAIL'  Fail  Cannot boot the OS.

    REST Power On  stack_mode=skip
    Upload And Activate Image
    ...  ${ALTERNATE_IMAGE_FILE_PATH}  skip_if_active=true
    REST Power On  stack_mode=normal
    Verify Running Host Image  ${ALTERNATE_IMAGE_FILE_PATH}

Host Image Priority Attribute Test
    [Documentation]  Set "Priority" attribute.
    [Tags]  Host_Image_Priority_Attribute_Test
    [Template]  Temporarily Set PNOR Attribute

    # Property        Value
    Priority          ${0}
    Priority          ${1}
    Priority          ${127}
    Priority          ${255}


Host Set Priority To Invalid Values
    [Documentation]  Attempt to set the priority of an image to an invalid
    ...              value and expect an error.
    [Tags]  Host_Set_Priority_To_Invalid_Values
    [Template]  Set Priority To Invalid Value And Expect Error

    # Version Type              Priority
    ${VERSION_PURPOSE_HOST}    ${-1}
    ${VERSION_PURPOSE_HOST}    ${256}


Set RequestedActivation To None
    [Documentation]  Set the RequestedActivation of the image to None and
    ...              verify that it is in fact set to None.
    [Tags]  Set_RequestedActivation_To_None

    ${software_objects}=  Get Software Objects
    Set Host Software Property  @{software_objects}[0]  RequestedActivation
    ...  ${REQUESTED_NONE}
    ${software_properties}=  Get Host Software Property  @{software_objects}[0]
    Should Be Equal As Strings  ${software_properties}[RequestedActivation]
    ...  ${REQUESTED_NONE}


Set RequestedActivation And Activation To Invalid Value
    [Documentation]  Set the RequestedActivation and Activation properties of
    ...              the image to an invalid value and verify that it was not
    ...              changed.
    [Template]  Set Property To Invalid Value And Verify No Change
    [Tags]  Set_RequestedActivation_And_Activation_To_Invalid_Value

    # Property              Version Type
    RequestedActivation     ${VERSION_PURPOSE_HOST}
    Activation              ${VERSION_PURPOSE_HOST}


Upload And Activate Multiple Host Images
    [Documentation]  Upload another PNOR image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_Host_Images
    [Template]  Activate Image And Verify No Duplicate Priorities
    [Setup]  Upload And Activate Multiple BMC Images Setup

    # Image File Path              Image Purpose
    ${ALTERNATE_IMAGE_FILE_PATH}   ${VERSION_PURPOSE_HOST}


Set Same Priority For Multiple Host Images
    [Documentation]  Attempt to set the priority to be the same for two PNOR
    ...              images and verify that the priorities are not the same.
    [Tags]  Set_Same_Priority_For_Multiple_Host_Images

    IF  '${PREV_TEST_STATUS}' == 'FAIL'
        Fail  Activation of alternate image failed. Cannot set priority.
    END
    Set Same Priority For Multiple Images  ${VERSION_PURPOSE_HOST}


Delete Host Image
    [Documentation]  Delete a PNOR image from the BMC and PNOR flash chip.
    [Tags]  Delete_Host_Image
    [Setup]  Initiate Host PowerOff

    ${software_objects}=  Get Software Objects
    ...  version_type=${VERSION_PURPOSE_HOST}
    ${num_images}=  Get Length  ${software_objects}
    Should Be True  0 < ${num_images}
    ...  msg=There are no PNOR images on the BMC to delete.
    Delete Image And Verify  @{software_objects}[0]  ${VERSION_PURPOSE_HOST}


Verify Host Update When Host Reboot During Activation In Progress
    [Documentation]  Attempt to reboot the host while an image is activating.
    [Tags]  Verify_Host_Update_When_Host_Reboot_During_Activation_In_Progress

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    REST Power On
    Delete All Error Logs

    ${version_id}=  Upload And Activate Image  ${ALTERNATE_IMAGE_FILE_PATH}
    ...  wait=${0}

    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Reboot Host during activation.
    Host Reboot

    Wait For Activation State Change  ${version_id}  ${ACTIVATING}

    # New image priority should be 0.
    ${new_host_properties}=
    ...  Get Host Software Property  ${SOFTWARE_VERSION_URI}${version_id}
    Should Be Equal As Integers  ${new_host_properties["Priority"]}  ${0}

    # Reboot host to boot up with the new host image version.
    Host Reboot
    Verify Running Host Image  ${ALTERNATE_IMAGE_FILE_PATH}


*** Keywords ***

Temporarily Set PNOR Attribute
    [Documentation]  Update the PNOR attribute value.
    [Arguments]  ${attribute_name}  ${attribute_value}

    # Description of argument(s):
    # attribute_name    Host software attribute name (e.g. "Priority").
    # attribute_value   Value to be written.

    ${image_ids}=  Get Software Objects
    ${init_host_properties}=  Get Host Software Property  ${image_ids[0]}
    ${initial_priority}=  Set Variable  ${init_host_properties["Priority"]}

    Set Host Software Property  ${image_ids[0]}  ${attribute_name}
    ...  ${attribute_value}

    ${cur_host_properties}=  Get Host Software Property  ${image_ids[0]}
    Should Be Equal As Integers  ${cur_host_properties["Priority"]}
    ...  ${attribute_value}

    # Revert to to initial value.
    Set Host Software Property
    ...  ${image_ids[0]}  ${attribute_name}  ${initial_priority}


Code Update Setup
    [Documentation]  Do code update test case setup.
    # - Clean up all existing BMC dumps.
    # - Clean up all currently install PNOR images.

    Run Keyword And Ignore Error  Smart Power Off
    Run Key  Delete All Dumps  ignore=1
    Run Key  Delete All Error Logs  ignore=1
    IF  'true' == '${DELETE_OLD_PNOR_IMAGES}'  Delete All PNOR Images
    IF  'true' == '${DELETE_OLD_GUARD_FILE}'
        BMC Execute Command
        ...  rm -f /var/lib/phosphor-software-manager/pnor/prsv/GUARD
    END

    BMC Execute Command  rm -rf /tmp/images/*

Upload And Activate Multiple BMC Images Setup
    [Documentation]  Check that the ALTERNATE_FILE_PATH variable is set.

    Should Not Be Empty  ${ALTERNATE_IMAGE_FILE_PATH}
    Delete All PNOR Images
    Upload And Activate Image  ${IMAGE_FILE_PATH}  skip_if_active=true

Get PNOR Extended Version
    [Documentation]  Return the PNOR extended version.
    [Arguments]  ${manifest_path}

    # Description of argument(s):
    # manifest_path  Path of the MANIFEST file
    #                (e.g. "/tmp/images/abc123/MANIFEST").

    ${version}= BMC Execute Command
    ...  grep extended_version= ${manifest_path}
    RETURN   ${version.split(",")}


Code Update Test Teardown
    [Documentation]  Do code update test case teardown.
    # 1. Collect FFDC if test case failed.
    # 2. Collect FFDC if test PASS but error log exists.

    FFDC On Test Case Fail
    IF  '${TEST_STATUS}' == 'PASS'  Check Error And Collect FFDC
