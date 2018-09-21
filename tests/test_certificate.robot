*** Settings ***

Documentation  Test certificate in OpenBMC.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot
Resource       ../lib/certificate_utils.robot

#Test Teardown  FFDC On Test Case Fail


*** Test Cases ***

Test Server Certificate Install With Valid Certificate And Valid Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Valid_Private_Key
    [Template]  Install Certificate Via REST
    # Certificate type    Certificate file path               Status
    Server               Valid_Certificate_Valid_Privatekey   Installed

Test Server Certificate Install With Empty Certificate And Valid Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and valid private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Valid_Private_Key
    [Template]  Install Certificate Via REST

    # Certificate type    Certificate file path               Expected Status
    Server                Empty_Certificate_Valid_Privatekey  Not Installed


Test Server Certificate Install With Valid Certificate And Empty Private Key
    [Documentation]  Test server certificate install with valid certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Valid_Certificate_And_Empty_Private_Key
    [Template]  Install Certificate Via REST

    # Certificate type    Certificate file path               Expected Status
    Server                Valid_Certificate_Empty_Privatekey  Not Installed


Test Server Certificate Install With Empty Certificate And Empty Private Key
    [Documentation]  Test server certificate install with empty certificate
    ...  and empty private key.
    [Tags]  Test_Server_Certificate_Install_With_Empty_Certificate_And_Empty_Private_Key
    [Template]  Install Certificate Via REST

    # Certificate type    Certificate file path               Expected Status
    Server                Empty_Certificate_Empty_Privatekey  Not Installed


***Keywords***

Install Certificate Via REST
    [Documentation]  Install given certificate in the BMC via REST.
    [Arguments]  ${certificate_type}  ${certificate_format}  ${status}

    # Description of argument(s):
    # certificate_type       Certificate type(e.g Server or Client).
    # certificate_file_path  Downloaded certificate file path.
    # status                 Expected status of certificate installation.

    ${certificate_file_path}=  Create Certificate File Via Openssl  ${certificate_format}
    ${file_data}=  OperatingSystem.Get Binary File  ${certificate_file_path}

    Run Keyword If  '${certificate_type}' == 'Server' and '${status}' == 'Installed'
    ...    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}  ok  ${0}
    ...    data=${file_data}
    ...  ELSE IF  '${certificate_type}' == 'Server' and '${status}' == 'Not Installed'
    ...    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}  error  ${0}
    ...    data=${file_data}
    ...  ELSE IF  '${certificate_type}' == 'Client' and '${status}' == 'Installed'
    ...    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}  ok  ${0}
    ...    data=${file_data}
    ...  ELSE IF  '${certificate_type}' == 'Client' and '${status}' == 'Not Installed'
    ...    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}  error  ${0}
    ...    data=${file_data}

    sleep  10s
    ${certificate_content}=  Get Certificate Content From File
    ...  ${certificate_file_path}
    ${certificate_content_openssl}=  Get Certificate Content Via Openssl

    Log to console  certificatefile--------${certificate_content}

    Log to console  certificate_openssl-------${certificate_content_openssl}

    Run Keyword if  '${status}' == 'Installed'
    ...  Should Be Equal  ${certificate_content_openssl}  ${certificate_content}
    ...  ELSE IF  '${status}' == 'Not Installed'
    ...  Should Not Be Equal  ${certificate_content_openssl}  ${certificate_content}
