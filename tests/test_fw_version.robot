*** Settings ***
Documentation       This suite will the firmware version exposed part of
...                 system inventory

Resource            ../lib/rest_client.robot


*** Variables ***


*** Test Cases ***
Test Firmware Version
    [Documentation]     This testcase is for testing the fw version.\n
    ...     Expected in following format:
    ...     $ git describe --dirty
    ...     v0.1-34-g95f7347
    ...     $
    ${resp} =    OpenBMC Get Request    /org/openbmc/inventory/system
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["Version"]}
    Should Match Regexp     ${jsondata["data"]["Version"]}      ^v\\d+\.\\d+