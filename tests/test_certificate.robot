*** Settings ***

Documentation  Test certificate in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot
Resource       ../lib/certificate_utils.robot

Test Teardown  FFDC On Test Case Fail


*** Test Cases ***

Test Server Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Test Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Server                Valid_Certificate_Valid_Privatekey  ok

Test Server Certificate Install With Empty Certificate And Valid Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Valid_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Empty_Certificate_Valid_Privatekey  error


Test Server Certificate Install With Valid Certificate And Empty Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Empty_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Valid_Certificate_Empty_Privatekey  error


Test Server Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Empty_Certificate_Empty_Privatekey  error


Test Server Certificate Install With Expired Certificate
    [Documentation]  Test server certificate install with expired certificate.
    [Tags]  Test_Server_Certificate_Install_With_Expired_Certificate
    [Template]  Test Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Server                Expired_Certificate                 error


Test Client Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test client certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Test_Client_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Test Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Client                Valid_Certificate_Valid_Privatekey  ok


Test Client Certificate Install With Empty Certificate And Valid Private Key
    [Documentation]  Test client certificate install with empty certificate
    ...  and valid private key.
    [Tags]  Test_Client_Certificate_Install_With_Empty_Certificate_And_Valid_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Empty_Certificate_Valid_Privatekey  error


Test Client Certificate Install With Valid Certificate And Empty Private Key
    [Documentation]  Test client certificate install with valid certificate
    ...  and empty private key.
    [Tags]  Test_Client_Certificate_Install_With_Valid_Certificate_And_Empty_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Valid_Certificate_Empty_Privatekey  error


Test Client Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test client certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Client_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Client                Empty_Certificate_Empty_Privatekey  error


Test Client Certificate Install With Expired Certificate
    [Documentation]  Test client certificate install with expired certificate.
    [Tags]  Test_Client_Certificate_Install_With_Expired_Certificate
    [Template]  Test Certificate Install Via REST
    # Certificate type    Certificate file format             Expected Status
    Client                Expired_Certificate                 error


Test Delete Server Certificate
    [Documentation]  Delete server certificate and verify.
    [Tags]  Test_Delete_Server_Certificate

    ${cert_file_path}=  Create Certificate File Via Openssl
    ...  Valid_Certificate_Valid_Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}
    ...  data=${file_data}

    OpenBMC Delete Request  ${SERVER_CERTIFICATE_URI}
    # Adding delay after certificate deletion
    Sleep  10s

    ${bmc_cert_content}=  Get Certificate Content Via Openssl
    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Test Delete Client Certificate
    [Documentation]  Delete client certificate and verify.
    [Tags]  Test_Delete_Client_Certificate

    ${cert_file_path}=  Create Certificate File Via Openssl
    ...  Valid_Certificate_Valid_Privatekey
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}
    ...  data=${file_data}

    OpenBMC Delete Request  ${CLIENT_CERTIFICATE_URI}
    # Adding delay after certificate deletion
    Sleep  10s

    ${bmc_cert_content}=  Get Client Certificate Content Via BMC
    Should Not Contain  ${cert_file_content}  ${bmc_cert_content}


Test Continuous Server Certificate Install
    [Documentation]  Stress server certificate installtion.
    [Tags]  Test_Continuous_Server_Certificate_Install

    Repeat Keyword  2 times  Test Certificate Install Via REST
    ...  Server  Valid_Certificate_Valid_Privatekey  ok

Test Continuous Client Certificate Install
    [Documentation]  Stress client certificate installtion.
    [Tags]  Test_Continuous_Client_Certificate_Install

    Repeat Keyword  2 times  Test Certificate Install Via REST
    ...  Client  Valid_Certificate_Valid_Privatekey  ok


***Keywords***

Test Certificate Install Via REST
    [Documentation]  Test certificate install in the BMC via REST.
    [Arguments]  ${cert_type}  ${cert_format}  ${expected_status}

    # Description of argument(s):
    # cert_type           Certificate type (e.g. "Server" or "Client").
    # cert_format         Certificate file format
    #                     (e.g. Valid_Certificate_Valid_Privatekey).
    # expected_status     Expected status of certificate installation REST
    #                     request(i.e. "ok" or "error").

    ${cert_file_path}=  Run Keyword if  '${cert_format}' == 'Expired_Certificate'
    ...  Create Certificate File Via Openssl  ${cert_format}  -10
    ...  ELSE  Create Certificate File Via Openssl  ${cert_format}

    #${cert_file_path}=  Create Certificate File Via Openssl  ${cert_format}
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    Run Keyword If  '${cert_type}' == 'Server'
    ...    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}

    # Adding delay after certificate installation
    sleep  5s
    ${cert_file_content}=  OperatingSystem.Get File  ${cert_file_path}

    ${bmc_cert_content}=  Run Keyword If  '${cert_type}' == 'Server'
    ...    Get Certificate Content Via Openssl
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...    Get Client Certificate Content Via BMC

    Run Keyword if  '${expected_status}' == 'ok'
    ...  Should Contain  ${cert_file_content}  ${bmc_cert_content}
    ...  ELSE IF  '${expected_status}' == 'error'
    ...  Should Not Contain  ${cert_file_content}  ${bmc_cert_content}
