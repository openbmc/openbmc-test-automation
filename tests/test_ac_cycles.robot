*** Settings ***

Documentation   This testsuite is for testing file corruption on hard power cycle

Resource          ../lib/pdu/pdu.robot
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections

*** Test Cases ***
Test openbmc buster
    [Tags]      reboot_tests
    ${output}=  Execute Command    find /var/lib -type f |xargs -n 1 touch
    PDU Power Cycle
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   1min

    # Need to re connect the session
    Open Connection And Log In
    ${stdout}   ${stderr}   ${rc}=  Execute Command     echo "hello world"    return_stderr=True  return_rc=True
    Should Be Equal As Integers    ${rc}    ${0}

*** Keywords ***
