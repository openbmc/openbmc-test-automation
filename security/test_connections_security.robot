*** Settings ***

Documentation    Test suite to verify security requirements.
Resource         ../lib/resource.robot
Resource         ../lib/utils.robot
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/connection_client.robot
Library          SSHLibrary

*** Variables ***

${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}

*** Test Cases ***

Verify User Cannot Login After 5 Non-Logged In Sessions
    [Documentation]  Open Five SSH sessions without entering password and open 6th session
    ...  with correct login and verify result should be error.
    [Tags]  Verify_User_Cannot_Login_After_5_Non-Logged_In_Sessions

    FOR  ${i}  IN RANGE  ${1}  ${6}
       SSHLibrary.Open Connection  ${host}
       Log To Console   ${i}
       Start Process  ssh ${username}@${host}  shell=True
    END
    SSHLibrary.Open Connection  ${host}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${username}  ${password}
    Should Be Equal  ${status}  ${False}
