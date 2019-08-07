*** Settings ***
Documentation     Update the BMC code on a target BMC via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH    The path to the BMC image file.
#
# Firmware update states:
#     Enabled        Image is installed and either functional or active.
#     Disabled       Image installation failed or ready for activation.
#     Updating       Image installation currently in progress.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/redfish_code_update_utils.robot
Library           ../../lib/gen_robot_valid.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

Force Tags   BMC_Code_Update

*** Variables ***
${onreset}        OnReset
${priority}       Priority
${functional}     functional
${image_id}       image_id

*** Test Cases ***

Redfish BMC Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_BMC_Code_Update

    ${image_version}=  Get Version Tar  ${image_file_path}

    ${resp_swinv_dict}=  Get Software Inventory State By Version  ${image_version}

    ${num_records}=  Get Length  ${resp_swinv_dict}

    ${status}=  Run Keyword If  '${num_records}' != '0'
    ...  Pre Setup Code update  ${image_version}  ${resp_swinv_dict}

    Run Keyword If  '${True}' == '${status}'
    ...  Pass Execution  Pre-Setup Code Update Successful.

    Redfish Update Firmware  ${onreset}

*** Keywords ***

Pre Setup Code update
    [Documentation]  If Image is active, set priority to least value
    ...  If image is functional, do nothing.
    [Arguments]  ${image_version}  ${sw_inv_dict}

    # Description of argument(s):
    # image_version       The Fimware image version (e.g. ibm-v.x-xx).
    # sw_inv_dict         Software inventory details.
    # Software inventory dictionary contains:
    # sw_inv_dict:
    # [image_id]:         449344f3
    # [version]:          ibm-v2.7.0-rc1 
    # [functional]:       False 
    # [image_type]:       BMC update

    ${image_version}=  Get Version Tar  ${image_file_path}

    ${ret_status}=  Run Keyword If  '${sw_inv_dict['${functional}']}' != 'True'
    ...  Run Keyword And Return Status
    ...      Set BMC Image Priority To Least  ${image_version}  ${sw_inv_dict}
    ...  ELSE
    ...   Run Keyword And Return Status
    ...       Should Be Equal  ${sw_inv_dict['${functional}']}  ${True}

    [Return]  ${ret_status}


Get Image Priority
    [Documentation]  Get Current Image Priority.
    [Arguments]  ${image_version}  ${sw_inv_dict}

    # Description of argument(s):
    # image_version       The Fimware image version (e.g. ibm-v.x-xx).
    # sw_inv_dict         Software inventory details.
    # Software inventory dictionary contains:
    # sw_inv_dict:
    # [image_id]:         449344f3
    # [version]:          ibm-v2.7.0-rc1
    # [functional]:       False
    # [image_type]:       BMC update

    ${sw_list}=  Get Software Objects  ${VERSION_PURPOSE_BMC}

    ${resp_image_id}=  Get From Dictionary  ${sw_inv_dict}  ${image_id}

    FOR  ${item}  IN  @{sw_list}
        ${rest}  ${last}=  Split String From Right  ${item}  /  1
        ${curr_value}=  Run Keyword If  '${resp_image_id}' == '${last}'
        ...  Run Keyword And Return
        ...      Read Software Attribute  ${item}  ${priority}
    END


Set BMC Image Priority To Least
    [Documentation]  Set BMC image priority to least value.
    [Arguments]  ${image_version}  ${sw_inv_dict}

    # Description of argument(s):
    # image_version       The Fimware image version (e.g. ibm-v.x-xx).
    # sw_inv_dict         Software inventory details.
    # Software inventory dictionary contains:
    # sw_inv_dict:
    # [image_id]:         449344f3
    # [version]:          ibm-v2.7.0-rc1
    # [functional]:       False
    # [image_type]:       BMC update

    ${image_id}=  Get From Dictionary  ${sw_inv_dict}  ${image_id}

    ${least_priority}=  Get Least Value Priority Image  ${VERSION_PURPOSE_BMC}

    ${cur_priority}=  Get Image Priority  ${image_version}  ${sw_inv_dict}

    Run Keyword If  '${least_priority}' != ${cur_priority}
    ...  Run Keyword
    ...      Set Host Software Property
    ...      ${SOFTWARE_VERSION_URI}${image_id}  Priority  ${least_priority}

    # Reboot BMC And Login
    Redfish OBMC Reboot (off)
    Redfish.Login


Redfish Update Firmware
    [Documentation]  Code update with ApplyTime i.e.
    ...  OnReset and verify installation.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    Set ApplyTime  policy=${apply_time}

    ${base_redfish_uri}=  Set Variable  ${REDFISH_BASE_URI}UpdateService

    Redfish Upload Image  ${base_redfish_uri}  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Wait a few seconds to check if the update progress started.
    Sleep  5s
    Check Image Update Progress State  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  5 min  20 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    # Reboot BMC And Verify BMC Image
    Redfish OBMC Reboot (off)
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}


Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

    # Delete BMC dump and Error logs
    Delete All BMC Dump
    Redfish Purge Event Log

    # Checking for file existence.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}

