*** Settings ***
Documentation         Test upload image with both valid and invalid images.
...                   This test expects there to be bad image tarballs named
...                   bmc_bad_manifest.ubi.mtd.tar, bmc_nokernel_image.ubi.mtd.tar,
...                   bmc_invalid_key.ubi.mtd.tar,
...                   pnor_bad_manifest.pnor.squashfs.tar,
...                   pnor_nokernel_image.pnor.squashfs.tar,
...                   pnor_invalid_key.pnor.squashfs.tar, on the TFTP
...                   server and in the BAD_IMAGES_DIR_PATH directory.
...                   Execution Method :
...                   python -m robot -v OPENBMC_HOST:<hostname>
...                   -v TFTP_SERVER:<TFTP server IP>
...                   -v PNOR_TFTP_FILE_NAME:<filename.tar>
...                   -v BMC_TFTP_FILE_NAME:<filename.tar>
...                   -v BAD_IMAGES_DIR_PATH:<path> test_redfish_image_upload.robot

Resource              ../../lib/connection_client.robot
Resource              ../../lib/rest_client.robot
Resource              ../../lib/openbmc_ffdc.robot
Resource              ../../lib/bmc_redfish_resource.robot
Resource              ../../lib/code_update_utils.robot
Library               OperatingSystem
Library               ../../lib/code_update_utils.py
Library               ../../lib/gen_robot_valid.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

Force Tags  Upload_Test

*** Variables ***
${timeout}            20
${QUIET}              ${1}


*** Test Cases ***

Redfish Upload BMC Image With Bad Manifest
    [Documentation]  Upload a BMC firmware with a bad MANFIEST file.
    [Tags]  Redfish_Upload_BMC_Firmware_With_Bad_Manifest
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    bmc_bad_manifest.ubi.mtd.tar


Redfish Upload BMC Image With No Image
    [Documentation]  Upload a BMC firmware with no kernel image.
    [Tags]  Redfish_Upload_BMC_Firmware_With_No_Image
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    bmc_nokernel_image.ubi.mtd.tar


Redfish Upload Host Image With Bad Manifest
    [Documentation]  Upload a PNOR firmware with a bad MANIFEST file.
    [Tags]  Redfish_Upload_Host_Fimware_With_Bad_Manifest
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    pnor_bad_manifest.pnor.squashfs.tar


Redfish Upload Host Image With No Image
    [Documentation]  Upload a PNOR firmware with no kernel Image.
    [Tags]  Redfish_Upload_Host_Fimware_With_No_Image
    [Template]  Redfish Bad Firmware Update

    # Image File Name
    pnor_nokernel_image.pnor.squashfs.tar


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Delete All BMC Dump
    Redfish Purge Event Log


Redfish Bad Firmware Update
    [Documentation]  Redfish firmware update.
    [Arguments]  ${bad_image_file_name}

    # Description of argument(s):
    # bad_image_file_name  The path to the image tarball.

    ${bad_image_file_path}=  OperatingSystem.Join Path  ${BAD_IMAGES_DIR_PATH}
    ...  ${bad_image_file_name}
    OperatingSystem.File Should Exist  ${bad_image_file_path}

    Set ApplyTime  policy=OnReset
    ${image_data}=  OperatingSystem.Get Binary File  ${bad_image_file_path}
    ${http_status}=  Upload Image To BMC And Return Status
    ...  ${REDFISH_BASE_URI}UpdateService
    ...  ${timeout}  ${QUIET}  data=${image_data}

    Pass Execution If  ${http_status.status_code} == ${HTTP_INTERNAL_SERVER_ERROR}
    ...  Firmware update Un-successful.

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id
    ${status}=  Run keyword And Return Status  Check Image Update Progress State
    ...  match_state='Updating', 'Disabled'  image_id=${image_id}
    Delete Software Object  /xyz/openbmc_project/software/${image_id}

    Pass Execution if  ${http_status.status_code} == ${HTTP_OK} and ${status} == True
    ...  Firmware update Un-successful.

