*** Settings ***
Documentation  Certificate utilities keywords.

Library        OperatingSystem
Resource       rest_client.robot
Resource       resource.robot


*** Keywords ***

Install Certificate File On BMC
    [Documentation]  Install certificate file in BMC using REST PUT operation.
    [Arguments]  ${uri}  ${status}=ok  ${quiet}=${1}  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via REST
    #             e.g. "/xyz/openbmc_project/certs/server/https".
    # status      Expected status of certificate installation via REST
    #             e.g. error, ok.
    # quiet       If enabled, turns off logging to console.
    # kwargs      A dictionary of keys/values to be passed directly to
    #             PUT Request.

    Initialize OpenBMC  quiet=${quiet}

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${kwargs}  headers  ${headers}

    Run Keyword If  '${quiet}' == '${0}'  Log Request  method=Put
    ...  base_uri=${uri}  args=&{kwargs}

    ${ret}=  Put Request  openbmc  ${uri}  &{kwargs}
    Run Keyword If  '${quiet}' == '${0}'  Log Response  ${ret}

    Run Keyword If  '${status}' == 'ok'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    ...  ELSE IF  '${status}' == 'error'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_BAD_REQUEST}

    Delete All Sessions


Get Certificate Content From BMC Via Openssl
    [Documentation]  Get certificate content from BMC via openssl.

    Check If Openssl Tool Exist

    ${openssl_cmd}=  Catenate
    ...  openssl s_client -connect ${OPENBMC_HOST}:443 -showcerts
    ${rc}  ${output}=  Run And Return RC and Output  ${openssl_cmd}
    Should Be Equal  ${rc}  ${0}  msg=${output}

    ${result}=  Fetch From Left
    ...  ${output}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    [Return]  ${result}


Get Certificate File Content From BMC
    [Documentation]  Get required certificate file content from BMC.
    [Arguments]  ${cert_type}=Client

    # Description of argument(s):
    # cert_type      Certificate type (e.g. "Client" or "CA").

    ${certificate}  ${stderr}  ${rc}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    BMC Execute Command  cat /etc/nslcd/certs/cert.pem
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    BMC Execute Command  cat /etc/ssl/certs/Root-CA.pem

    [Return]  ${certificate}


Generate Certificate File Via Openssl
    [Documentation]  Create certificate file via openssl with required content
    ...              and returns its path.
    [Arguments]  ${cert_format}  ${time}=365  ${cert_dir_name}=certificate_dir

    # Description of argument(s):
    # cert_format          Certificate file format
    #                      e.g. Valid_Certificate_Empty_Privatekey.
    # time                 Number of days to certify the certificate for.
    # cert_dir_name        The name of the sub-directory where the certificate
    #                      is stored.

    Check If Openssl Tool Exist

    ${openssl_cmd}=  Catenate  openssl req -x509 -sha256 -newkey rsa:2048
    ...  ${SPACE}-nodes -days ${time}
    ...  ${SPACE}-keyout ${cert_dir_name}/cert.pem -out ${cert_dir_name}/cert.pem
    ...  ${SPACE}-subj "/O=XYZ Corporation /CN=www.xyz.com"

    ${rc}  ${output}=  Run And Return RC and Output  ${openssl_cmd}
    Should Be Equal  ${rc}  ${0}  msg=${output}
    OperatingSystem.File Should Exist
    ...  ${EXECDIR}${/}${cert_dir_name}${/}cert.pem

    ${file_content}=  OperatingSystem.Get File
    ...  ${EXECDIR}${/}${cert_dir_name}${/}cert.pem
    ${result}=  Fetch From Left  ${file_content}  -----END CERTIFICATE-----
    ${cert_content}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----

    ${result}=  Fetch From Left  ${file_content}  -----END PRIVATE KEY-----
    ${private_key_content}=  Fetch From Right  ${result}  -----BEGIN PRIVATE KEY-----

    ${cert_data}=
    ...  Run Keyword if  '${cert_format}' == 'Valid Certificate Valid Privatekey'
    ...  OperatingSystem.Get File  ${EXECDIR}${/}${cert_dir_name}${/}cert.pem
    ...  ELSE IF  '${cert_format}' == 'Empty Certificate Valid Privatekey'
    ...  Remove String  ${file_content}  ${cert_content}
    ...  ELSE IF  '${cert_format}' == 'Valid Certificate Empty Privatekey'
    ...  Remove String  ${file_content}  ${private_key_content}
    ...  ELSE IF  '${cert_format}' == 'Empty Certificate Empty Privatekey'
    ...  Remove String  ${file_content}  ${cert_content}  ${private_key_content}
    ...  ELSE IF  '${cert_format}' == 'Expired Certificate'
    ...  OperatingSystem.Get File  ${EXECDIR}${/}${cert_dir_name}${/}cert.pem
    ...  ELSE IF  '${cert_format}' == 'Valid Certificate'
    ...  Remove String  ${file_content}  ${private_key_content}
    ...  -----BEGIN PRIVATE KEY-----  -----END PRIVATE KEY-----
    ...  ELSE IF  '${cert_format}' == 'Empty Certificate'
    ...  Remove String  ${file_content}  ${cert_content}
    ...  ${private_key_content}  -----BEGIN PRIVATE KEY-----
    ...  -----END PRIVATE KEY-----

    ${random_name}=  Generate Random String  8
    ${cert_name}=  Catenate  SEPARATOR=  ${random_name}  .pem
    Create File  ${cert_dir_name}/${cert_name}  ${cert_data}

    [Return]  ${EXECDIR}${/}${cert_dir_name}${/}${cert_name}


Get Certificate Content From File
    [Documentation]  Get certificate content from certificate file.
    [Arguments]  ${cert_file_path}

    # Description of argument(s):
    # cert_file_path  Downloaded certificate file path.

    ${file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${result}=  Fetch From Left  ${file_content}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    [Return]  ${result}


Check If Openssl Tool Exist
    [Documentation]  Check if openssl tool installed or not.

    ${rc}  ${output}=  Run And Return RC and Output  which openssl
    Should Not Be Empty  ${output}  msg=Openssl tool not installed.

