*** Settings ***
Documentation    Firmware image (BMC and Host) upload test using TFTP protocol.

# Test Parameters:
# TFTP_SERVER        The TFTP server host name or IP address.
# IMAGE_FILE_NAME    The BMC or Host image file name.
#
# Firmware update states:
#     Enabled  -> Image is installed and either functional or active.
#     Disabled -> Image installation failed or ready for activation.
#     Updating -> Image installation currently in progress.

Resource         ../../lib/resource.robot
Resource         ../../lib/boot_utils.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/code_update_utils.robot
Resource         ../../lib/redfish_code_update_utils.robot
Resource         ../../lib/utils.robot
Library          ../../lib/code_update_utils.py
Library          ../../lib/gen_robot_valid.py
Library          ../../lib/tftp_update_utils.py

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Setup       Run Keywords  Redfish Power Off  stack_mode=skip  quiet=1  AND  Redfish.Login
Test Teardown    FFDC On Test Case Fail

Force Tags       tftp_update

*** Test Cases ***

TFTP Download Install With ApplyTime OnReset Policy
    [Documentation]  Download image to BMC using TFTP with OnReset policy and verify installation.
    [Tags]  TFTP_Download_Install_With_ApplyTime_OnReset_Policy
    [Template]  TFTP Download Install

    # policy
    OnReset


TFTP Download Install With ApplyTime Immediate Policy
    [Documentation]  Download image to BMC using TFTP with Immediate policy and verify installation.
    [Tags]  TFTP_Download_Install_With_ApplyTime_Immediate_Policy
    [Template]  TFTP Download Install

    # policy
    Immediate


ImageURI Download Install With ApplyTime OnReset Policy
    [Documentation]  Download image to BMC using ImageURI with OnReset policy and verify installation.
    [Tags]  ImageURI_Download_Install_With_ApplyTime_OnReset_Policy
    [Template]  ImageURI Download Install

    # policy
    OnReset


ImageURI Download Install With ApplyTime Immediate Policy
    [Documentation]  Download image to BMC using ImageURI with Immediate policy and verify installation.
    [Tags]  ImageURI_Download_Install_With_ApplyTime_Immediate_Policy
    [Template]  ImageURI Download Install

    # policy
    Immediate


Install Same Image Two Times
    [Documentation]  Install firmware image and re-try using the same image which should fail.
    [Tags]  Install_Same_Image_Two_Times
    [Template]  Same Firmware Install Two Times

    # policy
    Immediate


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Valid Value  TFTP_SERVER
    Valid Value  IMAGE_FILE_NAME


TFTP Download Install
    [Documentation]  Download image to BMC using TFTP with ApplyTime policy and verify installation.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${policy}

    # Download image from TFTP server to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"TransferProtocol" : "TFTP", "ImageURI" : "${TFTP_SERVER}/${IMAGE_FILE_NAME}"}

    # Wait for image tar file to download complete.
    ${image_id}=  Wait Until Keyword Succeeds  180 sec  10 sec  Get Latest Image ID
    Rprint Vars  image_id

    # Let the image get extracted and it should not fail.
    Sleep  5s
    Check Image Update Progress State  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Get image version currently installation in progress.
    ${install_version}=  Get Firmware Image Version  image_id=${image_id}
    Rprint Vars  install_version

    Check Image Update Progress State  match_state='Updating'  image_id=${image_id}

    # Wait for the image to install complete.
    Wait Until Keyword Succeeds  8 min  15 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    Run Key  ${post_code_update_actions['BMC image']['${policy}']}

    # Verify the image is installed and functional.
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '=' | sed 's/"//g'
    ${functional_version}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Valid Value  functional_version  valid_values=['${install_version}']
    Rprint Vars  functional_version


ImageURI Download Install
    [Documentation]  Download image to BMC using ImageURI with ApplyTime policy and verify installation.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${policy}

    # Download image from TFTP server via ImageURI to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"ImageURI": "tftp://${TFTP_SERVER}/${IMAGE_FILE_NAME}"}

    # Wait for image tar file download to complete.
    ${image_id}=  Wait Until Keyword Succeeds  180 sec  10 sec  Get Latest Image ID
    Rprint Vars  image_id

    # Let the image get extracted and it should not fail.
    Sleep  5s
    Check Image Update Progress State  match_state='Disabled', 'Updating'  image_id=${image_id}

    ${install_version}=  Get Firmware Image Version  image_id=${image_id}
    Rprint Vars  install_version

    Check Image Update Progress State  match_state='Updating'  image_id=${image_id}

    # Wait for the image to install complete.
    Wait Until Keyword Succeeds  8 min  15 sec
    ...  Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}

    Run Key  ${post_code_update_actions['BMC image']['${policy}']}

    # Verify the image is installed and functional.
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '=' | sed 's/"//g'
    ${functional_version}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Valid Value  functional_version  valid_values=['${install_version}']
    Rprint Vars  functional_version


Same Firmware Install Two Times
    [Documentation]  Download same image twice to BMC via ImageURI. Second attempt would fail.
    [Arguments]  ${apply_time}  ${tftp_server}=${TFTP_SERVER}  ${image_file_name}=${IMAGE_FILE_NAME}

    # Description of argument(s):
    # apply_time       ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # tftp_server      Server IP.
    # image_file_name  Image file name.

    ImageURI Download Install  ${apply_time}

    # Download image from TFTP server via ImageURI to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"ImageURI": "tftp://${tftp_server}/${image_file_name}"}

    ${image_version}=  Get Image Version From TFTP Server  ${tftp_server}  ${image_file_name}
    ${software_inventory_record}=  Get Software Inventory State By Version
    ...  ${image_version}
    Rprint Vars  software_inventory_record

    ${image_id}=  Wait Until Keyword Succeeds  180 sec  10 sec  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State  match_state='Enabled'  image_id=${image_id}
    # Check if the existing firmware is functional.
    Pass Execution If  ${software_inventory_record['functional']}
    ...  The existing ${image_version} firmware is already functional.

