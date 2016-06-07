*** Settings ***

Documentation   This testsuite is for testing file corruption on hard power cycle

Resource        ../lib/pdu/pdu.robot
Resource        ../lib/utils.robot

Library         SSHLibrary

*** Test Cases ***
Test openbmc buster
    [Tags]      reboot_tests
    Open Connection And Log In
    ${output}=  Execute Command    find /var/lib -type f |xargs -n 1 touch
    PDU Power Cycle
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   1min
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=  Execute Command     echo "hello world"    return_stderr=True  return_rc=True
    Should Be Equal As Integers    ${rc}    ${0}

*** Keywords ***
Open Connection And Log In
    Open connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}   ${OPENBMC_PASSWORD}
