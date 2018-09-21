*** Settings ***

Documentation  Test certificate in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot

Test Teardown  FFDC On Test Case Fail

*** Variables ***


*** Test Cases ***

Upload Valid Server Certificate File
    [Documentation]  Upload a valid server certificate file via REST.
    [Tags]  Upload_Valid_Server_Certificate_File
    [Template]  Upload Certificate Via REST

    # Certificate type  Certificate file path
    Server Certificate  ${VALID_CERTIFICATE_FILE_PATH}


***Keywords***

Upload Certificate Via REST
    [Documentation]  Upload given certificate to the BMC via REST.
    [Arguments]  ${certificate_type}  ${certificate_file_path}
    # Description of argument(s):
    # certificate_type       Certificate type(e.g Server Certificate
    #                        or Client Certificate).
    # certificate_file_path  Downloaded certificate file path.

    OperatingSystem.File Should Exist  ${certificate_file_path}
    ${file_data}=  OperatingSystem.Get Binary File  ${certificate_file_path}
    Run Keyword If  '${certificate_type}' == 'Server Certificate'
    ...    Upload Certificate File To BMC  ${SERVER_CERTIFICATE_URI}
    ...    data=${file_data}
    ...  ELSE IF  '${certificate_type}' == 'Client Certificate'
    ...    Upload Certificate File To BMC  ${CLIENT_CERTIFICATE_URI}
    ...    data=${file_data}


Upload Certificate File To BMC
    [Documentation]  Upload certificate file to BMC using REST PUT operation.
    [Arguments]  ${uri}  ${quiet}=${1}  &{kwargs}
    # Description of argument(s):
    # uri         URI for uploading certificate file via REST
    #             e.g. "/xyz/openbmc_project/certs/server/https".
    # quiet       If enabled, turns off logging to console.
    # kwargs      A dictionary keys/values to be passed directly to
    #             PUT Request.

    Initialize OpenBMC  quiet=${quiet}

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    set to dictionary  ${kwargs}  headers  ${headers}
    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Put
    ...  base_uri=${base_uri}  args=&{kwargs}

    ${ret}=  Put Request  openbmc  ${base_uri}  &{kwargs}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}
    Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    Delete All Sessions
