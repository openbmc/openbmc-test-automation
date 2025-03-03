*** Settings ***
Documentation  Certificate utilities keywords.

Library        OperatingSystem
Resource       rest_client.robot
Resource       resource.robot

*** Variables ***

# Default wait sync time for certificate install and restart services.
${wait_time}    30
${keybit_length}  2048

*** Keywords ***

Install Certificate File On BMC
    [Documentation]  Install certificate file in BMC using POST operation.
    [Arguments]  ${uri}  ${status}=ok  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via Redfish
    #             e.g. "/redfish/v1/AccountService/LDAP/Certificates".
    # status      Expected status of certificate installation via Redfish
    #             e.g. error, ok.
    # kwargs      A dictionary of keys/values to be passed directly to
    #             POST Request.

    Initialize OpenBMC

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${kwargs}  headers  ${headers}

    ${resp}=  POST On Session  openbmc  ${uri}  &{kwargs}  expected_status=any
    ${cert_id}=  Set Variable If  '${resp.status_code}' == '${HTTP_OK}'  ${resp.json()["Id"]}  -1

    Run Keyword If  '${status}' == 'ok'
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ...  ELSE IF  '${status}' == 'error'
    ...  Should Be Equal As Strings  ${resp.status_code}  ${HTTP_INTERNAL_SERVER_ERROR}

    Delete All Sessions

    RETURN  ${cert_id}


Get Certificate Content From BMC Via Openssl
    [Documentation]  Get certificate content from BMC via openssl.

    Check If Openssl Tool Exist

    ${openssl_cmd}=  Catenate
    ...  timeout 10  openssl s_client -connect ${OPENBMC_HOST}:${HTTPS_PORT} -showcerts
    ${output}=  Run  ${openssl_cmd}

    ${result}=  Fetch From Left
    ...  ${output}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    RETURN  ${result}


Get Certificate File Content From BMC
    [Documentation]  Get required certificate file content from BMC.
    [Arguments]  ${cert_type}=Client

    # Description of argument(s):
    # cert_type      Certificate type (e.g. "Client" or "CA").

    ${certificate}  ${stderr}  ${rc}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    BMC Execute Command  cat /etc/nslcd/certs/cert.pem

    RETURN  ${certificate}


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

    ${openssl_cmd}=  Catenate  openssl req -x509 -sha256 -newkey rsa:${keybit_length}
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
    ...  ELSE IF  '${cert_format}' == 'Expired Certificate' or '${cert_format}' == 'Not Yet Valid Certificate'
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

    RETURN  ${EXECDIR}${/}${cert_dir_name}${/}${cert_name}


