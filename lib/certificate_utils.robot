*** Settings ***
Documentation  Certificate utilities keywords.

Resource       rest_client.robot
Resource       resource.txt


*** Keywords ***

Update Certificate File In BMC
    [Documentation]  Update certificate file in BMC using REST PUT operation.
    [Arguments]  ${uri}  ${quiet}=${1}  &{kwargs}

    # Description of argument(s):
    # uri         URI for updating certificate file via REST
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
