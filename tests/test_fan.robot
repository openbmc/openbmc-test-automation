*** Settings ***
Documentation     This testsuite is for testing fan interface for openbmc
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot

*** Test Cases ***
List all the fans
    ${resp} =    OpenBMC Get Request    /org.openbmc.control.Fan/
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
