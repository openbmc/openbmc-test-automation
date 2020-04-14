*** Settings ***

Documentation    Testsuite for verify security requirements.
Library          SSHLibrary

*** Variables ***
	
${host}                     ${OPENBMC_HOST}
${username}                 ${OPENBMC_USERNAME}
${password}                 ${OPENBMC_PASSWORD}

*** Test Cases ***

Open Five SSH Sessions Without Entering Password And verify 6th Session With Correct Login
    [Documentation]  Open Five SSH sessions without entering password and open 6th session
    ...  with correct login and verify result should be error.
    [Tags]  OPEN_Five_Sessions_Without_Entering_Password_And_Verify_6th_Session_With_Correct_Login

    FOR  ${i}  IN RANGE  ${1}  ${6}
       SSHLibrary.Open Connection  ${host}
       Run Keyword And Ignore Error  SSHLibrary.Login  ${username}  ${EMPTY}
    END

    SSHLibrary.Open Connection  ${host}
    ${status}  Run Keyword And Return Status  SSHLibrary.Login  ${username}  ${password}
    Should be Equal  ${status}  ${False}
