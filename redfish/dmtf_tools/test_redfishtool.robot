*** Settings ***


Documentation     Verify Redfish tool functionality.

Library           OperatingSystem
Library           String
Library           Collections

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/certificate_utils.robot


Suite Setup       Suite Setup Execution


*** Variables ***


${root_cmd_args} =  SEPARATOR=
...  redfishtool raw -r ${OPENBMC_HOST} -u ${OPENBMC_USERNAME} -p ${OPENBMC_PASSWORD} -S Always
${min_number_sensors}  ${15}
${min_number_roles}    ${4}
${min_number_users}    ${1}


*** Test Cases ***


Verify Redfishtool Sensor Commands
    [Documentation]  Verify redfishtool's sensor commands.
    [Tags]  Verify_Redfishtool_Sensor_Commands

    ${sensor_status}=  Redfishtool Get  /redfish/v1/Chassis/chassis/Sensors
    ${json_object}=  Evaluate  json.loads('''${sensor_status}''')  json
    Should Be True  ${json_object["Members@odata.count"]} > ${min_number_sensors}
    ...  msg=There should be at least ${min_number_sensors} sensors.


Verify Redfishtool Health Check Commands
    [Documentation]  Verify redfishtool's health check command.
    [Tags]  Verify_Redfishtool_Health_Check_Commands

    ${chassis_data}=  Redfishtool Get  /redfish/v1/Chassis/chassis/
    ${json_object}=  Evaluate  json.loads('''${chassis_data}''')  json
    ${status}=  Set Variable  ${json_object["Status"]}
    Should Be Equal  OK  ${status["Health"]}
    ...  msg=Health status should be OK.


Verify Redfishtool Create Users
    [Documentation]  Create user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Create_Users
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Verify User  "UserT100"  "Operator"


Verify Redfishtool Modify Users
    [Documentation]  Modify user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Modify_Users
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Update User Role  "UserT100"  "Administrator"
    Redfishtool Verify User  "UserT100"  "Administrator"


Verify Redfishtool Delete Users
    [Documentation]  Delete user via Redfishtool and verify.
    [Tags]  Verify_Redfishtool_Delete_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    ${status}=  Redfishtool Verify User Name Exists  "UserT100"
    Should Be True  ${status} == False


Verify Redfishtool Login With Deleted Redfish Users
    [Documentation]  Verify login with deleted user via Redfishtool.
    [Tags]  Verify_Redfishtool_Login_With_Deleted_Redfish_Users

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Delete User  "UserT100"
    Redfishtool Access Resource  /redfish/v1/AccountService/Accounts  "UserT100"  "TestPwd123"
    ...  ${HTTP_UNAUTHORIZED}


Verify Redfishtool Error Upon Creating Same Users With Different Privileges
    [Documentation]  Verify error upon creating same users with different privileges.
    [Tags]  Verify_Redfishtool_Error_Upon_Creating_Same_Users_With_Different_Privileges
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Operator"  true
    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true
    ...  expected_error=${HTTP_BAD_REQUEST}


Verify Redfishtool Admin User Privilege
    [Documentation]  Verify privilege of admin user.
    [Tags]  Verify_Redfishtool_Admin_User_Privilege
    [Teardown]  Run Keywords  Redfishtool Delete User  "UserT100"  AND
    ...  Redfishtool Delete User  "UserT101"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "Administrator"  true

    # Verify if an user can be added by admin
    Redfishtool Create User  "UserT101"  "TestPwd123"  "Operator"  true  "UserT100"  "TestPwd123"


Verify Redfishtool ReadOnly User Privilege
    [Documentation]  Verify Redfishtool ReadOnly user privilege works.
    [Tags]  Verify_Redfishtool_ReadOnly_User_Privilege
    [Teardown]  Redfishtool Delete User  "UserT100"

    Redfishtool Create User  "UserT100"  "TestPwd123"  "ReadOnly"  true
    Redfishtool Access Resource  /redfish/v1/Systems/  "UserT100"  "TestPwd123"

    Redfishtool Create User
    ...  "UserT101"  "TestPwd123"  "Operator"  true  "UserT100"  "TestPwd123"  ${HTTP_FORBIDDEN}


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


Verify Redfishtool Replace Server Certificate Invalid CertKey
    [Documentation]  Verify replace server certificate.
    [Tags]  Verify_Redfishtool_Replace_Server_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Server  Empty Certificate Empty Privatekey  error


Verify Redfishtool Replace Server Certificate Invalid Cert
    [Documentation]  Verify replace server certificate.
    [Tags]  Verify_Redfishtool_Replace_Server_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Server  Empty Certificate Valid Privatekey  error


