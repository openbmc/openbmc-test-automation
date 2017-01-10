*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Test Teardown       FFDC On Test Case Fail


*** Variables ***

*** Test Cases ***
Test BMC Version
    [Documentation]     Verifying if the BMC Version field is set with valid strings.\n
    ...     Expected in following format:
    ...     $ git describe --dirty
    ...     v0.1-34-g95f7347
    ...     $
    ${resp}=    OpenBMC Get Request
    ...   ${INVENTORY_URI}system/chassis/motherboard/bmc
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["version"]}    msg=version field is empty
    Should Match Regexp     ${jsondata["data"]["version"]}      ^v\\d+\.\\d+
