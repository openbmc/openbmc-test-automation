*** Settings ***
Documentation  Test IPMI sensor IDs.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot

Suite setup             Suite Setup Execution
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

    REST Power Off  stack_mode=skip  quiet=1
    Test SDR Info  core


Test DIMM SDR Info At Power Off
    [Documentation]  Verify DIMM SDR info via IPMI and REST at power off.

    [Tags]  Test_DIMM_SDR_Info_At_Power_Off

    REST Power Off  stack_mode=skip  quiet=1
    Test SDR Info  dimm


*** Keywords ***

Get Component URIs
    [Documentation]  Get URIs for given component and return as a list.
    [Arguments]  ${component_name}

    # A sample result returned for the "core" component:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core1
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core10
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core11
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core12
    # (etc.)

    # Description of argument(s):
    # component_name    Component name (e.g. "core", "dimm", etc.).

    ${base_uri_list}=  Get Dictionary Keys  ${SYSTEM_INFO}
    ${component_uris}=  Get Matches  ${base_uri_list}
    ...  regexp=^.*[0-9a-z_].${component_name}[0-9]*$
    [Return]  ${component_uris}


Get SDR Presence Via IPMI
    [Documentation]  Return presence info from IPMI sensor data record.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu0_core0", "dimm0", etc.).

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
    ...  Get Lines Containing String  ${sdr_elist_output}  ${component_name}
    ...  case-insensitive

    ${presence_ipmi}=  Fetch From Right  ${sdr_component_line}  |
    ${presence_ipmi}=  Strip String  ${presence_ipmi}
    [Return]  ${presence_ipmi}


Verify SRD
    [Documentation]  Verify IPMI sensor data record for given component
    ...  with REST.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu0/core0", "dimm0", etc.).

    ${presence_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component_name}
    ...  Present
    ${functional_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component_name}
    ...  Functional

    # Replace "/" with "_" if there is any "/" in component name.
    # e.g. cpu0/core0 to cpu0_core0
    ${component_name}=  Replace String  ${component_name}  /  _
    ${presence_ipmi}=  Get SDR Presence Via IPMI  ${component_name}${SPACE}

    Run Keyword If  '${presence_ipmi}' == 'Disabled'
    ...    Should Be True  ${presence_rest} == 0 and ${functional_rest} == 0
    ...  ELSE IF  '${presence_ipmi}' == 'Presence Detected' or '${presence_ipmi}' == 'Presence detected'
    ...    Should Be True  ${presence_rest} == 1 and ${functional_rest} == 1
    ...  ELSE IF  '${presence_ipmi}' == 'State Asserted'
    ...    Should Be True  ${presence_rest} == 1 and ${functional_rest} == 1
    ...  ELSE IF  '${presence_ipmi}' == 'State Deasserted'
    ...    Should Be True  ${presence_rest} == 1 and ${functional_rest} == 0
    ...  ELSE  Fail  msg=Invalid Presence${presence_ipmi}


Test SDR Info
    [Documentation]  Test SDR info for given component.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "core", "dimm", etc.).

    ${component_uri_list}=  Get Component URIs  ${component_name}
    : FOR  ${uri}  IN  @{component_uri_list}
    \  ${component_name}=  Fetch From Right  ${uri}  motherboard/
    \  Log To Console  ${component_name}
    \  Verify SRD  ${component_name}


Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    REST Power On  stack_mode=skip  quiet=1

    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=90
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
