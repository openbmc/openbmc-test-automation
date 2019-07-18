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
Library          ../../lib/code_update_utils.py
Library          ../../lib/gen_robot_valid.py
Library          ../../lib/tftp_update_utils.py

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Setup       Redfish Power Off
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

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Rvalid Value  TFTP_SERVER
    Rvalid Value  IMAGE_FILE_NAME


TFTP Download Install
    [Documentation]  Download image to BMC using TFTP with ApplyTime policy and verify installation.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${state}=  Get Pre Reboot State

    Set ApplyTime  policy=${policy}

    # Download image from TFTP server to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"TransferProtocol" : "TFTP", "ImageURI" : "${TFTP_SERVER}/${IMAGE_FILE_NAME}"}

    # Wait for image tar file to download complete.
    ${image_id}=  Wait Until Keyword Succeeds  60 sec  10 sec  Get Latest Image ID
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

    Reboot And Wait For BMC Standby  policy=${policy}  start_boot_seconds=${state['epoch_seconds']}

    # Verify the image is installed and functional.
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '=' | sed 's/"//g'
    ${functional_version}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Rvalid Value  functional_version  valid_values=['${install_version}']
    Rprint Vars  functional_version


ImageURI Download Install
    [Documentation]  Download image to BMC using ImageURI with ApplyTime policy and verify installation.
    [Arguments]  ${policy}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${state}=  Get Pre Reboot State

    Set ApplyTime  policy=${policy}

    # Download image from TFTP server via ImageURI to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"ImageURI": "tftp://${TFTP_SERVER}/${IMAGE_FILE_NAME}"}

    # Wait for image tar file download to complete.
    ${image_id}=  Wait Until Keyword Succeeds  60 sec  10 sec  Get Latest Image ID
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

    Reboot And Wait For BMC Standby  policy=${policy}  start_boot_seconds=${state['epoch_seconds']}

    # Verify the image is installed and functional.
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '=' | sed 's/"//g'
    ${functional_version}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Rvalid Value  functional_version  valid_values=['${install_version}']
    Rprint Vars  functional_version


Reboot And Wait For BMC Standby
    [Documentation]  Reboot or wait for BMC standby post reboot.
    [Arguments]  ${policy}  ${start_boot_seconds}

    # Description of argument(s):
    # policy                ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # start_boot_seconds    See 'Wait For Reboot' for details.

    Run Keyword If  '${policy}' == 'OnReset'
    ...    Redfish OBMC Reboot (off)
    ...  ELSE
    ...    Wait For Reboot  start_boot_seconds=${start_boot_seconds}
