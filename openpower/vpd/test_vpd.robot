*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) via busctl command.

Variables       ../../data/vpd_data.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_INVENTORY_PREFIX}  busctl get-property xyz.openbmc_project.Inventory.Manager
...  /xyz/openbmc_project/inventory


*** Test Cases ***

Verify VPD Data
    [Documentation]  Verify VPD via busctl command.
    [Tags]  Verify_VPD_Data
    [Template]  Verify VPD Via Busctl

    # Component name
    /system/chassis/motherboard
    /system/chassis/motherboard/base_op_panel_blyth
    /system/chassis/motherboard/ebmc_card_bmc
    /system/chassis/motherboard/lcd_op_panel_hill
    /system/chassis/motherboard/tpm_wilson
    /system/chassis/motherboard/vdd_vrm0
    /system/chassis/motherboard/vdd_vrm1


*** Keywords ***

Verify VPD Via Busctl
    [Documentation]  Verify VPD details via busctl.
    [Arguments]  ${component}

    # Description of argument(s):
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verify Location code
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX}${component} com.ibm.ipzvpd.Location LocationCode
    Should Be Equal  ${busctl_output[0].split('"')[1].strip('"')}
    ...  ${VPD_DETAILS['${component}']['LocationCode']}

    # Verify PrettyName
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX}${component} xyz.openbmc_project.Inventory.Item PrettyName
    Should Be Equal  ${busctl_output[0].split('"')[1].strip('"')}
    ...  ${VPD_DETAILS['${component}']['DR']}

    # Verify Part Number
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX}${component} xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
    Should Be Equal  ${busctl_output[0].split('"')[1].strip('"')}
    ...  ${VPD_DETAILS['${component}']['PN']}

    # Verify Serial Number
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX}${component} xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber
    Should Be Equal  ${busctl_output[0].split('"')[1].strip('"')}
    ...  ${VPD_DETAILS['${component}']['SN']}
