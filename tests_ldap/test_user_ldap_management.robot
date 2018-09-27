*** Settings ***
Documentation   OpenBMC LDAP user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot

Suite Setup      Suite Setup Execution
Test Teardown    FFDC On Test Case Fail

*** Variables ****

*** Test Cases ***

Verify LDAP Client Service Is Running And API Available
    [Documentation]  Verify LDAP client service is running and API available.
    [Tags]  Verify_LDAP_Client_Service_Is_Running_And_API_Available

    Check LDAP Service Running
    ${resp}=  Read Properties  ${BMC_LDAP_URI}
    Should Not Be Empty  ${resp}


Verify LDAP Config Is Created
    [Documentation]  Verify LDAP config is created in BMC.
    [Tags]  Verify_LDAP_Config_Is_Created

    Configure LDAP Server On BMC
    Check LDAP Config File Generated


Verify LDAP Config Is Deleted
    [Documentation]  Verify LDAP config is deleted in BMC.
    [Tags]  Verify_LDAP_Config_Is_Deleted

    Delete LDAP Config
    Check LDAP Config File Deleted


*** Keywords ***

Suite Setup Execution
    [Documentation]  Check for LDAP test readiness.

    Run Keyword And Continue On Failure
    ...  Should Not Be Empty  ${LDAP_SECURE_MODE}
    # Set Secure mode as false if value is not set
    ${LDAP_SECURE_MODE}=  Set Variable False
    Should Not Be Empty  ${LDAP_SERVER_URI}
    Should Not Be Empty  ${LDAP_BIND_DN}
    Should Not Be Empty  ${LDAP_BASE_DN}
    Should Not Be Empty  ${LDAP_BIND_DN_PASSWORD}
    Should Not Be Empty  ${LDAP_SEARCH_SCOPE}
    Should Not Be Empty  ${LDAP_SERVER_TYPE}
    Check LDAP Service Running

Check LDAP Service Running
    [Documentation]  Check LDAP service running in BMC.

    BMC Execute Command  systemctl | grep -in ldap

Configure LDAP Server On BMC
    [Documentation]  Configure LDAP server on BMC.

    @{ldap_parm_list}=  Create List  xyz.openbmc_project.User.Ldap.Create
    ...  ${LDAP_SECURE_MODE}  ${LDAP_SERVER_URI}  ${LDAP_BIND_DN}
    ...  ${LDAP_BASE_DN}  ${LDAP_BIND_DN_PASSWORD}  ${LDAP_SEARCH_SCOPE}
    ...  ${LDAP_SERVER_TYPE}

    ${data}=  Create Dictionary  data=@{ldap_parm_list}

    ${resp}=  OpenBMC Post Request
    ...  ${BMC_LDAP_URI}/action/CreateConfig  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Check LDAP Config File Generated
    [Documentation]  Check LDAP file nslcd.conf generated.
    [Arguments]  ${ldap_server}=${LDAP_SERVER_URI}

    ${ldap_server_config}  ${stderr}  ${rc}=  BMC Execute Command
    ...  cat /etc/nslcd.conf

    Should Contain  ${ldap_server_config}  ${ldap_server}
    ...  msg=${ldap_server} is not configured.

Delete LDAP Config
    [Documentation]  Delete LDAP Config from REST.

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${BMC_LDAP_URI}/action/delete  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Check LDAP Config File Deleted
    [Documentation]  Check LDAP file nslcd.conf deleted.

    BMC Execute Command  [ ! -f /etc/nslcd.conf ]
