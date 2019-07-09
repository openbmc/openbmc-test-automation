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
    Should Be Equal   ${apply_time}  xyz.openbmc_project.Software.ApplyTime.RequestedApplyTimes.OnReset

    # Download image from TFTP server to BMC.
    Redfish.Post  /redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate
    ...  body={"TransferProtocol" : "TFTP", "ImageURI" : "${TFTP_SERVER}/${IMAGE_FILE_NAME}"}
    ...  valid_status_codes=[${HTTP_OK}]

    # Wait for image tar file to download complete.
    ${image_id}=  Wait Until Keyword Succeeds  60 sec  10 sec  Image Id Should Exist
    Rprint Vars  image_id  fmt=terse

    # Let the image get extracted and it should not fail.
    Sleep  5s
    ${update_state}=  Image Update Progress State  image_id=${image_id}
    Should Not Be Equal  Disabled  ${update_state}

    # Get image version currently installation in progress.
    ${install_version}=  Get Image Version  image_id=${image_id}

    Image Update Progress State  image_id=${image_id}  expect_state=Updating

    # Wait for the image to install complete.
    Wait Until Keyword Succeeds  5 min  15 sec
    ...  Image Update Progress State  image_id=${image_id}  expect_state=Enabled

    Redfish OBMC Reboot (off)

    # Verify the image is installed and functional.
    ${functional_version}=  Get BMC Version
    Rprint Vars  functional_version  fmt=terse
    Should Be Equal  ${functional_version}  "${install_version}"


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Rvalid Value  TFTP_SERVER
    Rvalid Value  IMAGE_FILE_NAME


Image Id Should Exist
    [Documentation]  Recent extracted image directory should exist.

    ${image_id}=  Get Latest File  /tmp/images/
    Should Not Be Empty  ${image_id}

    # It could so happen that image extract is in progress, check one of the file
    # needed to be in the extracted directory.
     BMC Execute Command  ls -l /tmp/images/${image_id}/MANIFEST

    [Return]  ${image_id}


Image Update Progress State
    [Documentation]  Firmware update progress state.
    [Arguments]  ${image_id}  ${expect_state}=${EMPTY}

    # Description of argument(s):
    # image_id         Temp image id name.
    # expect_state     Update progress (e.g. "Enabled", "Disabled", "Updating").

    # Example:
    #  "Status": {
    #              "Health": "OK",
    #              "HealthRollup": "OK",
    #              "State": "Enabled"
    #            },
    ${update_status}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Status
    Rprint Vars  update_status  fmt=terse

    Run Keyword If  '${expect_state}' != '${EMPTY}'  Should Be Equal  ${update_status["State"]}  ${expect_state}

    [Return]  ${update_status["State"]}


Get Image Version
    [Documentation]  Firmware image version to be installed.
    [Arguments]  ${image_id}

    # Description of argument(s):
    # image_id         Temp image id name.

    ${version}=  Redfish.Get Attribute  /redfish/v1/UpdateService/FirmwareInventory/${image_id}  Version
    Rprint Vars  version  fmt=terse

    [Return]  ${version}
