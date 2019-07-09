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
Library          ../../lib/code_update_utils.py
Library          ../../lib/gen_robot_valid.py

Suite Setup      Suite Setup Execution
Suite Teardown   Redfish.Logout
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Force Tags       tftp_update

*** Test Cases ***

TFTP Download Install With ApplyTime OnReset Policy
    [Documentation]  Download image to BMC using TFTP with OnReset policy and verify installation.
    [Tags]  TFTP_Download_Install_With_ApplyTime_OnReset_Policy

    # Set and verify the firmware OnReset policy.
    Redfish.Patch  ${REDFISH_BASE_URI}UpdateService  body={'ApplyTime' : 'OnReset'}
    ${apply_time}=  Read Attribute   ${SOFTWARE_VERSION_URI}apply_time  RequestedApplyTime
    Rprint Vars  apply_time  fmt=terse
    Rvalid Value  apply_time  valid_values=['xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset']

    # Download image from TFTP server to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"TransferProtocol" : "TFTP", "ImageURI" : "${TFTP_SERVER}/${IMAGE_FILE_NAME}"}

    # Wait for image tar file to download complete.
    ${image_id}=  Wait Until Keyword Succeeds  60 sec  10 sec  Get Latest Image ID
    Rprint Vars  image_id  fmt=terse

    # Let the image get extracted and it should not fail.
    Sleep  5s
    Check Image Update Progress State  match_state=Disabled  image_id=${image_id}

    # Get image version currently installation in progress.
    ${install_version}=  Get Firmware Image Version  image_id=${image_id}

    Check Image Update Progress State  match_state=Updating  image_id=${image_id}

    # Wait for the image to install complete.
    Wait Until Keyword Succeeds  5 min  15 sec
    ...  Check Image Update Progress State  match_state=Enabled  image_id=${image_id}

    Redfish OBMC Reboot (off)

    # Verify the image is installed and functional.
    ${functional_version}=  Get BMC Version
    Rprint Vars  functional_version  fmt=terse
    Rvalid Value  functional_version  valid_values=["${install_version}"]


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Rvalid Value  TFTP_SERVER
    Rvalid Value  IMAGE_FILE_NAME


Get Latest Image ID
    [Documentation]  Return the ID of the most recently extracted image.
    # Note: This keyword will fail if there is no such file.

    # Example: # ls /tmp/images/
    #            1b714fb7
    ${image_id}=  Get Latest File  /tmp/images/
    Rvalid Value  image_id

    # It could so happen that image extract is in progress. Check one of the files
    # is in progress needed to be in the extracted directory.
    BMC Execute Command  ls -l /tmp/images/${image_id}/MANIFEST

    [Return]  ${image_id}


Check Image Update Progress State
    [Documentation]  Check that the image update progress state matches the specified state.
    [Arguments]  ${match_state}  ${image_id}
    # match_state     Update progress (e.g. "Enabled", "Disabled", "Updating").
    # image_id         The image ID (e.g. "1b714fb7").

    ${state}=  Get Image Update Progress State  image_id=${image_id}
    Rvalid Value  ${state}  valid_values=['${match_state}']


Get Image Update Progress State
    [Documentation]  Return the current state of the image update.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id         The image ID (e.g. "1b714fb7").

    # Example:
    #  "Status": {
    #              "Health": "OK",
    #              "HealthRollup": "OK",
    #              "State": "Enabled"
    #            },
    ${update_status}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Status
    Rprint Vars  update_status  fmt=terse

    [Return]  ${update_status["State"]}


Get Firmware Image Version
    [Documentation]  Get the version of the currently installed firmware and return it.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id      The image ID (e.g. "1b714fb7").

    # Example of a version returned by this keyword:
    # 2.8.0-dev-19-g6d5764b33
    ${version}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Version
    Rprint Vars  version  fmt=terse

    [Return]  ${version}