Verify Redfishtool Replace Server Certificate Invalid Key
    [Documentation]  Verify replace server certificate.
    [Tags]  Verify_Redfishtool_Replace_Server_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Server  Valid Certificate Empty Privatekey  error


Verify Redfishtool Replace Client Certificate Invalid CertKey
    [Documentation]  Verify replace client certificate.
    [Tags]  Verify_Redfishtool_Replace_Client_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Client  Empty Certificate Empty Privatekey  error


Verify Redfishtool Replace Client Certificate Invalid Cert
    [Documentation]  Verify replace client certificate.
    [Tags]  Verify_Redfishtool_Replace_Client_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Client  Empty Certificate Valid Privatekey  error


Verify Redfishtool Replace Client Certificate Invalid Key
    [Documentation]  Verify replace client certificate.
    [Tags]  Verify_Redfishtool_Replace_Client_Certificate_Valid_CertKey

    Verify Redfishtool Replace Certificate  Client  Valid Certificate Empty Privatekey  error


Verify Redfishtool Replace CA Certificate Invalid Cert
    [Documentation]  Verify replace CA certificate.
    [Tags]  Verify_Redfishtool_Replace_CA_Certificate_Valid_Cert

    Verify Redfishtool Replace Certificate  CA  Empty Certificate  error


Verify Redfishtool Client Certificate Install Invalid CertKey
    [Documentation]  Verify client certificate installation.
    [Tags]  Verify_Redfishtool_Client_Certificate_Install_Valid_CertKey

    Verify Redfishtool Install Certificate  Client  Empty Certificate Empty Privatekey  error


Verify Redfishtool Client Certificate Install Invalid Cert
    [Documentation]  Verify client certificate installation.
    [Tags]  Verify_Redfishtool_Client_Certificate_Install_Valid_CertKey

    Verify Redfishtool Install Certificate  Client  Empty Certificate Valid Privatekey  error


Verify Redfishtool Client Certificate Install Invalid Key
    [Documentation]  Verify client certificate installation.
    [Tags]  Verify_Redfishtool_Client_Certificate_Install_Valid_CertKey

    Verify Redfishtool Install Certificate  Client  Valid Certificate Empty Privatekey  error


*** Keywords ***


Redfishtool Access Resource
    [Documentation]  Access resource.
    [Arguments]  ${uri}   ${login_user}  ${login_pasword}  ${expected_error}=""

    # Description of argument(s):
    # uri            URI for resource access.
    # login_user     The login user name used other than default root user.
    # login_pasword  The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    Redfishtool Get  ${uri}  ${user_cmd_args}  ${expected_error}


Is HTTP error Expected
    [Documentation]  Check if the HTTP error is expected.
    [Arguments]  ${cmd_output}  ${error_expected}

    # Description of argument(s):
    # cmd_output      Output of an HTTP operation.
    # error_expected  Expected error.

    @{words} =  Split String    ${error_expected}       ,
    @{errorString}=  Split String    ${cmd_output}       ${SPACE}
    Should Contain Any  ${errorString}  @{words}


Redfishtool Create User
    [Documentation]  Create new user.
    [Arguments]  ${user_name}  ${password}  ${roleID}  ${enable}  ${login_user}=""  ${login_pasword}=""
    ...  ${expected_error}=""

    # Description of argument(s):
    # user_name      The user name (e.g. "test", "robert", etc.).
    # password       The user password (e.g. "0penBmc", "0penBmc1", etc.).
    # roleID         The role of user (e.g. "Administrator", "Operator", etc.).
    # enable         Enabled attribute of (e.g. true or false).
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    ${data}=  Set Variable
    ...  '{"UserName":${user_name},"Password":${password},"RoleId":${roleId},"Enabled":${enable}}'
    Run Keyword If  ${login_user} == ""
    ...   Redfishtool Post  ${data}  /redfish/v1/AccountService/Accounts  ${root_cmd_args}  ${expected_error}
    ...   ELSE
    ...   Redfishtool Post  ${data}  /redfish/v1/AccountService/Accounts  ${user_cmd_args}  ${expected_error}


Redfishtool Update User Role
    [Documentation]  Update user role.
    [Arguments]  ${user_name}  ${newRole}  ${login_user}=""  ${login_pasword}=""
    ...  ${expected_error}=""

    # Description of argument(s):
    # user_name      The user name (e.g. "test", "robert", etc.).
    # newRole        The new role of user (e.g. "Administrator", "Operator", etc.).
    # login_user     The login user name used other than default root user.
    # login_pasword  The login password.
    # expected_error Expected error optionally provided in testcase (e.g. 401 /
    #                authentication error, etc. )

    ${user_cmd_args}=  Set Variable
    ...  redfishtool raw -r ${OPENBMC_HOST} -u ${login_user} -p ${login_pasword} -S Always
    Run Keyword If  ${login_user} == ""
    ...   Redfishtool Patch  '{"RoleId":${newRole}}'
          ...  /redfish/v1/AccountService/Accounts/${user_name}  ${root_cmd_args}  ${expected_error}
    ...   ELSE
    ...   Redfishtool Patch  '{"RoleId":${newRole}}'
          ...  /redfish/v1/AccountService/Accounts/${user_name}  ${user_cmd_args}  ${expected_error}


