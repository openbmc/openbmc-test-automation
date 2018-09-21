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
    Server                Valid_Certificate_Empty_Privatekey  Not Installed


Test Server Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Test Certificate Install Via REST

    # Certificate type    Certificate file format             Expected Status
    Server                Empty_Certificate_Empty_Privatekey  Not Installed


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

    ${cert_file_path}=  Create Certificate File Via Openssl  ${cert_format}
    ${file_data}=  OperatingSystem.Get Binary File  ${cert_file_path}

    Run Keyword If  '${cert_type}' == 'Server'
    ...    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}
    ...  ELSE IF  '${cert_type}' == 'Client'
    ...    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}
    ...    ${expected_status}  ${1}  data=${file_data}

    sleep  5s
    ${cert_file_content}=  Get Certificate Content From File
    ...  ${cert_file_path}
    ${openssl_cert_content}=  Get Certificate Content Via Openssl

    Run Keyword if  '${expected_status}' == 'ok'
    ...  Should Be Equal  ${openssl_cert_content}  ${cert_file_content}
    ...  ELSE IF  '${expected_status}' == 'error'
    ...  Should Not Be Equal  ${openssl_cert_content}  ${cert_file_content}
