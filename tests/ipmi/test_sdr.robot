*** Settings ***
Documentation  Test IPMI sensor IDs.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot

Suite setup             Setup The Suite
Test Setup              Open Connection And Log In
Test Teardown           Test Teardown Execution

*** Test Cases ***


Test CPU Core SDR Info At Power On
    [Documentation]  Verify CPU core SDR info via IPMI and REST at power on.

    [Tags]  Test_CPU_Core_SDR_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Test SDR Info  core


Test DIMM SDR Info At Power On
    [Documentation]  Verify DIMM SDR info via IPMI and REST at power on.

    [Tags]  Test_DIMM_SDR_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Test SDR Info  dimm

Test CPU Core SDR Info At Power Off
    [Documentation]  Verify CPU core SDR info via IPMI and REST at power off.

    [Tags]  Test_CPU_Core_SDR_Info_At_Power_Off

    REST Power Off
    Test SDR Info  core


Test DIMM SDR Info At Power Off
    [Documentation]  Verify DIMM SDR info via IPMI and REST at power off.

    [Tags]  Test_DIMM_SDR_Info_At_Power_Off

    REST Power Off
    Test SDR Info  dimm


*** Keywords ***

Get URL List
    [Documentation]  Get URL list of given component.
    [Arguments]  ${component}

    # Description of argument(s):
    # component    Component name.

    ${list}=  Get Dictionary Keys  ${SYSTEM_INFO}
    ${component_list}=  Get Matches  ${list}  regexp=^.*[0-9a-z_].${component}[0-9]*$
    [Return]  ${component_list}


Get SDR Presence Via IPMI
    [Documentation]  Return IPMI SDR presence info.
    [Arguments]  ${component}

    # Description of argument(s):
    # component    Component name.

    # Example of IPMI SDR elist output.
    # BootProgress     | 03h | ok  | 34.2 |
    # OperatingSystemS | 05h | ok  | 35.1 | boot completed - device not specified
    # AttemptsLeft     | 07h | ok  | 34.1 |
    # occ0             | 08h | ok  | 210.1 | Device Disabled
    # occ1             | 09h | ok  | 210.2 | Device Disabled
    # cpu0_core0       | 12h | ok  | 208.1 | Presence detected
    # cpu0_core1       | 15h | ok  | 208.2 | Disabled
    # cpu0_core2       | 18h | ok  | 208.3 | Presence detected
    # dimm0            | A6h | ok  | 32.1 | Presence Detected
    # dimm1            | A8h | ok  | 32.2 | Presence Detected
    # dimm2            | AAh | ok  | 32.9 | Presence Detected
    # gv100card0       | C5h | ok  | 216.1 | 0 unspecified
    # gv100card1       | C8h | ok  | 216.2 | 0 unspecified
    # TPMEnable        | D7h | ok  |  3.3 | State Asserted
    # auto_reboot      | DAh | ok  | 33.2 | State Asserted
    # volatile         | DBh | ok  | 33.1 | State Deasserted

    ${sdr_elist_output}=  Run IPMI Standard Command  sdr elist
    ${sdr_component_line}=
    ...  Get Lines Containing String  ${sdr_elist_output}  ${component}
    ...  case-insensitive

    ${presense_ipmi}=  Fetch From Right  ${sdr_component_line}  |
    ${presense_ipmi}=  Strip String  ${presense_ipmi}
    [return]  ${presense_ipmi}


Verify SRD Info
    [Documentation]  Verify IPMI sensor data record for given component
    ...  with REST.
    [Arguments]  ${component}

    # Description of argument(s):
    # component    Component name.

    ${presence_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  Present
    ${functional_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  Functional

    ${component}=  Replace String  ${component}  /  _
    ${presence_ipmi}=  Get SDR Presence Via IPMI  ${component}${SPACE}

    Run Keyword If   '${presence_ipmi}' == 'Disabled'
    ...    Should Be True  ${presence_rest} == ${0} and ${functional_rest} == ${0}
    ...  ELSE IF  '${presence_ipmi}' == 'Presence Detected' or '${presence_ipmi}' == 'Presence detected'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${1}
    ...  ELSE IF  '${presence_ipmi}' == 'State Asserted'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${1}
    ...  ELSE IF  '${presence_ipmi}' == 'State Deasserted'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${0}
    ...  ELSE  Fail  msg=Invalid Presence${presence_ipmi}


Test SDR Info
    [Documentation]  Test SDR info of given component.
    [Arguments]  ${component}

    # Description of argument(s):
    # component    Component name.

    ${component_url_list}=  Get URL List  ${component}
    : FOR  ${uri}  IN  @{component_url_list}
    \  ${component}=  Fetch From Right  ${uri}  motherboard/
    \  Log To Console  ${component}
    \  Verify SRD Info  ${component}


Setup The Suite
    [Documentation]  Do the initial suite setup.

    REST Power On  stack_mode=skip  quiet=1

    Open Connection And Log In
    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=90
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections

