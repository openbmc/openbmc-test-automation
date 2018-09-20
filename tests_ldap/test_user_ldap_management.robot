*** Settings ***
Documentation   OpenBMC LDAP user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot

*** Variables ****

*** Test Cases ***

Verify LDAP Client Service Is Running And API Available
    [Documentation]  Verify LDAP client service is running and API available.
    [Tags]  Verify_LDAP_Client_Service_Is_Running_And_API_Available

    Check LDAP Service Running
    ${resp}=  Read Properties  ${BMC_LDAP_URI}
    Should Not Be Empty  ${resp}

*** Keywords ***

Check LDAP Service Running
    [Documentation]  Check LDAP service running in BMC.

    BMC Execute Command  systemctl | grep -in ldap
