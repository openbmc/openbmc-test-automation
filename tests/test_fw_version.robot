*** Settings ***
Documentation       This suite will the firmware version exposed part of
...                 system inventory

Resource            ../lib/rest_client.robot


*** Variables ***


*** Test Cases ***
Test Firmware Version
    [Documentation]     Verifying if the FW Version field is set with valid strings.\n
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
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/system/bios
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["Version"]}    msg=Version field is empty
    Should Match Regexp     ${jsondata["data"]["Version"]}      ^open+\-\power+\-\
