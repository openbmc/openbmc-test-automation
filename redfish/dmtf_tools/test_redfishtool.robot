*** Settings ***
Documentation    Verify Redfish tool functionality.

# The following tests are performed:
#
# create user
# modify user
# delete user
#
# Test Parameters:
# OPENBMC_HOST          The BMC host name or IP address.
# OPENBMC_USERNAME      The username to login to the BMC.
# OPENBMC_PASSWORD      Password for OPENBMC_USERNAME.
#
# We use DMTF Redfishtool for writing openbmc automation test cases.
# DMTF redfishtool is a commandline tool that implements the client
# side of the Redfish RESTful API for Data Center Hardware Management.

*** Settings ***

Library   OperatingSystem
Library   String
Library   Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/certificate_utils.robot

Suite Setup       Suite Setup Execution

*** Variables ***

${root_cmd_args}       redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${HTTP_ERROR}          Error

*** Test Cases ***

Verify Redfishtool Replace Server Certificate valid cert format
    [Documentation]  Verify replace server certificate

    Verify Redfishtool Replace Certificate  Server  Valid Certificate Valid Privatekey

Verify Redfishtool Replace Client Certificate valid cert format
    [Documentation]  Verify replace server certificate

    Verify Redfishtool Replace Certificate  Client  Valid Certificate Valid Privatekey

Verify Redfishtool Replace CA Certificate valid cert format
    [Documentation]  Verify replace server certificate

    Verify Redfishtool Replace Certificate  CA  Valid Certificate Valid Privatekey

Verify Redfishtool Client Certificate Install valid cert format
    [Documentation]  Verify replace server certificate

    Verify Redfishtool Install Certificate  Client  Valid Certificate Valid Privatekey

*** Keywords ***

Verify Redfishtool Install Certificate
    [Documentation]  Install and verify certificate using Redfish.
    [Arguments]  ${cert_type}  ${cert_format}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Client" or "CA").
    # cert_format         Certificate file format

    ${time}=  Set Variable If  '${cert_format}' == 'Expired Certificate'  -10  365
    ${cert_file_path}=  Generate Certificate File Via Openssl  ${cert_format}  ${time}
    ${bytes}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${file_data}=  Decode Bytes To String  ${bytes}  UTF-8

    ${certificate_uri}=  Set Variable If
    ...  '${cert_type}' == 'Client'  ${REDFISH_LDAP_CERTIFICATE_URI}
    ...  '${cert_type}' == 'CA'  ${REDFISH_CA_CERTIFICATE_URI}

    Log To Console  ${file_data}

    ${cert_id}=  Redfishtool Install Certificate File On BMC  ${certificate_uri}  data=${file_data}

    # Adding delay after certificate installation.
    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${bmc_cert_content}=  redfish_utils.Get Attribute  ${certificate_uri}/${cert_id}  CertificateString

    Should Contain  ${cert_file_content}  ${bmc_cert_content}

    [Return]  ${cert_id}

Redfishtool Install Certificate File On BMC
    [Documentation]  Install certificate file in BMC using POST operation.
    [Arguments]  ${uri}  &{kwargs}

    # Description of argument(s):
    # uri         URI for installing certificate file via Redfish
    #             e.g. "/redfish/v1/AccountService/LDAP/Certificates".
    # status      Expected status of certificate installation via Redfish
    #             e.g. error, ok.
    # kwargs      A dictionary of keys/values to be passed directly to
    #             POST Request.

    #Initialize OpenBMC

    ${headers}=  Create Dictionary  Content-Type=application/octet-stream
    ...  X-Auth-Token=${XAUTH_TOKEN}

    Log To Console  ${uri}

    Set To Dictionary  ${kwargs}  headers  ${headers}

    ${string}=  Convert To String  ${kwargs}
    ${string}=  Replace String  ${string}  '  "
    ${payload}=  Set Variable  '${string}'

    ${ret}=  Redfishtool Post  ${payload}  ${uri}

    ${content_json}=  To JSON  ${ret.content}

    ${cert_id}=  Set Variable  ${content_json["Id"]}

    Should Be Equal As Strings  ${ret.status_code}  ${HTTP_OK}

    [Return]  ${cert_id}

Verify Redfishtool Replace Certificate
    [Documentation]  Verify replace server certificate
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
    [return]  ${response}

Check HTTP error
    [Documentation]  Check if there is an HTTP error.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    ${error}=  Evaluate  "${HTTP_ERROR}" in """${cmd_output}"""
    ${error_expected}=  Run Keyword If  ${error}
    ...  Evaluate  "${error_expected}" in """${cmd_output}"""
    ...  ELSE
    ...  Set Variable  False
    Run Keyword If  ${error} == True  Should Be True  ${error_expected} == True

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for GET operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} GET ${uri}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for POST operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} POST ${uri} --data=${payload}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for POST operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} PATCH ${uri} --data=${payload}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri  URI for DELETE operation.
    # cmd_args  Commandline arguments.
    # expected_error  Expected error.

    ${cmd_output}=  Run  ${cmd_args} DELETE ${uri}
    Check HTTP error  ${cmd_output}  ${expected_error}
    [Return]  ${cmd_output}

Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}
