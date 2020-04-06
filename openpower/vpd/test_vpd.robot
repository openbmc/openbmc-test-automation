*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) via busctl command.

Variables       ../../data/vpd_variables.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_INVENTORY_PREFIX}  busctl get-property xyz.openbmc_project.Inventory.Manager
...  /xyz/openbmc_project/inventory/

*** Test Cases ***

Verify VPD Data
    [Documentation]  Verify VPD via busctl command.
    [Tags]  Verify_VP_Data
    [Template]  Verify VPD Via Busctl

    # Component name
    system
    system/chassis
    system/chassis/motherboard
    system/chassis/motherboard/base_op_panel_blyth
    system/chassis/motherboard/ebmc_card_bmc
    system/chassis/motherboard/ebmc_card_bmc/ethernet0
    system/chassis/motherboard/ebmc_card_bmc/ethernet1
    system/chassis/motherboard/lcd_op_panel_hill
    system/chassis/motherboard/vdd_vrm0
    system/chassis/motherboard/vdd_vrm1


*** Keywords ***


Verify VPD Via Busctl
    [Documentation]  Verify VPD details via busctl.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${cmd}=  Catenate  ${CMD_LOCATION_CODE}${component} com.ibm.ipzvpd.Location  LocationCode s
    ${output}=  BMC Execute Command  ${cmd}
    Valid Value  output  ['${VPD_DETAILS['${component}']['LocationCode']}']

