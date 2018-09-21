*** Settings ***
Documentation  Certificate utilities keywords.

Library        OperatingSystem
Resource       rest_client.robot
Resource       resource.txt


*** Keywords ***

Install Certificate File In BMC
    [Documentation]  Install certificate file in BMC using REST PUT operation.
    [Arguments]  ${uri}  ${status}=ok  ${quiet}=${1}  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via REST
    #             e.g. "/xyz/openbmc_project/certs/server/https".
    # status      Expected status of certificate installation via REST
    #             e.g. error, ok.
    # quiet       If enabled, turns off logging to console.
    # kwargs      A dictionary keys/values to be passed directly to
    #             PUT Request.

    Initialize OpenBMC  quiet=${quiet}

    ${base_uri}=  Catenate  SEPARATOR=  ${DBUS_PREFIX}  ${uri}
    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    set to dictionary  ${kwargs}  headers  ${headers}

    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Put
    ...  base_uri=${base_uri}  args=&{kwargs}
    Log Request  method=Put  base_uri=${base_uri}  args=&{kwargs}

    ${ret}=  Put Request  openbmc  ${base_uri}  &{kwargs}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}

    Run Keyword If  '${status}' == 'ok'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    ...  ELSE IF  '${status}' == 'error'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_SERVICE_UNAVAILABLE}

    Delete All Sessions


Get Certificate Content Via Openssl
    [Documentation]  Get certificate content via openssl.

    Check If Openssl Tool Exist

    ${openssl_cmd}=  Catenate  openssl s_client -connect ${OPENBMC_HOST}:443 -showcerts
    ${rc}  ${output}=  Run And Return RC and Output  ${openssl_cmd}
    Should Be Equal  ${rc}  ${0}  msg=${output}
    ${result}=  Fetch From Left
    ...  ${output}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    Log to console  ${result}
    [Return]  ${result}


Create Certificate File Via Openssl
    [Documentation]  Create certificate file via openssl with required content.
    [Arguments]  ${required_certificate_content}

    # Description of argument(s):
    # required_certificate_content  Required content in certificate file.
    #                               e.g. Valid_Certificate_Empty_Privatekey

    Check If Openssl Tool Exist

    ${openssl_cmd}=  Catenate  openssl req -x509 -sha256 -newkey rsa:2048
    ...  ${SPACE}-nodes -days 365
    ...  ${SPACE}-keyout cert.pem -out cert.pem
    ...  ${SPACE}-subj "/O=XYZ Corporation /CN=www.xyz.com"

    ${rc}  ${output}=  Run And Return RC and Output  ${openssl_cmd}
    Should Be Equal  ${rc}  ${0}  msg=${output}
    OperatingSystem.File Should Exist  ${EXECDIR}${/}cert.pem

    ${file_content}=  OperatingSystem.Get File  ${EXECDIR}${/}cert.pem
    ${result}=  Fetch From Left  ${file_content}  -----END CERTIFICATE-----
    ${certificate_content}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----

    ${result}=  Fetch From Left  ${file_content}  -----END PRIVATE KEY-----
    ${private_key_content}=  Fetch From Right  ${result}  -----BEGIN PRIVATE KEY-----

    ${certificate}=
    ...  Run Keyword if  '${required_certificate_content}' == 'Valid_Certificate_Valid_Privatekey'
    ...  OperatingSystem.Get File  ${EXECDIR}${/}cert.pem
    ...  ELSE IF  '${required_certificate_content}' == 'Empty_Certificate_Valid_Privatekey'
    ...  Remove String  ${file_content}  ${certificate_content}
    ...  ELSE IF  '${required_certificate_content}' == 'Valid_Certificate_Empty_Privatekey'
    ...  Remove String  ${file_content}  ${private_key_content}
    ...  ELSE IF  '${required_certificate_content}' == 'Empty_Certificate_Empty_Privatekey'
    ...  Remove String  ${file_content}  ${certificate_content}  ${private_key_content}

    Log to console  ${certificate}
    Create File  certnew.pem  ${certificate}
    [Return]  ${EXECDIR}${/}certnew.pem


Get Certificate Content From File
    [Documentation]  Get certificate content from certificate file.
    [Arguments]  ${certificate_file_path}

    # Description of argument(s):
    # certificate_file_path  Downloaded certificate file path.

    ${file_content}=  OperatingSystem.Get File  ${certificate_file_path}
    ${result}=  Fetch From Left  ${file_content}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    Log to console  ${result}
    [Return]  ${result}


Check If Openssl Tool Exist
    [Documentation]  Check if openssl tool installed or not.
    ${rc}  ${output}=  Run And Return RC and Output  which openssl
    Should Not Be Empty  ${output}  msg=Openssl tool not installed.

