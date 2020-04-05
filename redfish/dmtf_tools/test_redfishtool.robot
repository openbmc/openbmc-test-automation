*** Settings ***
Documentation    Verify Redfish tool functionality.


Library           OperatingSystem
Library           String
Library           Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/certificate_utils.robot

Suite Setup       Suite Setup Execution

*** Variables ***

${root_cmd_args}       redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always


*** Test Cases ***


Verify Redfishtool Replace Server Certificate valid cert format
    [Documentation]  Verify replace server certificate.

    Verify Redfishtool Replace Certificate  Server  Valid Certificate Valid Privatekey

Verify Redfishtool Replace Client Certificate valid cert format
    [Documentation]  Verify replace client certificate.

    Verify Redfishtool Replace Certificate  Client  Valid Certificate Valid Privatekey

Verify Redfishtool Replace CA Certificate valid cert format
    [Documentation]  Verify replace CA certificate.

    Verify Redfishtool Replace Certificate  CA  Valid Certificate

Verify Redfishtool Client Certificate Install valid cert format
    [Documentation]  Verify client certificate installation.

    Verify Redfishtool Install Certificate  Client  Valid Certificate Valid Privatekey

Verify Redfishtool CA Certificate Install valid cert format
    [Documentation]  Verify CA Certificate installation.

    Verify Redfishtool Install Certificate  CA  Valid Certificate


*** Keywords ***


Verify Redfishtool Install Certificate
    [Documentation]  Install and verify certificate using Redfishtool.
    [Arguments]  ${cert_type}  ${cert_format}  ${delete_cert}=${True}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format

    Run Keyword If  '${cert_type}' == 'Client' and '${delete_cert}' == '${True}'
    ...  Delete Certificate Via BMC CLI  ${cert_type}

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    ${cert_id}=  Redfishtool Install Certificate File On BMC  ${certificate_uri}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    # Adding delay after certificate installation.
    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${bmc_cert_content}=  Redfishtool GetAttribute  ${certificate_uri}/${cert_id}  CertificateString

    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    [Return]  ${cert_id}

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
    [Arguments]   ${cert_type}  ${cert_format}

    Create Directory  certificate_dir
    # Install certificate before replacing client or CA certificate.
    ${cert_id}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    Verify Redfishtool Install Certificate  ${cert_type}  Valid Certificate Valid Privatekey
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Verify Redfishtool Install Certificate  ${cert_type}  Valid Certificate

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}
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
    ${response}=  Redfishtool Post  ${payload}  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Redfishtool GetAttribute  ${certificate_uri}  CertificateString
    Should Contain  ${cert_file_content}  ${bmc_cert_content}

Is HTTP error Expected
    [Documentation]  Check if the HTTP error is expected.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    ${error_expected}=  Evaluate  "${error_expected}" in """${cmd_output}"""
    Should Be True  ${error_expected} == True

Redfishtool GetAttribute
    [Documentation]  Execute redfishtool for GET operation.
    [Arguments]  ${uri}  ${Attribute}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} GET ${uri}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}
    ${json_object}=  To JSON  ${cmd_output}
    [Return]  ${json_object["CertificateString"]}

Redfishtool Post
    [Documentation]  Execute redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # payload         Payload with POST operation (e.g. data for user name, password, role,
    #                 enabled attribute)
    # uri             URI for POST operation (e.g. /redfish/v1/AccountService/Accounts/).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} POST ${uri} --data=${payload}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}


Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
