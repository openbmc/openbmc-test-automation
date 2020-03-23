*** Settings ***
Documentation   This suite tests System Vital Product Data (VPD) using vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_GET_PROPERTY_INVENTORY}  busctl get-property xyz.openbmc_project.Inventory.Manager
${DR_WRITE_VALUE}              XYZ Component
${PN_WRITE_VALUE}              XYZ1234
${SN_WRITE_VALUE}              ABCD12345678

*** Test Cases ***

Verify System VPD
    [Documentation]  Verify system VPD details via vpdtool '-i' option.
    [Tags]  Verify_System_VPD

    ${vpd_records}=  Vpdtool  -i

    ${components}=  Get Dictionary Keys  ${vpd_records}
    FOR  ${component}  IN  @{components}
        Verify VPD Data  ${vpd_records}  ${component}
    END


Verify VPD Component Read
    [Documentation]  Verify details of VPD component via vpdtool.
    [Tags]  Verify_VPD_Component_Read

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}
    FOR  ${component}  IN  @{components}
        Verify VPD Component Read Operation  ${component}
    END


Verify VPD Field Read
    [Documentation]  Verify reading VPD field value via vpdtool.
    [Tags]  Verify_VPD_Field_Read

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}
    FOR  ${component}  IN  @{components}
        Verify VPD Field Read Operation  ${component}
    END


Verify VPD Field Write
    [Documentation]  Verify writting VPD field value via vpdtool.
    [Tags]  Verify_VPD_Field_Write

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}
    FOR  ${component}  IN  @{components}
        Verify VPD Field Write Operation  ${component}
    END


*** Keywords ***

Verify VPD Data
    [Documentation]  Verify VPD data of given component.
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


Verify VPD Component Read Operation
    [Documentation]  Verify reading VPD details of given compoment via vpdtool.
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

    Verify VPD Data  ${vpd_records}  ${component}


Verify VPD Field Read Operation
    [Documentation]  Verify reading all VPD fields for given compoment via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  SN  PN

    FOR  ${fields}  IN   @{vpd_fields}
        Verify VPD Field Value  ${component}  ${fields}
    END


Verify VPD Field Write Operation
    [Documentation]  Verify writing all VPD fields for given compoment via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  SN  PN

    ${field}=  Evaluate  random.choice($vpd_fields)  random

    FOR  ${fields}  IN   @{vpd_fields}
        ${write_value}=  Set Variable If
        ...  '${field}' == 'DR'  ${DR_WRITE_VALUE}
        ...  '${field}' == 'PN'  ${PN_WRITE_VALUE}
        ...  '${field}' == 'SN'  ${SN_WRITE_VALUE}
        Vpdtool  -w -O ${component} -R VINI -K ${field} --value ${write_value}
        Verify VPD Field Value  ${component}  ${fields}
    END


Verify VPD Field Value
    [Documentation]  Verify VPD field value via vpdtool.
    [Arguments]  ${component}  ${field}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD field (e.g. DR, SN, PN)

    ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}

    ${busctl_field}=  Set Variable If
    ...  '${field}' == 'DR'  xyz.openbmc_project.Inventory.Item PrettyName
    ...  '${field}' == 'PN'  xyz.openbmc_project.Inventory.Decorator.Asset PartNumber
    ...  '${field}' == 'SN'  xyz.openbmc_project.Inventory.Decorator.Asset SerialNumber

    ${cmd}=  Catenate  ${CMD_GET_PROPERTY_INVENTORY} /xyz/openbmc_project/inventory${component}
    ...  ${busctl_field}
    ${cmd_output}=  BMC Execute Command  ${cmd}

    Valid Value  vpd_records['${component}']['${field}']  ['${cmd_output[0].split('"')[1].strip('"')}']
