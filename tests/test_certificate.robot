*** Settings ***

Documentation  Test certificate in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot
Resource       ../lib/certificate_utils.robot

Suite Setup    Suite Setup Execution
Test Teardown  Test Teardown Execution

Force Tags     Certificate_Test


*** Test Cases ***

Test Server Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Server                Valid Certificate Valid Privatekey  ok


Test Server Certificate Install With Empty Certificate And Valid Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Valid_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Empty Certificate Valid Privatekey  error


Test Server Certificate Install With Valid Certificate And Empty Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Empty_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Valid Certificate Empty Privatekey  error


Test Server Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Empty Certificate Empty Privatekey  error


Test Server Certificate Install With Expired Certificate
    [Documentation]  Test server certificate install with expired certificate.
    [Tags]  Test_Server_Certificate_Install_With_Expired_Certificate
    [Template]  Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Server                Expired Certificate                 error


Test Client Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test client certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Test_Client_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Client                Valid Certificate Valid Privatekey  ok


Test Client Certificate Install With Empty Certificate And Valid Private Key
    [Documentation]  Test client certificate install with empty certificate
    ...  and valid private key.
    [Tags]  Test_Client_Certificate_Install_With_Empty_Certificate_And_Valid_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Empty Certificate Valid Privatekey  error


Test Client Certificate Install With Valid Certificate And Empty Private Key
    [Documentation]  Test client certificate install with valid certificate
    ...  and empty private key.
    [Tags]  Test_Client_Certificate_Install_With_Valid_Certificate_And_Empty_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Valid Certificate Empty Privatekey  error


Test Client Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test client certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Client_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Empty Certificate Empty Privatekey  error


Test Client Certificate Install With Expired Certificate
    [Documentation]  Test client certificate install with expired certificate.
    [Tags]  Test_Client_Certificate_Install_With_Expired_Certificate
    [Template]  Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Client                Expired Certificate                 error


Test CA Certificate Install With Valid Certificate
    [Documentation]  Test CA certificate install with valid certificate.
    [Tags]  Test_CA_Certificate_Install_With_Valid_Certificate
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    CA                    Valid Certificate                   ok


Test CA Certificate Install With Empty Certificate
    [Documentation]  Test CA certificate install with empty certificate.
    [Tags]  Test_CA_Certificate_Install_With_Empty_Certificate
    [Template]  Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    CA                    Empty Certificate                   error


Test Delete Server Certificate
    [Documentation]  Delete server certificate and verify.
    [Tags]  Test_Delete_Server_Certificate

    ${cert_file_path}=  Generate Certificate File Via Openssl
    ...  Valid Certificate Valid Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File On BMC  ${SERVER_CERTIFICATE_URI}
    ...  data=${file_data}

    OpenBMC Delete Request  ${SERVER_CERTIFICATE_URI}
    # Adding delay after certificate deletion
    Sleep  30s

    ${bmc_cert_content}=  Get Certificate Content From BMC Via Openssl
    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Test Delete Client Certificate
    [Documentation]  Delete client certificate and verify.
    [Tags]  Test_Delete_Client_Certificate

    ${cert_file_path}=  Generate Certificate File Via Openssl
    ...  Valid Certificate Valid Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File On BMC  ${CLIENT_CERTIFICATE_URI}
    ...  data=${file_data}

    OpenBMC Delete Request  ${CLIENT_CERTIFICATE_URI}
    # Adding delay after certificate deletion
    Sleep  30s

    ${msg}=  Run Keyword And Expect Error  *
    ...  Get Certificate File Content From BMC  Client

    Should Contain  ${msg}  No such file or directory  ignore_case=True


Test Delete CA Certificate
    [Documentation]  Delete CA certificate and verify.
    [Tags]  Test_CA_Certificate

    ${cert_file_path}=  Generate Certificate File Via Openssl
    ...  Valid Certificate
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File On BMC  ${CA_CERTIFICATE_URI}
    ...  data=${file_data}

    OpenBMC Delete Request  ${CA_CERTIFICATE_URI}
    # Adding delay after certificate deletion.
    Sleep  30s

    ${msg}=  Run Keyword And Expect Error  *
    ...  Get Certificate File Content From BMC  CA

    Should Contain  ${msg}  No such file or directory  ignore_case=True



Test Continuous Server Certificate Install
    [Documentation]  Stress server certificate installtion.
    [Tags]  Test_Continuous_Server_Certificate_Install

    Repeat Keyword  3 times  Certificate Install Via REST
    ...  Server  Valid Certificate Valid Privatekey  ok


Test Continuous Client Certificate Install
    [Documentation]  Stress client certificate installtion.
    [Tags]  Test_Continuous_Client_Certificate_Install

    Repeat Keyword  3 times  Certificate Install Via REST
    ...  Client  Valid Certificate Valid Privatekey  ok


***Keywords***

Certificate Install Via REST
    [Documentation]  Test certificate install in the BMC via REST.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate installation REST
    #                     request(i.e. "ok" or "error").

    ${cert_file_path}=  Run Keyword if  '${cert_format}' == 'Expired Certificate'
    ...  Generate Certificate File Via Openssl  ${cert_format}  -10
    ...  ELSE  Generate Certificate File Via Openssl  ${cert_format}

    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    Run Keyword If  '${cert_type}' == 'Server'
    ...    Install Certificate File On BMC  ${SERVER_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...    Install Certificate File On BMC  ${CLIENT_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Install Certificate File On BMC  ${CA_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}

    # Adding delay after certificate installation.
    sleep  10s
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}
    Should Not Be Empty  ${cert_file_content}

    ${bmc_cert_content}=  Run Keyword If  '${cert_type}' == 'Server'
    ...    Get Certificate Content From BMC Via Openssl
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...    Get Certificate File Content From BMC  Client
    ...  ELSE IF  '${cert_type}' == 'CA'
    ...    Get Certificate File Content From BMC  CA

    Run Keyword if  '${expected_status}' == 'ok'
    ...  Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE IF  '${expected_status}' == 'error'
    ...  Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Suite Setup Execution
    [Documentation]  Do suite setup tasks.

    # Create certificate sub-directory in current working directory.
    Create Directory  certificate_dir
    OperatingSystem.Directory Should Exist  ${EXECDIR}${/}certificate_dir


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Empty Directory  ${EXECDIR}${/}certificate_dir
    FFDC On Test Case Fail
