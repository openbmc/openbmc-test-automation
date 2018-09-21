*** Settings ***

Documentation  Test certificate in OpenBMC.
# Program arguments:
# VALID_CERTIFICATE_FILE_PATH    Directory path of the downloaded certificates.

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/openbmc_ffdc.robot
Resource       ../lib/certificate_utils.robot

Test Teardown  FFDC On Test Case Fail


*** Test Cases ***

Test Valid Server Certificate Install
    [Documentation]  Install a valid server certificate file via REST.
    [Tags]  Test_Valid_Server_Certificate_Install
    [Setup]  OperatingSystem.File Should Exist  ${VALID_CERTIFICATE_FILE_PATH}
    [Template]  Install Certificate Via REST

    # Certificate type    Certificate file path
    Server                ${VALID_CERTIFICATE_FILE_PATH}


***Keywords***

Install Certificate Via REST
    [Documentation]  Install given certificate in the BMC via REST.
    [Arguments]  ${certificate_type}  ${certificate_file_path}

    # Description of argument(s):
    # certificate_type       Certificate type(e.g Server or Client).
    # certificate_file_path  Downloaded certificate file path.

    ${file_data}=  OperatingSystem.Get Binary File  ${certificate_file_path}
    Run Keyword If  '${certificate_type}' == 'Server'
    ...    Install Certificate File In BMC  ${SERVER_CERTIFICATE_URI}
    ...    data=${file_data}
    ...  ELSE
    ...    Install Certificate File In BMC  ${CLIENT_CERTIFICATE_URI}
    ...    data=${file_data}

