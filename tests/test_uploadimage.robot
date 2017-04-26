*** Settings ***
Documentation  Test Upload Image

Resource          ../lib/connection_client.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Library           RequestsLibrary.RequestsKeywords
Library           Collections
Library           String
Library           OperatingSystem


*** Variables ***
${timeout}                10
${DEFAULT_TFTP_SERVER}=   9.3.164.219
${DEFAULT_TFTP_FILE}=     pnor.squashfs.tar
${DEFAULT_UPLOAD_FILE}=   data/UploadImageTestFile
${UPLOAD_DIR}=            /tmp/images/


*** Test Cases ***

Upload Image Via REST Without Name
    [Documentation]  Test uploads an image (for example to upgrade the
    ...              BMC or host software) via REST. The file name on
    ...              the BMC will be chosen by the REST server.
    [Tags]  Uploading_Images_Via_REST

    ${data}=  OperatingSystem.Get File  ${DEFAULT_UPLOAD_FILE}
    ${file}=  Create Dictionary  files=${data}
    ${resp}=  Upload Post Request
    ...  /upload/image  files=${file}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}

Upload Image Via REST With Name
    [Documentation]  Test uploads an image (for example to upgrade the
    ...              BMC or host software) via REST. The file name on
    ...              the BMC will be chosen by the user.
    [Tags]  Uploading_Images_Via_REST

    Delete File if Exist  ${DEFAULT_TFTP_FILE}  ${UPLOAD_DIR}
    ${data}=  OperatingSystem.Get File  ${DEFAULT_UPLOAD_FILE}
    ${file}=  Create Dictionary  files=${data}
    ${resp}=  Upload Put Request
    ...  /upload/image/${DEFAULT_TFTP_FILE}  files=${file}
    Should Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    ${ret}=  Check if File Exist  ${DEFAULT_TFTP_FILE}  ${UPLOAD_DIR}
    Should Be Equal  ${ret}  ${0}

Upload Image Via TFTP
    [Documentation]  Test uploads an image (for example to upgrade the
    ...              BMC or host software) via TFTP. The file name on
    ...              the BMC will be chosen by the user.
    [Tags]  Uploading_Images_Via_TFTP

    Delete File if Exist  ${DEFAULT_TFTP_FILE}  ${UPLOAD_DIR}
    @{image}=  Create List  ${DEFAULT_TFTP_FILE}  ${DEFAULT_TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...  ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${ret}=  Check if File Exist  ${DEFAULT_TFTP_FILE}  ${UPLOAD_DIR}
    Should Be Equal  ${ret}  ${0}

*** Keywords ***

Delete File if Exist
    [Documentation]  Delete the file from the path provided by the
    ...              calling function.
    [Arguments]    ${filename}    ${filepath}

    Open Connection And Log In
    Execute Command   rm -rf ${filepath}${filename}
    Close All Connections

Check if File Exist
    [Documentation]  Check if the file exists in the path provided by the
    ...              calling function.
    [Arguments]      ${filename}    ${filepath}

    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${filepath}${filename}
    ...   return_stderr=True  return_rc=True
    Close All Connections
    [Return]   ${rc}

Upload Post Request
    [Arguments]    ${uri}    ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    Initialize OpenBMC    ${timeout}  quiet=${quiet}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=     Create Dictionary   Content-Type=application/octet-stream
    set to dictionary   ${kwargs}       headers     ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Post Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    [Return]    ${ret}

Upload Put Request
    [Arguments]    ${uri}    ${timeout}=10    &{kwargs}

    Initialize OpenBMC    ${timeout}
    ${base_uri}=    Catenate    SEPARATOR=    ${DBUS_PREFIX}    ${uri}
    ${headers}=     Create Dictionary   Content-Type=application/octet-stream
    set to dictionary   ${kwargs}       headers     ${headers}
    Log Request    method=Put    base_uri=${base_uri}    args=&{kwargs}
    ${ret}=  Put Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Log Response    ${ret}
    [Return]    ${ret}
