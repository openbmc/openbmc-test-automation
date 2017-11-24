*** Settings ***
Documentation         Test upload image with both valid and invalid images.
...                   This test expects there to be bad image tarballs named
...                   pnor_bad_manifest.tar, pnor_no_image.tar,
...                   bmc_bad_manifest.tar, and bmc_no_image.tar on the TFTP
...                   server and in the BAD_IMAGES_DIR_PATH directory.
...                   Execution Method :
...                   python -m robot -v OPENBMC_HOST:<hostname>
...                   -v TFTP_SERVER:<TFTP server IP>
...                   -v PNOR_TFTP_FILE_NAME:<filename.tar>
...                   -v BMC_TFTP_FILE_NAME:<filename.tar>
...                   -v PNOR_IMAGE_FILE_PATH:<path/*.tar>
...                   -v BMC_IMAGE_FILE_PATH:<path/*.tar>
...                   -v BAD_IMAGES_DIR_PATH:<path> test_image_upload.robot

Resource              ../../lib/connection_client.robot
Resource              ../../lib/rest_client.robot
Resource              ../../lib/openbmc_ffdc.robot
Library               Collections
Library               String
Library               OperatingSystem
Library               ../../lib/code_update_utils.py

Test Teardown  Upload Image Teardown

Force Tags  Upload_Test

*** Variables ***
${timeout}            10
${QUIET}              ${1}

*** Test Cases ***

Upload Host Image Via REST
    # Image File Path

    ${PNOR_IMAGE_FILE_PATH}

    [Documentation]  Upload a PNOR image via REST.
    [Template]  Upload Image Via REST And Verify Success
    [Tags]  Upload_Host_Image_Via_REST


Upload BMC Image Via REST
    # Image File Path

    ${BMC_IMAGE_FILE_PATH}

    [Documentation]  Upload a BMC image via REST.
    [Template]  Upload Image Via REST And Verify Success
    [Tags]  Upload_BMC_Image_Via_REST


Upload Host Image Via TFTP
    # Image File Path

    ${PNOR_TFTP_FILE_NAME}

    [Documentation]  Upload a PNOR image via TFTP.
    [Template]  Upload Image Via TFTP And Verify Success
    [Tags]  Upload_Host_Image_Via_TFTP


Upload BMC Image Via TFTP
    # Image File Path

    ${BMC_TFTP_FILE_NAME}

    [Documentation]  Upload a BMC image via TFTP
    [Template]  Upload Image Via TFTP And Verify Success
    [Tags]  Upload_BMC_Image_Via_TFTP


Upload Host Image With Bad Manifest Via REST
    # Image File Name

    pnor_bad_manifest.tar

    [Documentation]  Upload a PNOR image with a bad MANIFEST via REST and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via REST And Verify Failure
    [Tags]  Upload_Host_Image_With_Bad_Manifest_Via_REST


Upload Host Image With No Squashfs Via REST
    # Image File Name

    pnor_no_image.tar

    [Documentation]  Upload a PNOR image with just a MANIFEST file via REST
    ...              and verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via REST And Verify Failure
    [Tags]  Upload_Host_Image_With_No_Squashfs_Via_REST


Upload BMC Image With Bad Manifest Via REST
    # Image File Name

    bmc_bad_manifest.tar

    [Documentation]  Upload a BMC image with a bad MANFIEST file via REST and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via REST And Verify Failure
    [Tags]  Upload_BMC_Image_With_Bad_Manifest_Via_REST


Upload BMC Image With No Image Via REST
    # Image File Name

    bmc_no_image.tar

    [Documentation]  Upload a BMC image with no just a MANIFEST file via REST
    ...              and verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via REST And Verify Failure
    [Tags]  Upload_BMC_Image_With_No_Image_Via_REST


Upload Host Image With Bad Manifest Via TFTP
    # Image File Name

    pnor_bad_manifest.tar

    [Documentation]  Upload a PNOR image with a bad MANIFEST file via TFTP and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via TFTP And Verify Failure
    [Tags]  Upload_Host_Image_With_Bad_Manifest_Via_TFTP


Upload Host Image With No Squashfs Via TFTP
    # Image File Name

    pnor_no_image.tar

    [Documentation]  Upload a PNOR image with just a MANIFEST file via TFTP and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via TFTP And Verify Failure
    [Tags]  Upload_Host_Image_With_No_Squashfs_Via_TFTP


Upload BMC Image With Bad Manifest Via TFTP
    # Image File Name

    bmc_bad_manifest.tar

    [Documentation]  Upload a BMC image with a bad MANIFEST file via TFTP and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via TFTP And Verify Failure
    [Tags]  Upload_BMC_Image_With_Bad_Manifest_Via_TFTP


Upload BMC Image With No Image Via TFTP
    # Image File Name

    bmc_no_image.tar

    [Documentation]  Upload a BMC image with just a MANIFEST file via TFTP and
    ...              verify that the BMC does not unpack it.
    [Template]  Upload Bad Image Via TFTP And Verify Failure
    [Tags]  Upload_BMC_Image_With_No_Image_Via_TFTP


*** Keywords ***

Upload Image Teardown
    [Documentation]  Log FFDC if test fails for debugging purposes.

    Open Connection And Log In
    Execute Command On BMC  rm -rf /tmp/images/*

    Close All Connections
    FFDC On Test Case Fail


Upload Post Request
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    # Description of argument(s):
    # uri             URI for uploading image via REST.
    # timeout         Time allocated for the REST command to return status.
    # quiet           If enabled turns off logging to console.
    # kwargs          A dictionary that maps each keyword to a value.

    Initialize OpenBMC  ${timeout}  quiet=${quiet}
    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  Accept=application/octet-stream
    Set To Dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Post Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}

Get Image Version From TFTP Server
    [Documentation]  Get the version dfound in the MANIFEST file of
    ...              an image on the given TFTP server.
    [Arguments]  ${tftp_image_file_path}

    # Description of argument(s):
    # tftp_image_file_path  The path to the image on the TFTP server.

    ${stripped_file_path}=  Strip String  ${tftp_image_file_path}  characters=/
    ${rc}=  OperatingSystem.Run And Return RC
    ...  curl -s tftp://${TFTP_SERVER}/${stripped_file_path} > tftp_image.tar
    Should Be Equal As Integers  0  ${rc}
    ...  msg=Could not download image to check version.
    ${version}=  Get Version Tar  tftp_image.tar
    OperatingSystem.Remove File  tftp_image.tar
    [Return]  ${version}

Upload Image Via REST And Verify Success
    [Documentation]  Upload an image to the BMC and check that it is unpacked.

    # Upload the given good image to the BMC via REST, and check that the
    # BMC has unpacked the image and created a valid D-Bus entry for it.

    [Arguments]  ${image_file_path}

    # Description of argument(s):
    # image_file_path  The path to the image file to upload.

    OperatingSystem.File Should Exist  ${image_file_path}
    ${image_version}=  Get Version Tar  ${image_file_path}
    ${image_data}=  OperatingSystem.Get Binary File  ${image_file_path}
    Upload Image To BMC  /upload/image  data=${image_data}
    ${ret}  ${version_id}=  Verify Image Upload  ${image_version}
    Should Be True  ${ret}

Upload Image Via TFTP And Verify Success
    [Documentation]  Upload an image to the BMC and check that it was unpacked.

    # Upload the given good image to the BMC via TFTP, and check that the
    # BMC has unpacked the image and created a valid D-Bus entry for it.

    [Arguments]  ${image_file_name}

    # Description of argument(s):
    # image_file_name  The name of the image file on the TFTP server.

    @{image}=  Create List  ${image_file_name}  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  1 minute
    ${image_version}=  Get Image Version From TFTP Server  ${image_file_name}
    ${ret}  ${version_id}=  Verify Image Upload  ${image_version}
    Should Be True  ${ret}

Upload Bad Image Via REST And Verify Failure
    [Documentation]  Upload the given bad image to the BMC via REST and check
    ...              that the BMC did not unpack the invalid image.
    [Arguments]  ${bad_image_file_name}

    # Description of argument(s):
    # image_file_name  The name of the bad image to upload via REST.

    ${bad_image_file_path}=  OperatingSystem.Join Path  ${BAD_IMAGES_DIR_PATH}
    ...  ${bad_image_file_name}
    OperatingSystem.File Should Exist  ${bad_image_file_path}
    ...  msg=Bad image file ${bad_image_file_name} not found.
    ${bad_image_version}=  Get Version Tar  ${bad_image_file_path}
    ${bad_image_data}=  OperatingSystem.Get Binary File  ${bad_image_file_path}
    Upload Post Request  /upload/image  data=${bad_image_data}
    Sleep  5s
    Verify Image Not In BMC Uploads Dir  ${bad_image_version}

Upload Bad Image Via TFTP And Verify Failure
    [Documentation]  Upload the given bad image to the BMC via TFTP and check
    ...              that the BMC did not unpack the invalid image.
    [Arguments]  ${bad_image_file_name}

    # Description of argument(s):
    # image_file_name  The name of the bad image to upload via TFTP.

    @{image}=  Create List  ${bad_image_file_name}  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${bad_image_version}=  Get Image Version From TFTP Server
    ...  ${bad_image_file_name}
    Sleep  5s
    Verify Image Not In BMC Uploads Dir  ${bad_image_version}
