*** Settings ***

Documentation    Testsuite for verify security requirements.
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

Open Five SSH Sessions Without Entering Password And verify 6th Session With Correct Login
    [Documentation]  Open Five SSH sessions without entering password and open 6th session
    ...  with correct login and verify result should be error.
    [Tags]  Open_Five_Sessions_Without_Entering_Password_And_Verify_6th_Session_With_Correct_Login

    FOR  ${i}  IN RANGE  ${1}  ${6}
       log To Console  ${i}
       ${index}=  SSHLibrary.Open Connection  ${host}
       log to console  ${index}
       ${ret_val}=  get Connection  1
       log to console  ${ret_val}
       Start Process  ssh ${username}@${host}  shell=True
    END
    SSHLibrary.Open Connection  ${host}
    ${status}=   Run Keyword And Return Status  SSHLibrary.Login  ${username}  ${password}
    Should Be Equal  ${status}  ${False}
