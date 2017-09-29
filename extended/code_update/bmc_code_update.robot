*** Settings ***
Documentation     Update the BMC code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  bmc_code_update.robot

Library           ../../lib/code_update_utils.py
Variables         ../../data/variables.py
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/dump_utils.robot

Suite Setup       Code Update Suite Setup

Test Teardown     Code Update Test Teardown

*** Variables ***

${QUIET}                          ${1}
${IMAGE_FILE_PATH}                ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}      ${EMPTY}
${SKIP_UPDATE_IF_ACTIVE}          false
${dump_id}                        ${EMPTY}

*** Test Cases ***

Prepare Persistent Data
    [Documentation]  Set data that should persist across the code update.
    [Tags]  Prepare_Persistent_Data
    [Teardown]  No Operation

    # Install the debug tarball.
    BMC Execute Command  rm -rf /tmp/tarball
    Install Debug Tarball On BMC  tarball_file_path=${DEBUG_TARBALL_PATH}

    # Create a dummy error log and dump.
    BMC Execute Command  /tmp/tarball/bin/logging-test -c AutoTestSimple
    ${dump_id}=  Create User Initiated Dump
    Check Dump Existence  ${dump_id}
    Set Suite Variable  ${dump_id}

    # Set persistent settings.
    ${autoreboot_dict}=  Create Dictionary  data=${0}
    Write Attribute  ${CONTROL_HOST_URI}auto_reboot  AutoReboot
    ...  data=${autoreboot_dict}
    ${onetime_dict}=  Create Dictionary  data=${0}
    Write Attribute  ${CONTROL_HOST_URI}boot/one_time  Enabled
    ...  data=${onetime_dict}

REST BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via REST.
    [Tags]  REST_BMC_Code_Update
    [Teardown]  No Operation

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    ...  skip_if_active=${SKIP_UPDATE_IF_ACTIVE}
    OBMC Reboot (off)
    Verify Running BMC Image  ${IMAGE_FILE_PATH}


Verify Error Log Persistency
    [Documentation]  Check that the error log is still present after a
    ...              code update.
    [Tags]  Verify_Error_Log_Persistency
    [Teardown]  No Operation

    ${error_log_paths}=  Read Properties  ${BMC_LOGGING_URI}/list
    ${test_error_message}=  Read Attribute  @{error_log_paths}[-1]  Message
    Should Be Equal  ${test_error_message}
    ...  example.xyz.openbmc_project.Example.Elog.AutoTestSimple
    Delete Error Log Entry  @{error_log_paths}[-1]


Verify BMC Dump Persistency
    [Documentation]  Check that the BMC dump present after a code update.
    [Tags]  Verify_BMC_Dump_Persistency

    Check Dump Existence  ${dump_id}
    Delete BMC Dump  ${dump_id}


Verify Settings Persistency
    [Documentation]  Verify that the settings from 'Prepare Persistent Data'
    ...              are still set correctly after the code update.
    [Tags]  Verify_Settings_Persistency

    ${autoreboot_enabled}=  Read Attribute  ${CONTROL_HOST_URI}auto_reboot
    ...  AutoReboot
    Should Be Equal  ${autoreboot_enabled}  ${0}
    ${onetime_enabled}=  Read Attribute  ${CONTROL_HOST_URI}boot/one_time
    ...  Enabled
    Should Be Equal  ${onetime_enabled}  ${0}

    # Set values back to their defaults
    ${autoreboot_dict}=  Create Dictionary  data=${1}
    Write Attribute  ${CONTROL_HOST_URI}auto_reboot  AutoReboot
    ...  data=${autoreboot_dict}
    ${onetime_dict}=  Create Dictionary  data=${1}
    Write Attribute  ${CONTROL_HOST_URI}boot/one_time  Enabled
    ...  data=${onetime_dict}


Upload And Activate Multiple BMC Images
    [Documentation]  Upload another BMC image and verify that its state is
    ...              different from all others.
    [Tags]  Upload_And_Activate_Multiple_BMC_Images
    [Template]  Activate Image And Verify No Duplicate Priorities
    [Setup]  Upload And Activate Multiple BMC Images Setup

    # Image File Path              Image Purpose
    ${ALTERNATE_IMAGE_FILE_PATH}   ${VERSION_PURPOSE_BMC}


BMC Set Priority To Invalid Values
    [Documentation]  Attempt to set the priority of an image to an invalid
    ...              value and expect an error.
    [Tags]  BMC_Set_Priority_To_Invalid_Values
    [Template]  Set Priority To Invalid Value And Expect Error

    # Version Type              Priority
    ${VERSION_PURPOSE_BMC}     ${-1}
    ${VERSION_PURPOSE_BMC}     ${256}


Delete BMC Image
    [Documentation]  Delete a BMC image from the BMC flash chip.
    [Tags]  Delete_BMC_Image

    ${software_object}=  Get Non Running BMC Software Object
    Delete Image And Verify  ${software_object}  ${VERSION_PURPOSE_BMC}


BMC Image Priority Attribute Test
    [Documentation]  Set "Priority" attribute.
    [Tags]  BMC_Image_Priority_Attribute_Test
    [Template]  Temporarily Set BMC Attribute

    # Property        Value
    Priority          ${0}
    Priority          ${1}
    Priority          ${127}
    Priority          ${255}


*** Keywords ***

Temporarily Set BMC Attribute
    [Documentation]  Update the BMC attribute value.
    [Arguments]  ${attribute_name}  ${attribute_value}

    # Description of argument(s):
    # attribute_name    BMC software attribute name (e.g. "Priority").
    # attribute_value   Value to be written.

    ${image_ids}=  Get Software Objects  ${VERSION_PURPOSE_BMC}
    ${init_bmc_properties}=  Get Host Software Property  ${image_ids[0]}
    ${initial_priority}=  Set Variable  ${init_bmc_properties["Priority"]}

    Set Host Software Property  ${image_ids[0]}  ${attribute_name}
    ...  ${attribute_value}

    ${cur_bmc_properties}=  Get Host Software Property  ${image_ids[0]}
    Should Be Equal As Integers  ${cur_bmc_properties["Priority"]}
    ...  ${attribute_value}

    # Revert to to initial value.
    Set Host Software Property
    ...  ${image_ids[0]}  ${attribute_name}  ${initial_priority}


Upload And Activate Multiple BMC Images Setup
    [Documentation]  Check that the ALTERNATE_FILE_PATH variable is set.

    Should Not Be Empty  ${ALTERNATE_IMAGE_FILE_PATH}

Code Update Suite Setup
    [Documentation]  Do code update test case setup.
    # - Clean up all existing BMC dumps.

    Delete All Dumps
    Run Keyword And Ignore Error  Smart Power Off

Code Update Test Teardown
    [Documentation]  Do code update test case teardown.
    # 1. Collect FFDC if test case failed.
    # 2. Collect FFDC if test PASS but error log exists.

    FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'PASS'  Check Error And Collect FFDC
