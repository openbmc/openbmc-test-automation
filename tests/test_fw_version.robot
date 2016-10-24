*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Test Teardown       Log FFDC


*** Variables ***

*** Test Cases ***
Test BMC Version
    [Documentation]     Verifying if the BMC Version field is set with valid strings.\n
    ...     Expected in following format:
    ...     $ git describe --dirty
    ...     v0.1-34-g95f7347
    ...     $
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/system/chassis/motherboard/bmc
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["version"]}    msg=version field is empty
    Should Match Regexp     ${jsondata["data"]["version"]}      ^v\\d+\.\\d+

Test BIOS Version
    [Documentation]     Verifying if the BIOS Version field is set with valid strings.\n
    ...     Expected in following format:
    ...     open-power-barreleye-v1.8
    ...     $

    [Tags]  chassisboot    Test_BIOS_Version
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/system/bios
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["Version"]}    msg=Version field is empty
    Should Match Regexp     ${jsondata["data"]["Version"]}      ^open+\-\power+\-\
