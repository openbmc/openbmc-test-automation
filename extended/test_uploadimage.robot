*** Settings ***
Documentation         Test Upload Image
...                   Execution Method :
...                   python -m robot -v OPENBMC_HOST:<hostname>
...                   -v TFTP_SERVER:<TFTP server IP>
...                   -v TFTP_FILE_NAME:<filename.tar>
...                   -v IMAGE_FILE_PATH:<path/*.tar> test_uploadimage.robot

Resource              ../lib/connection_client.robot
Resource              ../lib/rest_client.robot
Resource              ../lib/openbmc_ffdc.robot
Library               Collections
Library               String
Library               OperatingSystem
Library               test_uploadimage.py

Test Teardown  Upload Image Teardown

Force Tags  Upload_Test

*** Variables ***
${timeout}            10
${UPLOAD_DIR_PATH}    /tmp/images/
${QUIET}              ${1}
${IMAGE_VERSION}      ${EMPTY}
${bad_image_version}  ${EMPTY}

*** Test Cases ***

Upload Image Via REST
    [Documentation]  Upload an image via REST.
    [Tags]  Upload_Image_Via_REST

    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}
    ${IMAGE_VERSION}=  Get Version Tar  ${IMAGE_FILE_PATH}
    ${image_data}=  OperatingSystem.Get Binary File  ${IMAGE_FILE_PATH}
    Upload Post Request  /upload/image  data=${image_data}
    ${ret}=  Verify Image Upload
    Should Be True  True == ${ret}

Upload Image Via TFTP
    [Documentation]  Upload an image via TFTP.
    [Tags]  Upload_Image_Via_TFTP

    @{image}=  Create List  ${TFTP_FILE_NAME}  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  1 minute
    ${upload_file}=  Get Latest File  ${UPLOAD_DIR_PATH}
    ${IMAGE_VERSION}=  Get Image Version
    ...  ${UPLOAD_DIR_PATH}${upload_file}/MANIFEST
    ${ret}=  Verify Image Upload
    Should Be True  True == ${ret}

Upload Image With Bad Manifest Via REST
    [Documentation]  Upload an image with a MANIFEST with an invalid
    ...              purpose via REST and make sure the BMC does not unpack it.
    [Tags]

    ${bad_image_file_path}=  OperatingSystem.Join Path  %{BAD_IMAGES_DIR_PATH}
    ...  bad_manifest_rest.pnor.squashfs.tar
    OperatingSystem.File Should Exist  ${bad_image_file_path}
    ${bad_image_version}=  Get Version Tar  ${bad_image_file_path}
    ${bad_image_data}=  OperatingSystem.Get Binary File  ${bad_image_file_path}
    Upload Post Request  /upload/image  data=${bad_image_data}
    ${ret}=  Verify Image Not On BMC  ${bad_image_version}
    Should Be True  True == ${ret}

Upload Image With Bad Manifest Via TFTP
    [Documentation]  Upload an image with a MANIFEST with an invalid
    ...              purpose via TFTP and make sure the BMC does not unpack it.
    [Tags]

    @{image}=  Create List  bad_manifest_tftp.pnor.squashfs.tar  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  1 minute
    ${bad_image_version}=  Set Variable
    ...  open-power-witherspoon-v1.16-53-gfb396b3-dirty-badmanifesttftp
    ${ret}=  Verify Image Not On BMC  ${bad_image_version}
    Should Be True  True == ${ret}

Upload Image With No Squashfs Via REST
    [Documentation]  Upload an image with no pnor.xz.suashfs file via REST and
    ...              make sure the BMC does not unpack it.
    [Tags]

    ${bad_image_file_path}=  OperatingSystem.Join Path  %{BAD_IMAGES_DIR_PATH}
    ...  no_squashfs_rest.pnor.squashfs.tar
    OperatingSystem.File Should Exist  ${bad_image_file_path}
    ${bad_image_version}=  Get Version Tar  ${bad_image_file_path}
    ${bad_image_data}=  OperatingSystem.Get Binary File  ${bad_image_file_path}
    Upload Post Request  /upload/image  data=${bad_image_data}
    ${ret}=  Verify Image Not On BMC  ${bad_image_version}
    Should Be True  True == ${ret}

Upload Image With No Squashfs Via TFTP
    [Documentation]  Upload an image with no pnor.xz.suashfs file via TFTP and
    ...              make sure the BMC does not unpack it.
    [Tags]

    @{image}=  Create List  no_squashfs_tftp.pnor.squashfs.tar  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  1 minute
    ${bad_image_version}=  Set Variable
    ...  open-power-witherspoon-v1.16-53-gfb396b3-dirty-nosquashfstftp
    ${ret}=  Verify Image Not On BMC  ${bad_image_version}
    Should Be True  True == ${ret}

*** Keywords ***

Upload Image Teardown
    [Documentation]  Log FFDC if test suite fails and collect SOL log for
    ...              debugging purposes.

    Close All Connections
    FFDC On Test Case Fail

Upload Post Request
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    # Description of arguments:
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

