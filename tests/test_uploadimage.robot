*** Settings ***
Documentation  Test Upload Image

Resource          ../lib/connection_client.robot
Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Library           Collections
Library           String
Library           OperatingSystem

Test Teardown  FFDC On Test Case Fail

*** Variables ***
${timeout}           10
${UPLOAD_DIR}        /tmp/images/
${QUIET}  ${1}

*** Test Cases ***

Upload Image Via REST
    [Documentation]  Upload an image via REST.
    [Tags]  Uploading_Images_Via_REST

    OperatingSystem.File Should Exist  ${IMAGE_PATH}
    ${data}=  OperatingSystem.Get Binary File  ${IMAGE_PATH}
    ${resp}=  Upload Post Request
    ...  /upload/image  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Upload Image Via REST With Name
    [Documentation]  Upload an image via REST with name.
    [Tags]  Uploading_Images_Via_REST

    Open Connection And Log In
    Execute Command  "rm -rf ${UPLOAD_DIR}${TFTP_FILENAME}"
    OperatingSystem.File Should Exist  ${IMAGE_PATH}
    ${data}=  OperatingSystem.Get Binary File  ${IMAGE_PATH}
    ${resp}=  Upload Put Request
    ...  /upload/image/${TFTP_FILENAME}  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${UPLOAD_DIR}${TFTP_FILENAME}
    ...   return_stderr=True  return_rc=True
    Close All Connections
    Should Be Equal  ${rc}  ${0}

Upload Image Via TFTP
    [Documentation]  Upload an image via TFTP.
    [Tags]  Upload_Images_Via_TFTP

    Open Connection And Log In
    Execute Command  "rm -rf ${UPLOAD_DIR}${TFTP_FILENAME}"
    @{image}=  Create List  ${TFTP_FILENAME}  ${TFTP_SERVER}
    ${data}=  Create Dictionary  data=@{image}
    ${resp}=  OpenBMC Post Request
    ...       ${SOFTWARE_VERSION_URI}/action/DownloadViaTFTP  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${UPLOAD_DIR}${TFTP_FILENAME}
    ...   return_stderr=True  return_rc=True
    Close All Connections
    Should Be Equal  ${rc}  ${0}

*** Keywords ***

Upload Post Request
    [Arguments]  ${uri}  ${timeout}=10  ${quiet}=${QUIET}  &{kwargs}

    Initialize OpenBMC  ${timeout}  quiet=${quiet}
    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...          Accept=application/octet-stream
    set to dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Post
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Post Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    [Return]  ${ret}

Upload Put Request
    [Arguments]  ${uri}  ${timeout}=10  &{kwargs}

    Initialize OpenBMC  ${timeout}
    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...          Accept=application/octet-stream
    set to dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Put
    ...  base_uri=${base_uri}  args=&{kwargs}
    ${ret}=  Put Request  openbmc  ${base_uri}  &{kwargs}  timeout=${timeout}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    [Return]  ${ret}
