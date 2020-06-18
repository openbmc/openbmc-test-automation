*** Settings ***


Documentation     Suite to test certificate via DMTF redfishtool.

Library           OperatingSystem
Library           String
Library           Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/certificate_utils.robot
Resource          ../../lib/dmtf_redfishtool_utils.robot

Suite Setup       Suite Setup Execution


*** Variables ***

${root_cmd_args} =  SEPARATOR=
...  redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always


*** Test Cases ***


Verify Redfishtool Replace Server Certificate Valid CertKey
    [Documentation]  Verify replace server certificate.
    [Tags]  Verify_Redfishtool_Replace_Server_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Server  Valid Certificate Valid Privatekey  ok


Verify Redfishtool Replace Client Certificate Valid CertKey
    [Documentation]  Verify replace client certificate.
    [Tags]  Verify_Redfishtool_Replace_Client_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Client  Valid Certificate Valid Privatekey  ok


Verify Redfishtool Replace CA Certificate Valid Cert
    [Documentation]  Verify replace CA certificate.
    [Tags]  Verify_Redfishtool_Replace_CA_Certificate_Valid_Cert

    Verify Redfishtool Replace Certificate  CA  Valid Certificate  ok


Verify Redfishtool Client Certificate Install Valid CertKey
    [Documentation]  Verify client certificate installation.
    [Tags]  Verify_Redfishtool_Client_Certificate_Install_Valid_CertKey

    Verify Redfishtool Install Certificate  Client  Valid Certificate Valid Privatekey  ok


Verify Redfishtool CA Certificate Install Valid Cert
    [Documentation]  Verify CA Certificate installation.
    [Tags]  Verify_Redfishtool_CA_Certificate_Install_Valid_Cert

    Verify Redfishtool Install Certificate  CA  Valid Certificate  ok


Verify Redfishtool Replace Server Certificate Errors
    [Documentation]  Verify error while replacing invalid server certificate.
    [Tags]  Verify_Redfishtool_Replace_Server_Certificate_Errors
    [Template]  Verify Redfishtool Replace Certificate

    Server  Empty Certificate Empty Privatekey  error
    Server  Empty Certificate Valid Privatekey  error
    Server  Valid Certificate Empty Privatekey  error


Verify Redfishtool Replace Client Certificate Errors
    [Documentation]  Verify error while replacing invalid client certificate.
    [Tags]  Verify_Redfishtool_Replace_Client_Certificate_Errors
    [Template]  Verify Redfishtool Replace Certificate

    Client  Empty Certificate Empty Privatekey  error
    Client  Empty Certificate Valid Privatekey  error
    Client  Valid Certificate Empty Privatekey  error


Verify Redfishtool Replace CA Certificate Errors
    [Documentation]  Verify error while replacing invalid CA certificate.
    [Tags]  Verify_Redfishtool_Replace_CA_Certificate_Errors
    [Template]  Verify Redfishtool Replace Certificate

    CA  Empty Certificate  error


Verify Redfishtool Client Certificate Install Errors
    [Documentation]  Verify error while installing invalid client certificate.
    [Tags]  Verify_Redfishtool_Client_Certificate_Install_Errors
    [Template]  Verify Redfishtool Install Certificate

    Client  Empty Certificate Empty Privatekey  error
    Client  Empty Certificate Valid Privatekey  error
    Client  Valid Certificate Empty Privatekey  error


*** Keywords ***


Verify Redfishtool Install Certificate
    [Documentation]  Install and verify certificate using Redfishtool.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}  ${delete_cert}=${True}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format
    # expected_status     Expected status of certificate install Redfishtool
    #                     request (i.e. "ok" or "error").
    # delete_cert         Certificate will be deleted before installing if this True.

    Run Keyword If  '${cert_type}' == 'CA' and '${delete_cert}' == '${True}'
    ...  Delete All CA Certificate Via Redfisthtool
    ...  ELSE IF  '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
    ...  Redfishtool Delete Certificate Via BMC CLI  ${cert_type}

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    ${cert_id}=  Redfishtool Install Certificate File On BMC
    ...  ${certificate_uri}  ${expected_status}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    # Adding delay after certificate installation.
    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${bmc_cert_content}=  Run Keyword If  '${expected_status}' == 'ok'
    ...  Redfishtool GetAttribute  ${certificate_uri}/${cert_id}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'  Should Contain  ${cert_file_content}  ${bmc_cert_content}

    [Return]  ${cert_id}


