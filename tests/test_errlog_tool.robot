*** Settings ***
Documentation       This suite will verify the debugging tool "logging-test."

Resource            ../lib/connection_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot

Test Setup          Open Connection And Log In
Test Teardown       Close All Connections

*** Test Cases ***

Commit AutoTestSimple
    [Documentation]  Commits the error "AutoTestSimple."
    Execute Command On BMC   logging-test -c AutoTestSimple
    ${resp}=  OpenBMC Get Request  /xyz/openbmc_project/logging/entry/1
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Delete AutoTestSimple
    [Documentation]  Deletes the error "AutoTestSimple."
    ${resp}=  OpenBMC Delete Request  /xyz/openbmc_project/logging/entry/1
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
