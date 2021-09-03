*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) via busctl command.
...             Before running this suite, create a data/vpd_data.py file with
...             all VPD data to verify from system.
...
...             #!/usr/bin/env python3
...             VPD_DETAILS = {
...                 "/system/chassis/motherboard": {
...                     "DR": "SYSTEM BACKPLANE",
...                     "LocationCode": "ABCD.EF1.1234567-P0",
...                     "PN": "PN12345",
...                     "SN": "SN1234567890",
...                 },
...                 "/system/chassis/motherboard/base_op_panel_blyth": {
...                     "DR": "CEC OP PANEL",
...                     "LocationCode": "ABCD.EF1.1234567-D0",
...                     "PN": "PN12345",
...                     "SN": "SN1234567890",
...                 }
...             }

Variables       ../../data/vpd_data.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_INVENTORY_PREFIX}  busctl get-property xyz.openbmc_project.Inventory.Manager
...  /xyz/openbmc_project/inventory


*** Test Cases ***

Verify Vital Product Data
    [Documentation]  Verify VPD via busctl command.
    [Tags]  Verify_Vital_Product_Data

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}
    FOR  ${component}  IN  @{components}
        Verify VPD Via Busctl  ${component}
    END


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

    # Skip check for other VPD fields if its an ethernet component.
    ${status}=  Run Keyword And Return Status  Should Contain  ${component}  ethernet
    Return From Keyword If  '${status}' == 'True'

    # Verify PrettyName
    ${busctl_output}=  BMC Execute Command
    ...  ${CMD_INVENTORY_PREFIX}${component} xyz.openbmc_project.Inventory.Item PrettyName
    Should Contain  ${busctl_output[0].split('"')[1].strip('"')}
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
