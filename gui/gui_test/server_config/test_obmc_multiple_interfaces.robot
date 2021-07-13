*** Settings ***
Documentation   Test BMC multiple network interface functionalities via GUI.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/resource.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${bmc_url_1}           https://${OPENBMC_HOST_1}
${LDAP_FILE_PATH}      ${EMPTY}
${CA_FILE_PATH}        ${EMPTY}

${xpath_add_newcertificate}    //*[contains(text(), ' Add new certificate ')]
${xpath_certificate_type}      //*[@id="certificate-type"]
${xpath_upload_file}           //*[@id="certificate-file"]
${xpath_load_certificate}      //button[text()=' Add ']
${xpath_close_poup}            //*[@class="close ml-auto mb-1"]

*** Test Cases ***

Verify Able To Load Certificates Via Eth1 IP Address
    [Documentation]  Verify able load LDAP certificate using eth1 IP address.
    [Tags]  Verify_Able_To_Load_Certificates_Via_Eth1_IP_Address
    [Template]  Load Certificates On BMC Via GUI

    # bmc_url     certificate_type  file_path
    ${bmc_url_1}  LDAP Certificate  ${LDAP_FILE_PATH}
    ${bmc_url_1}  CA Certificate    ${CA_FILE_PATH}


*** keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}


Load Certificates On BMC Via GUI
    [Documentation]  Load certificate on BMC via GUI.
    [Arguments]  ${bmc_url}  ${certificate_type}  ${file_path}
    [Teardown]  Run Keywords  Logout GUI  AND  Close Browser

    # Description of argument(s):
    # bmc_url            Openbmc GUI URL to be open.
    # certificate_type   Certificate type.
    #                    (e.g. "LDAP Certificate" or "CA Certificate").
    # file_path          Certificate file path (e.g. "/home/folder/file.pem").

    ${path}  ${ext}=  Split Extension  ${file_path}
    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=tab1
    Login GUI
    Click Element  ${xpath_access_control_menu}
    Click Element  ${xpath_ssl_certificates_sub_menu}
    Page Should Contain  SSL certificates
    Sleep  5s
    Click Element  ${xpath_add_newcertificate}
    Select From List By Value  ${xpath_certificate_type}  ${certificate_type}
    Choose File  ${xpath_upload_file}  ${file_path}
    Click Element  ${xpath_load_certificate}

    Run Keyword If  '${ext}' !='pem'   Wait Until Page Contains  Error adding certificate
    ...  ELSE  Wait Until Page Contains  Successfully added ${certificate_type}.
    ...  msg=Please upload valid certificate.
    Click Element  ${xpath_close_poup}
