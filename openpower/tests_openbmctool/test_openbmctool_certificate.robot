*** Settings ***
Documentation  Verify openbmctool's certificate fuctionality.

Resource                ../../lib/certificate_utils.robot

Suite Setup             Suite Setup Execution


*** Test Cases ***

Verify Server Certificate Replace Via Openbmctool
    [Documentation]  Verify server certificate replace via openbmctool.
    [Tags]  Verify_Server_Certificate_Replace_Via_Openbmctool

    ${cert_file_path}=  Generate Certificate File Via Openssl
    ...  Valid Certificate Valid Privatekey

    ${openbmctool_cmd}=  Catenate  python  ${openbmctool_file_path}
    ...  -H ${OPENBMC_HOST} -U ${OPENBMC_USERNAME} -P ${OPENBMC_PASSWORD}
    ...  certificate replace server https -f  ${cert_file_path}
    ${rc}  ${output}=  Run And Return RC and Output  ${openbmctool_cmd}

    Wait Until Keyword Succeeds  1 mins  15 secs
    ...  Verify Certificate Visible Via OpenSSL  ${cert_file_path}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Verify connectivity to run openbmctool commands.

    Create Directory  certificate_dir

