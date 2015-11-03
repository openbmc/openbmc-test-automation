*** Settings ***
Documentation     This testsuite is for testing inventory
Suite Teardown    Delete All Sessions
Resource          ../lib/rest_client.robot
Resource          ../lib/resource.txt

*** Test Cases ***
List Inventory
    [Documentation]     This testcase will get the inventory for the openbmc
    ...                 machine and validates with the expected inventory
    ${resp} =    OpenBMC Get Request    org/openbmc/inventory/list
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    ${ret}=    Get Inventory Schema    ${MACHINE_TYPE}
    : FOR    ${ELEMENT}    IN    @{ret}
    \    Should Contain    ${jsondata}    ${ELEMENT}
