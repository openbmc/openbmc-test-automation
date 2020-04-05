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

${cmd_prefix}          redfishtool raw
${root_cmd_args}       -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always --status

*** Test Cases ***

Verify Redfishtool Replace Server Certificate valid cert format 
    [Documentation]  Verify replace server certificate

    ${response}=  Verify Redfishtool Replace Certificate  Valid Certificate Valid Privatekey  Server 
    ${RETN_CODE_OK}=  Redfishtool Check HTTP Return OK  ${response}
    Should Be True  ${RETN_CODE_OK} == True
    ...  msg=${response}

Verify Redfishtool Replace CA Certificate valid cert format
    [Documentation]  Verify replace server certificate

    ${response}=  Verify Redfishtool Replace Certificate  Valid Certificate Valid Privatekey  CA
    ${RETN_CODE_OK}=  Redfishtool Check HTTP Return OK  ${response}
    Should Be True  ${RETN_CODE_OK} == True
    ...  msg=${response}

Verify Redfishtool Replace Client Certificate valid cert format
    [Documentation]  Verify replace server certificate

    ${response}=  Verify Redfishtool Replace Certificate  Valid Certificate Valid Privatekey  Client 
    ${RETN_CODE_OK}=  Redfishtool Check HTTP Return OK  ${response}
    Should Be True  ${RETN_CODE_OK} == True
    ...  msg=${response}

*** Keywords ***

Verify Redfishtool Replace certificate
    [Documentation]  Verify replace server certificate
    [Arguments]   ${cert_format}  ${cert_type}

    Create Directory  certificate_dir
    # Install certificate before replacing client or CA certificate.
    ${cert_id}=  Run Keyword If  '${cert_type}' == 'Client'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate Valid Privatekey
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Install And Verify Certificate Via Redfish  ${cert_type}  Valid Certificate

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
 
Redfishtool Handle Error
    [Documentation]  Handle error.
    [Arguments]  ${cmd_output}  ${error_expected}

    ${contains}=  Evaluate   "${error_expected}" in """${cmd_output}"""
    Should Be True  ${contains}
    ...  msg=${cmd_output}

Redfishtool Get
    [Documentation]  Execute DMTF redfishtool for  GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for GET operation.

    ${cmd_output}=  Run  ${cmd_prefix} GET ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Post
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} POST ${uri} --data=${payload} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Patch
    [Documentation]  Execute DMTF redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for POST operation.

    ${cmd_output}=  Run  ${cmd_prefix} PATCH ${uri} --data=${payload} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Delete
    [Documentation]  Execute DMTF redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}

    # Description of argument(s):
    # uri  URI for DELETE operation.

    ${cmd_output}=  Run  ${cmd_prefix} DELETE ${uri} ${cmd_args}
    [Return]  ${cmd_output}

Redfishtool Check HTTP Return OK 
    [Documentation]
    [Arguments]  ${response}

    ${contains}=  Evaluate   "status_code: 200" in """${response}"""
    [return]  ${contains}

Suite Setup Execution
    [Documentation]  Do suite setup execution.
    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}

    Create Directory  certificate_dir

