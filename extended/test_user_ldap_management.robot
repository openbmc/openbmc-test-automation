*** Settings ***
Documentation   OpenBMC LDAP user management test.

Resource         ../lib/rest_client.robot
Resource         ../lib/openbmc_ffdc.robot


*** Variables ****

*** Test Cases ***


Verify LDAP Service Is Running And API Available
    [Documentation]  Verify LDAP service is running and REST API available.
    [Tags]  Verify_LDAP_Service_Is_Running_And_API_Available

    Check LDAP Service Running
    ${resp}=  OpenBMC Get Request  ${BMC_LDAP_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}


Verify User API Shows Allgroups And Allprivileges
    [Documentation]  Verify user API shows groups and privileges.
    [Tags]  Verify_User_API_Shows_Allgroups_And_Allprivileges

    ${resp}=  OpenBMC Get Request  ${OPENBMC_BASE_URI}user
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Not Be Empty  ${jsondata["data"]}

*** Keywords ***

Check LDAP Service Running
    [Documentation]  Check LDAP service running in BMC.

    ${output}=  BMC Execute Command  systemctl | grep ldap
    Should Not Be Empty  ${output}