Redfishtool Delete User
    [Documentation]  Delete an user.
    [Arguments]  ${user_name}  ${expected_error}=""

    # Description of argument(s):
    # user_name       The user name (e.g. "test", "robert", etc.).
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    Redfishtool Delete  /redfish/v1/AccountService/Accounts/${user_name}
    ...  ${root_cmd_args}  ${expected_error}


Redfishtool Verify User
    [Documentation]  Verify role of the user.
    [Arguments]  ${user_name}  ${role}

    # Description of argument(s):
    # user_name  The user name (e.g. "test", "robert", etc.).
    # role       The new role of user (e.g. "Administrator", "Operator", etc.).

    ${user_account}=  Redfishtool Get  /redfish/v1/AccountService/Accounts/${user_name}
    ${json_obj}=   Evaluate  json.loads('''${user_account}''')  json
    Should Be equal  "${json_obj["RoleId"]}"  ${role}


Redfishtool Verify User Name Exists
    [Documentation]  Verify user name exists.
    [Arguments]  ${user_name}

    # Description of argument(s):
    # user_name  The user name (e.g. "test", "robert", etc.).

    ${status}=  Run Keyword And Return Status  redfishtool Get
    ...  /redfish/v1/AccountService/Accounts/${user_name}

    [return]  ${status}


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

    ${cert_id}=  Redfishtool Install Certificate File On BMC  ${certificate_uri}  ${expected_status}  data=${file_data}
    Logging  Installed certificate id: ${cert_id}

    # Adding delay after certificate installation.
    Sleep  30s

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${bmc_cert_content}=  Run Keyword If  '${expected_status}' == 'ok'  Redfishtool GetAttribute  ${certificate_uri}/${cert_id}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'  Should Contain  ${cert_file_content}  ${bmc_cert_content}

    [Return]  ${cert_id}


Delete All CA Certificate Via Redfisthtool
    [Documentation]  Delete all CA certificate via Redfish.

    ${cmd_output}=  Redfishtool Get  /redfish/v1/Managers/bmc/Truststore/Certificates
    ${json_object}=  To JSON  ${cmd_output}
    ${cert_list}=  Set Variable  ${json_object["Members"]}
    FOR  ${cert}  IN  @{cert_list}
      Redfishtool Delete  ${cert["@odata.id"]}  ${root_cmd_args}  ${HTTP_NO_CONTENT}
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

    #Create Directory  certificate_dir
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
    ...  '${expected_status}' == 'error'  ${HTTP_NOT_FOUND}, ${HTTP_INTERNAL_SERVER_ERROR}
    ${response}=  Redfishtool Post
    ...  ${payload}  /redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate  expected_error=${expected_resp}

    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    ${bmc_cert_content}=  Redfishtool GetAttribute  ${certificate_uri}  CertificateString

    Run Keyword If  '${expected_status}' == 'ok'
    ...    Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE
    ...    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Redfishtool Get
    [Documentation]  Execute redfishtool for GET operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri             URI for GET operation (e.g. /redfish/v1/AccountService/Accounts/).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} GET ${uri}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


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


Redfishtool Patch
    [Documentation]  Execute redfishtool for  Patch operation.
    [Arguments]  ${payload}  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # payload         Payload with POST operation (e.g. data for user name, role, etc. ).
    # uri             URI for PATCH operation (e.g. /redfish/v1/AccountService/Accounts/ ).
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} PATCH ${uri} --data=${payload}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Redfishtool Delete
    [Documentation]  Execute redfishtool for  Post operation.
    [Arguments]  ${uri}  ${cmd_args}=${root_cmd_args}  ${expected_error}=""

    # Description of argument(s):
    # uri             URI for DELETE operation.
    # cmd_args        Commandline arguments.
    # expected_error  Expected error optionally provided in testcase (e.g. 401 /
    #                 authentication error, etc. ).

    ${rc}  ${cmd_output}=  Run and Return RC and Output  ${cmd_args} DELETE ${uri}
    Run Keyword If  ${rc} != 0  Is HTTP error Expected  ${cmd_output}  ${expected_error}

    [Return]  ${cmd_output}


Suite Setup Execution
    [Documentation]  Do suite setup execution.

    ${tool_exist}=  Run  which redfishtool
    Should Not Be Empty  ${tool_exist}

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
