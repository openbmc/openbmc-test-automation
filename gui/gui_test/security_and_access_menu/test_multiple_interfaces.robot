*** Settings ***
Documentation   Test BMC multiple network interface functionalities via GUI.

Resource        ../../lib/gui_resource.robot
Resource        ../../../lib/resource.robot
Resource        ../../../lib/certificate_utils.robot

Suite Setup     Suite Setup Execution
Test Teardown   FFDC On Test Case Fail

*** Variables ***

${bmc_url}                     https://${OPENBMC_HOST}
${bmc_url_1}                   https://${OPENBMC_HOST_1}
${LDAP_FILE_PATH}              ${EMPTY}
${CA_FILE_PATH}                ${EMPTY}

${xpath_add_new_certificate}   //*[contains(text(), ' Add new certificate ')]
${xpath_certificate_type}      //*[@id="certificate-type"]
${xpath_upload_file}           //*[@id="certificate-file"]
${xpath_load_certificate}      //button[text()=' Add ']
${xpath_close_poup}            //*[@class="close ml-auto mb-1"]

*** Test Cases ***

Verify BMC GUI Is Accessible Via Both Network Interfaces
    [Documentation]  Verify BMC GUI is accessible via both network interfaces.
    [Tags]  Verify_BMC_GUI_Is_Accessible_Via_Both_Network_Interfaces
    [Teardown]  Close All Browsers

    Start Virtual Display
    ${browser_ID}=  Open Browser  ${bmc_url}  alias=tab1
    Set Window Size  1920  1080
    ${browser_ID}=  Open Browser  ${bmc_url_1}  alias=tab2
    Set Window Size  1920  1080
    Switch Browser  tab1
    Run Keywords  Login GUI  AND  Logout GUI
    Switch Browser  tab2
    Run Keywords  Login GUI  AND  Logout GUI


Load Certificates Via Eth1 IP Address And Verify
    [Documentation]  Verify ability to load LDAP certificate using eth1 IP address.
    [Tags]  Load_Certificates_Via_Eth1_IP_Address_And_Verify
    [Template]  Load Certificates On BMC Via GUI

    # bmc_url     certificate_type  file_path
    ${bmc_url_1}  Client            ${LDAP_FILE_PATH}
    ${bmc_url_1}  CA                ${CA_FILE_PATH}


*** keywords ***

Suite Setup Execution
    [Documentation]  Do suite setup task.

    Valid Value  OPENBMC_HOST_1

    # Check both interfaces are configured and reachable.
    Ping Host  ${OPENBMC_HOST}
    Ping Host  ${OPENBMC_HOST_1}


Load Certificates On BMC Via GUI
    [Documentation]  Load certificate on BMC via GUI.
    [Arguments]  ${bmc_url}  ${certificate_type}  ${file_path}  ${delete_cert}=${True}
    [Teardown]  Run Keywords  Logout GUI  AND  Close Browser

    # Description of argument(s):
    # bmc_url            Openbmc GUI URL to be open.
    # certificate_type   Certificate type.
    #                    (e.g. "LDAP Certificate" or "CA Certificate").
    # file_path          Certificate file path (e.g. "/home/folder/file.pem").

    ${path}  ${ext}=  Split Extension  ${file_path}
    Run Keyword If  '${certificate_type}' == 'CA' and '${delete_cert}' == '${True}'
    ...  Delete All CA Certificate Via Redfish
    ...  ELSE IF  '${certificate_type}' == 'Client' and '${delete_cert}' == '${True}'
    ...  Delete Certificate Via BMC CLI  ${certificate_type}

    Set Test Variable  ${obmc_gui_url}  https://${OPENBMC_HOST_1}
    Launch Browser And Login GUI
    Navigate To SSL Certificate Page
    Sleep  10s
    Click Element  ${xpath_add_new_certificate}

    Wait Until Page Contains Element  ${xpath_certificate_type}  timeout=20s
    Run Keyword If  '${certificate_type}' == 'CA'
    ...  Select From List By Label  ${xpath_certificate_type}  CA Certificate
    ...  ELSE IF  '${certificate_type}' == 'Client'
    ...  Select From List By Label  ${xpath_certificate_type}  LDAP Certificate

    Choose File  ${xpath_upload_file}  ${file_path}
    Click Element  ${xpath_load_certificate}

    Run Keyword If  '${ext}' !='pem'   Wait Until Page Contains  Error adding certificate.

    Run Keyword If  '${certificate_type}' == 'CA'
    ...  Wait Until Page Contains  Successfully added CA Certificate.
    ...  ELSE IF  '${certificate_type}' == 'Client'
    ...  Wait Until Page Contains  Successfully added LDAP Certificate.
    Click Element  ${xpath_close_poup}


Navigate To SSL Certificate Page
    [Documentation]  Navigate to SSL Certificate page.

    Click Element  ${xpath_secuity_and_accesss_menu}
    Click Element  ${xpath_certificates_sub_menu}
    Wait Until Keyword Succeeds  30 sec  10 sec  Location Should Contain  certificates