Delete All CA Certificate Via Redfisthtool
    [Documentation]  Delete all CA certificate via Redfish.

    ${cmd_output}=  Redfishtool Get  /redfish/v1/Managers/bmc/Truststore/Certificates
    ${json_object}=  To JSON  ${cmd_output}
    ${cert_list}=  Set Variable  ${json_object["Members"]}
    FOR  ${cert}  IN  @{cert_list}
      Redfishtool Delete  ${cert["@odata.id"]}  ${root_cmd_args}
    END


Redfishtool Delete Certificate Via BMC CLI
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


Redfishtool Install Certificate File On BMC
    [Documentation]  Install certificate file in BMC using POST operation.
    [Arguments]  ${uri}  ${status}=ok  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via Redfishtool.
    #             e.g. "/redfish/v1/AccountService/LDAP/Certificates".
    # status      Expected status of certificate installation via Redfishtool.
    #             e.g. error, ok.
    # kwargs      A dictionary of keys/values to be passed directly to
    #             POST Request.

    Initialize OpenBMC  20  ${quiet}=${1}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}
    Set To Dictionary  ${kwargs}  headers  ${headers}

    ${ret}=  Post Request  openbmc  ${uri}  &{kwargs}
    ${content_json}=  To JSON  ${ret.content}
    ${cert_id}=  Set Variable If  '${ret.status_code}' == '${HTTP_OK}'  ${content_json["Id"]}  -1

    Run Keyword If  '${status}' == 'ok'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}
    ...  ELSE IF  '${status}' == 'error'
    ...  Should Be Equal As Strings  ${ret.status_code}  ${HTTP_INTERNAL_SERVER_ERROR}

    Delete All Sessions

    [Return]  ${cert_id}


Verify Redfishtool Replace Certificate
    [Documentation]  Verify replace server certificate.
    [Arguments]   ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type        Certificate type (e.g. "Client", "Server" or "CA").
    # cert_format      Certificate file format
    #                  (e.g. "Valid_Certificate_Valid_Privatekey").
    # expected_status  Expected status of certificate replace Redfishtool
    #                  request (i.e. "ok" or "error").

    # Install certificate before replacing client or CA certificate.
    ${cert_id}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    Verify Redfishtool Install Certificate  ${cert_type}  Valid Certificate Valid Privatekey  ok
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Verify Redfishtool Install Certificate  ${cert_type}  Valid Certificate  ok

    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Server'  ${REDFISH_HTTPS_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}/1
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}/${cert_id}

    ${certificate_dict}=  Create Dictionary  @odata.id=${certificate_uri}
    ${dict_objects}=  Create Dictionary  CertificateString=${file_data}
    ...  CertificateType=PEM  CertificateUri=${certificate_dict}
    ${string}=  Convert To String  ${dict_objects}
    ${string}=  Replace String  ${string}  '  "
    ${payload}=  Set Variable  '${string}'

    ${expected_resp}=  Set Variable If  '${expected_status}' == 'ok'  ${HTTP_OK}
    ...  '${expected_status}' == 'error'  ${HTTP_NOT_FOUND}

    ${response}=  Redfishtool Post
    ...  ${payload}  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate
    ...  expected_error=${expected_resp}

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Redfishtool GetAttribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Redfishtool GetAttribute
    [Documentation]  Execute redfishtool for GET operation.
    [Arguments]  ${uri}  ${Attribute}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri             URI for GET operation (e.g. /redfish/v1/AccountService/Accounts/).
    # Attribute       The specific attribute to be retrieved with the URI.
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} GET ${uri}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}
    ${json_object}=  To JSON  ${cmd_output}

    [Return]  ${json_object["CertificateString"]}


Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
