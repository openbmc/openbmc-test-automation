*** Settings ***
Documentation       This suite is for Verifying BMC & BIOS version exposed part
...                 of system inventory

Resource            ../lib/rest_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/connection_client.robot
Test Teardown       FFDC On Test Case Fail


*** Variables ***


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
    [Documentation]  Verify version and activation status.
    [Tags]  Software_Version_Management
    ${managed_list}=  Get Software Version List
    :FOR  ${element}  IN  @{managed_list}
    \  Verify Software Properties  ${element}


*** Keywords ***

Get Software Version List
    [Documentation]  Get the software version endpoints list.
    # Example of JSON body data returned
    # "data": [
    #     "/xyz/openbmc_project/software/53c70e7b"
    # ],

    ${resp}=  OpenBMC Get Request  ${SOFTWARE_VERSION_URI}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]}


Verify Software Properties
    [Documentation]  Verify the software endpoints properties.
    [Arguments]  ${endpoint}
    # Description of arguments:
    # endpoint  Managed element by software version manager.
    #           Endpoint URI would be as shown bellow
    #           https://xx.xx.xx.xx/xyz/openbmc_project/software/53c70e7b
    ${resp}=  OpenBMC Get Request  ${endpoint}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}

    Check Activation Status  ${jsondata["data"]["Activation"]}
    Check BMC Version  ${jsondata["data"]["Version"]}


Check BMC Version
    [Documentation]  Get BMC version from /etc/os-release and compare.
    [Arguments]  ${version}
    # Description of arguments:
    # version  Software version (e.g. "v1.99.2-107-g2be34d2-dirty")
    Open Connection And Log In
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}=  Execute Command On BMC  ${cmd}
    Should Be Equal As Strings  ${version}  ${output[1:-1]}


Check Activation Status
    [Documentation]  Check if software state is "Active".
    [Arguments]  ${status}
    # Description of arguments:
    # status  Activation status
    # (e.g. "xyz.openbmc_project.Software.Activation.Activations.Active")
    Should Be Equal As Strings  ${ACTIVE}  ${status}
