*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/connection_client.robot
Test Teardown       FFDC On Test Case Fail


*** Variables ***

${CMD}   cat /etc/os-release | grep ^VERSION_ID= | cut -f 2 -d '='

*** Test Cases ***
Test BMC Version
    [Documentation]     Verifying if the BMC Version field is set with valid strings.\n
    ...     Expected in following format:
    ...     $ git describe --dirty
    ...     v0.1-34-g95f7347
    ...     $
    [Tags]  Test_BMC_Version

    ${resp}=    OpenBMC Get Request
    ...   ${INVENTORY_URI}system/chassis/motherboard/bmc
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

    ${resp}=    OpenBMC Get Request    ${INVENTORY_URI}system/bios
    Should Be Equal As Strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}
    Should not be empty     ${jsondata["data"]["Version"]}    msg=Version field is empty
    Should Match Regexp     ${jsondata["data"]["Version"]}      ^open+\-\power+\-\


Software Version Management
    [Documentation]  Verify version and Activation status.
    [Tags]  Software_Version_Management
    ${managed_version}=  Get Software Version List
    :FOR  ${element}  IN  @{managed_list} 
    \  Verify Software Properties  ${element}


*** Keywords ***

Get Software Version List
    [Documentation]  Get the software version endpoints list.
    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}
    Should Be Equal As Strings  ${resp.status_code}    ${HTTP_OK}
    [Return]  ${jsondata["data"]}


Verify Software Properties
    [Documentation]  Verify the software endpoints properties.
    [Arguments]  ${endpoint}
    # endpoints  Managed element by software version manager.
    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}${endpoint}
    Should Be Equal As Strings  ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    To Json    ${resp.content}

    Check Activation Status  ${jsondata["data"]["Activation"]}
    Check BMC Version  ${jsondata["data"]["Version"]}


Check BMC Version
    [Documentation]  Get BMC version from /etc/os-release and compare.
    [Arguments]  ${version}
    # version  Software version
    Open Connection And Log In
    ${stdout}  ${stderr}=  Execute Command  ${CMD}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Be Equal As Strings  ${version}  ${stdout}


Check Activation Status
    [Documentation]  Check if software state is "Active".
    [Arguments]  ${status}
    # status  Activation status
    Should Be Equal As Strings  ${ACTIVE}  ${status}
