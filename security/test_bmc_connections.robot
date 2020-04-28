*** Settings ***

Documentation    Test suite to verify security requirements.
Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot
Library          SSHLibrary

*** Variables ***

${MAX_UNAUTH_PER_IP}=   ${5}

*** Test Cases ***

Verify User Cannot Login After 5 Non-Logged In Sessions
    [Documentation]  User should not be able to login when there
    ...  are 5 non-logged in sessions.
    [Tags]  Verify_User_Cannot_Login_After_5_Non-Logged_In_Sessions

    FOR  ${i}  IN RANGE  ${0}  ${MAX_UNAUTH_PER_IP}
       SSHLibrary.Open Connection  ${OPENBMC_HOST}
       Start Process  ssh ${OPENBMC_USERNAME}@${OPENBMC_HOST}  shell=True
    END

    SSHLibrary.Open Connection  ${OPENBMC_HOST}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    Should Be Equal  ${status}  ${False}
