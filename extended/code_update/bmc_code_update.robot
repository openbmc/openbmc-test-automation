*** Settings ***
Documentation     Update the BMC code on a target BMC.
...               Execution Method:
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v IMAGE_FILE_PATH:<path/*.tar>  bmc_code_update.robot

Library           ../../lib/code_update_utils.py
Library           ../../lib/gen_robot_keyword.py
Variables         ../../data/variables.py
Resource          ../../lib/utils.robot
Resource          ../../lib/boot_utils.robot
Resource          code_update_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/dump_utils.robot
Resource          ../../lib/certificate_utils.robot

Suite Setup       Suite Setup Execution

Test Teardown     Test Teardown Execution

Force Tags        BMC_Code_Update

*** Variables ***

${QUIET}                          ${1}
${IMAGE_FILE_PATH}                ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}      ${EMPTY}
${SKIP_UPDATE_IF_ACTIVE}          false
${dump_id}                        ${EMPTY}
${running_persistence_test}       ${FALSE}
${test_errlog_text}               AutoTestSimple

*** Test Cases ***

Test Basic BMC Performance Before BMC Code Update
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Test_Basic_BMC_Performance_Before_BMC_Code_Update

    Open Connection And Log In
    Check BMC Performance

Prepare Persistent Data
    [Documentation]  Set data that should persist across the code update.
    [Tags]  Prepare_Persistent_Data

    # Install the debug tarball.
    BMC Execute Command  rm -rf /tmp/tarball
    Install Debug Tarball On BMC  tarball_file_path=${DEBUG_TARBALL_PATH}

    # Create a dummy error log and dump.
    BMC Execute Command  /tmp/tarball/bin/logging-test -c ${test_errlog_text}
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

    # Let the remaining test cases know we are doing a persistence test so we
    # do not delete logs.
    Set Suite Variable  ${running_persistence_test}  ${TRUE}


REST BMC Code Update
    [Documentation]  Do a BMC code update by uploading image on BMC via REST.
    [Tags]  REST_BMC_Code_Update
    [Teardown]  REST BMC Code Update Teardown

    Run Keyword And Ignore Error  List Installed Images  BMC

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    ...  skip_if_active=${SKIP_UPDATE_IF_ACTIVE}
    OBMC Reboot (off)
    Verify Running BMC Image  ${IMAGE_FILE_PATH}


Verify Error Log Persistency
    [Documentation]  Check that the error log is still present after a
    ...              code update.
    [Tags]  Verify_Error_Log_Persistency

    ${error_log_paths}=  Read Properties  ${BMC_LOGGING_URI}/list
    Log To Console  ${error_log_paths}
    ${test_error_message}=  Read Attribute  @{error_log_paths}[-1]  Message
    Should Be Equal  ${test_error_message}
    ...  example.xyz.openbmc_project.Example.Elog.${test_errlog_text}
    Delete Error Log Entry  @{error_log_paths}[-1]


Verify BMC Dump Persistency
    [Documentation]  Check that the BMC dump present after a code update.
    [Tags]  Verify_BMC_Dump_Persistency
    [Teardown]  Set Suite Variable  ${running_persistence_test}  ${FALSE}

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


Delete All Non Running BMC Images
    [Documentation]  Delete all non running BMC images.
    [Tags]  Delete_All_Non_Running_BMC_Images

    ${version_id}=  Upload And Activate Image  ${ALTERNATE_IMAGE_FILE_PATH}
    ...  skip_if_active=true
    Delete All Non Running BMC Images

    ${software_ids}=  Get Software Objects Id
    ...  version_type=${VERSION_PURPOSE_BMC}
    Should Not Contain  ${software_ids}  ${version_id}


Test Certificate Persistency After BMC Code Update
    [Documentation]  Test certificate persistency after BMC update.
    [Tags]  Test_Certificate_Persistency_After_BMC_Code_Update

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
    OperatingSystem.Directory Should Exist  ${EXECDIR}${/}certificate_dir

    ${cert_file_path}=  Generate Certificate File Via Openssl
    ...  Valid Certificate Valid Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File On BMC  ${CLIENT_CERTIFICATE_URI}
    ...  data=${file_data}

    ${bmc_cert_content}=  Get Certificate File Content From BMC  Client
    Should Contain  ${cert_file_content}  ${bmc_cert_content}

    Upload And Activate Image  ${IMAGE_FILE_PATH}
    ...  skip_if_active=${SKIP_UPDATE_IF_ACTIVE}
    OBMC Reboot (off)
    Verify Running BMC Image  ${IMAGE_FILE_PATH}

    ${bmc_cert_content}=  Get Certificate File Content From BMC  Client
    Should Contain  ${cert_file_content}  ${bmc_cert_content}


Test Basic BMC Performance After Code Update
    [Documentation]  Check performance of memory, CPU & file system of BMC.
    [Tags]  Test_Basic_BMC_Performance_After_Code_Update

    Open Connection And Log In
    Check BMC Performance


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


REST BMC Code Update Teardown
    [Documentation]  Do code update test teardown.

    FFDC On Test Case Fail
    Run Keyword If Test Failed  Fatal Error  msg=Code update failed.


Suite Setup Execution
    [Documentation]  Do code update test case setup.
    # - Clean up all existing BMC dumps.

    Run Key  Delete All Dumps  ignore=1
    Run Keyword And Ignore Error  Smart Power Off

Test Teardown Execution
    [Documentation]  Do code update test case teardown.
    # 1. Collect FFDC if test case failed.
    # 2. Collect FFDC if test PASS but error log exists.

    # Don't delete our logs if we want to persist them for tests.
    Return From Keyword If  ${running_persistence_test}

    FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'PASS'  Check Error And Collect FFDC
    Close All Connections
