*** Settings ***
Documentation   This suite tests System Vital Product Data (VPD) using vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_GET_PROPERTY_INVENTORY}  busctl get-property xyz.openbmc_project.Inventory.Manager


*** Test Cases ***

Verify System VPD
    [Documentation]  Verify system VPD details via vpdtool '-i' option.
    [Tags]  Verify_System_VPD

    ${vpd_records}=  Vpdtool  -i

    ${components}=  Get Dictionary Keys  ${vpd_records}
    FOR  ${component}  IN  @{components}
        Verify VPD Field Data  ${vpd_records}  ${component}
    END


Verify VPD Component
    [Documentation]  Verify VPD details of VPD component via vpdtool.
    [Tags]  Verify_VPD_Component
    [Template]  Verify VPD Component Details

    # VPD component
    /system/chassis/motherboard
    /system/chassis/motherboard/vdd_vrm1
    /system/chassis/motherboard/base_op_panel_blyth
    /system/chassis/motherboard/ebmc_card_bmc
    /system/chassis/motherboard/lcd_op_panel_hill
    /system/chassis/motherboard/tpm_wilson
    /system/chassis/motherboard/vdd_vrm0
    /system/chassis/motherboard/vdd_vrm1


Verify VPD Field
    [Documentation]  Verify VPD value of VPD field via vpdtool.
    [Tags]  Verify_VPD_Field

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  SN  PN

    ${component}=  Evaluate  random.choice($components)  random
    ${field}=  Evaluate  random.choice($vpd_fields)  random

    ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}

    ${busctl_field}=  Set Variable If
    ...  '${field}' == 'DR'  xyz.openbmc_project.Inventory.Item PrettyName
    ...  '${field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
    ...  '${field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber

    ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY} /xyz/openbmc_project/inventory${component}
    ...  ${busctl_field}
    ${cmd_output}=  BMC Execute Command  ${cmd}

    Valid Value  vpd_records['${component}']['${field}']  ['${cmd_output[0].split('"')[1].strip('"')}']


*** Keywords ***

Verify VPD Component Details
    [Documentation]  Verify VPD details of given compoment via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${vpd_records}=  Vpdtool  -o -O ${component}

    # Example output from 'Vpdtool  -o -O /system/chassis/motherboard/vdd_vrm1':
    #  [/system/chassis/motherboard/vdd_vrm1]:
    #    [DR]:                                         CPU POWER CARD
    #    [type]:                                       xyz.openbmc_project.Inventory.Item.Vrm
    #    [CC]:                                         E123
    #    [FN]:                                         F123456
    #    [LocationCode]:                               ABCD.XY1.1234567-P0
    #    [SN]:                                         YL2E32010000
    #    [PN]:                                         PN12345

    Verify VPD Field Data  ${vpd_records}  ${component}


Verify VPD Field Data
    [Documentation]  Verify field data of given VPD component.
    [Arguments]  ${vpd_records}  ${component}
    # Description of arguments:
    # vpd_records     All VPD data Via vpdtool.
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  LocationCode  SN  PN
    FOR  ${field}  IN  @{vpd_fields}
      ${busctl_field}=  Set Variable If
      ...  '${field}' == 'DR'  xyz.openbmc_project.Inventory.Item PrettyName
      ...  '${field}' == 'LocationCode'  com.ibm.ipzvpd.Location LocationCode
      ...  '${field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
      ...  '${field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber

      ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY} /xyz/openbmc_project/inventory${component}
      ...  ${busctl_field}
      ${cmd_output}=  BMC Execute Command  ${cmd}
      # Example of cmd_output:
      #   [0]:                                            s "ABCD.XY1.1234567-P0"
      #   [1]:
      #   [2]:                                            0

      Valid Value  vpd_records['${component}']['${field}']  ['${cmd_output[0].split('"')[1].strip('"')}']
    END
    Valid Value  vpd_records['${component}']['type']  ['${VPD_DETAILS['${component}']['type']}']