Get Certificate Content From File
    [Documentation]  Get certificate content from certificate file.
    [Arguments]  ${cert_file_path}

    # Description of argument(s):
    # cert_file_path  Downloaded certificate file path.

    ${file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${result}=  Fetch From Left  ${file_content}  -----END CERTIFICATE-----
    ${result}=  Fetch From Right  ${result}  -----BEGIN CERTIFICATE-----
    RETURN  ${result}


Check If Openssl Tool Exist
    [Documentation]  Check if openssl tool installed or not.

    ${rc}  ${output}=  Run And Return RC and Output  which openssl
    Should Not Be Empty  ${output}  msg=Openssl tool not installed.


Verify Certificate Visible Via OpenSSL
    [Documentation]  Checks if given certificate is visible via openssl's showcert command.
    [Arguments]  ${cert_file_path}

    # Description of argument(s):
    # cert_file_path           Certificate file path.

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${openssl_cert_content}=  Get Certificate Content From BMC Via Openssl
    Should Contain  ${cert_file_content}  ${openssl_cert_content}


Delete All CA Certificate Via Redfish
    [Documentation]  Delete all CA certificate via Redfish.
    ${cert_list}=  Redfish_Utils.Get Member List  /redfish/v1/Managers/${MANAGER_ID}/Truststore/Certificates
    FOR  ${cert}  IN  @{cert_list}
      Redfish.Delete  ${cert}  valid_status_codes=[${HTTP_NO_CONTENT}]
      Log To Console  Wait Time started in seconds ${wait_time}
      Sleep  ${wait_time}s
    END


Delete Certificate Via BMC CLI
    [Documentation]  Delete certificate via BMC CLI.
    [Arguments]  ${cert_type}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").

    ${certificate_file_path}  ${certificate_service}  ${certificate_uri}=
    ...  Run Keyword If  '${cert_type}' == 'Client'
    ...    Set Variable  /etc/nslcd/certs/cert.pem  phosphor-certificate-manager@nslcd.service
    ...    ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Set Variable  ${ROOT_CA_FILE_PATH}  phosphor-certificate-manager@authority.service
    ...    ${REDFISH_CA_CERTIFICATE_URI}

    ${file_status}  ${stderr}  ${rc}=  BMC Execute Command
    ...  [ -f ${certificate_file_path} ] && echo "Found" || echo "Not Found"

    Return From Keyword If  "${file_status}" != "Found"
    BMC Execute Command  rm ${certificate_file_path}
    BMC Execute Command  systemctl restart ${certificate_service}
    BMC Execute Command  systemctl daemon-reload
    Wait Until Keyword Succeeds  1 min  10 sec  Redfish.Get  ${certificate_uri}/1
    ...  valid_status_codes=[${HTTP_NOT_FOUND}, ${HTTP_INTERNAL_SERVER_ERROR}]


Replace Certificate Via Redfish
    [Documentation]  Test 'replace certificate' operation in the BMC via Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").

    # Install certificate before replacing client or CA certificate.
    ${cert_id}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate Valid Privatekey  ok
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate  ok

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}

    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    Run Keyword If  '${cert_format}' == 'Expired Certificate'
    ...    Modify BMC Date  future
    ...  ELSE IF  '${cert_format}' == 'Not Yet Valid Certificate'
    ...    Modify BMC Date  old


    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Server'  ${REDFISH_HTTPS_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}/${cert_id}

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${payload}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}

    ${expected_resp}=  Set Variable If  '${expected_status}' == 'ok'  ${HTTP_OK}, ${HTTP_NO_CONTENT}
    ...  '${expected_status}' == 'error'  ${HTTP_NOT_FOUND}, ${HTTP_INTERNAL_SERVER_ERROR}
    ${resp}=  redfish.Post  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  body=${payload}  valid_status_codes=[${expected_resp}]

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  redfish_utils.Get Attribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Install And Verify Certificate Via Redfish
    [Documentation]  Install and verify certificate using Redfish.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}  ${delete_cert}=${True}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format
    #                     (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status     Expected status of certificate replace Redfish
    #                     request (i.e. "ok" or "error").
    # delete_cert         Certificate will be deleted before installing if this True.

    Run Keyword If  '${cert_type}' == 'CA' and '${delete_cert}' == '${True}'
    ...  Delete All CA Certificate Via Redfish
    ...  ELSE IF  '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
    ...  Delete Certificate Via BMC CLI  ${cert_type}

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    Run Keyword If  '${cert_format}' == 'Expired Certificate'  Modify BMC Date  future
    ...  ELSE IF  '${cert_format}' == 'Not Yet Valid Certificate'  Modify BMC Date  old

    ${cert_id}=  Install Certificate File On BMC  ${certificate_uri}  ${expected_status}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    # Adding delay after certificate installation.
    # Lesser wait timing causes bmcweb to restart quickly and breaks the web services.
    Log To Console  Wait Time started in seconds ${wait_time}
    Sleep  ${wait_time}s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Run Keyword If  '${expected_status}' == 'ok'  redfish_utils.Get Attribute
    ...  ${certificate_uri}/${cert_id}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'  Should Contain  ${cert_file_content}  ${bmc_cert_content}
    RETURN  ${cert_id}


Modify BMC Date
    [Documentation]  Modify date in BMC.
    [Arguments]  ${date_set_type}=current

    # Description of argument(s):
    # date_set_type    Set BMC date to a current, future, old date by 375 days.
    #                  current - Sets date to local system date.
    #                  future - Sets to a future date from current date.
    #                  old - Sets to a old date from current date.

    Redfish Power Off  stack_mode=skip
    ${current_date_time}=  Get Current Date
    ${new_time}=  Run Keyword If  '${date_set_type}' == 'current'  Set Variable  ${current_date_time}
    ...  ELSE IF  '${date_set_type}' == 'future'
    ...  Add Time To Date  ${current_date_time}  375 days
    ...  ELSE IF  '${date_set_type}' == 'old'
    ...  Subtract Time From Date  ${current_date_time}  375 days

    # Enable manual mode.
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'ProtocolEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    # Change date format to 2024-03-07T07:58:50+00:00 from 2024-03-07 07:58:50.000.
    ${new_time_format}=  Convert Date  ${new_time}  result_format=%Y-%m-%dT%H:%M:%S+00:00

    # NTP network takes few seconds to restart.
    Wait Until Keyword Succeeds  30 sec  10 sec
    ...  Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}  body={'DateTime': '${new_time}'}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
