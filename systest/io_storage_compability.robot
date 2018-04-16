*** Settings ***
Documentation    Robot Script to test IO Storage compatibility stress
Library    SSHLibrary
Suite Setup    lpar connection
Suite Teardown    Close All Connections

*** Variables ***
${HOST}
${USERNAME}
${PASSWORD}
${TIME}
${MDT}

*** Test Cases ***
IOStorage Compability Stress
    Set Suite Variable  ${iteration}  ${0}
    Log To Console    Running HTX, please wait.
    Repeat Keyword     ${TIME} times
    ...  Run Keywords
    ...  Set Suite Variable  ${iteration}  ${iteration +1}
    ...  AND  Log To Console  Iteration ${iteration}
    ...  AND  loop HTX
    Run Keyword    close HTX

*** Keywords ***
lpar connection
    Open Connection    ${HOST}
    Login    ${USERNAME}  ${PASSWORD}
    ${profile}=    Execute Command    htxcmdline -sut ${HOST} -createmdt ${MDT}
    Should Contain    ${profile}      mdts are created successfully.
     ${htx_run}=  Execute Command    htxcmdline -run -mdt ${MDT}
    Should Contain  ${htx_run}  Activated

loop HTX
    Repeat Keyword    1 hour
    ...    Run keywords    status_HTX
    ...    AND    Sleep    10 min
status_HTX
    ${status}=    Execute Command    htxcmdline -status -mdt ${MDT}
    Should Contain    ${status}    Currently running
    ${error}=    Execute Command     htxcmdline -geterrlog
    Should Contain  ${error}  file </tmp/htxerr> is empty
close HTX
     ${shutdown}=  Execute Command
    ...  htxcmdline -shutdown -mdt ${MDT}
    Should Contain  ${shutdown}  shutdown successfully