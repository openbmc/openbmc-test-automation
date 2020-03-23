*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) read functionality of vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Test Cases ***

Verify All VPD
    [Documentation]  Verify all VPD details via vpdtool '-i' option.
    [Tags]  Verify_ALL_VPD

    ${vpd_records}=  Vpdtool  -i

    # Example output from 'Vpdtool  -i':
    #  [/system/chassis/motherboard/vdd_vrm1]:
    #    [DR]:                                         CPU POWER CARD
    #    [type]:                                       xyz.openbmc_project.Inventory.Item.Vrm
    #    [CC]:                                         2E32
    #    [FN]:                                         F190827
    #    [LocationCode]:                               U78DA.ND1.       -P0-C23
    #    [SN]:                                         YL2E32010000
    #    [PN]:                                         PN12345
    #  [/system/chassis/motherboard/ebmc_card_bmc]:
    #    [LocationCode]:                               U78DA.ND1.       -P0-C5
    #    [SN]:                                         YL6B58010000
    #    [type]:                                       xyz.openbmc_project.Inventory.Item.Bmc
    #    [FN]:                                         F191014
    #    [PN]:                                         PN12345
    #    [CC]:                                         6B58
    #    [DR]:                                         EBMC

    ${components}=  Get Dictionary Keys  ${vpd_records}
    FOR  ${component}  IN  @{components}
        Verify VPD Field Data  ${vpd_records}  ${component}
    END


Verify Single VPD
    [Documentation]  Verify single VPD via vpdtool '-o -O' option.
    [Tags]  Verify_Single_VPD
    [Template]  Verify Single VPD Details

    # VPD component
    /system/chassis/motherboard
    /system/chassis/motherboard/vdd_vrm1
    /system/chassis/motherboard/base_op_panel_blyth
    /system/chassis/motherboard/ebmc_card_bmc
    /system/chassis/motherboard/lcd_op_panel_hill
    /system/chassis/motherboard/tpm_wilson
    /system/chassis/motherboard/vdd_vrm0
    /system/chassis/motherboard/vdd_vrm1


Verify Single VPD Field
    [Documentation]  Verify single VPD field value via vpdtool.
    [Tags]  Verify_Single_VPD_Field

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  SN  PN

    ${component}=  Evaluate  random.choice($components)  random
    ${field}=  Evaluate  random.choice($vpd_fields)  random

    ${vpd_records}=  Vpdtool  -r -O ${component} -R VINI -K ${field}

    Run Keyword If  '${field}' == 'DR'
    ...  Valid Value  vpd_records['${component}']['DR']  ['${VPD_DETAILS['${component}']['DR']}']
    ...  ELSE IF  '${field}' == 'SN'
    ...  Should Match Regexp  ${vpd_records['${component}']['SN']}  [a-zA-Z0-9]
    ...  ELSE IF  '${field}' == 'PN'
    ...  Should Match Regexp  ${vpd_records['${component}']['PN']}  [a-zA-Z0-9]


*** Keywords ***

Verify Single VPD Details
    [Documentation]  Verify sigle VPD details via vpdtool.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${vpd_records}=  Vpdtool  -o -O ${component}

    # Example output from 'Vpdtool  -o -O /system/chassis/motherboard/vdd_vrm1':
    #  [/system/chassis/motherboard/vdd_vrm1]:
    #    [DR]:                                         CPU POWER CARD
    #    [type]:                                       xyz.openbmc_project.Inventory.Item.Vrm
    #    [CC]:                                         2E32
    #    [FN]:                                         F190827
    #    [LocationCode]:                               U78DA.ND1.       -P0-C23
    #    [SN]:                                         YL2E32010000
    #    [PN]:                                         PN12345

    Verify VPD Field Data  ${vpd_records}  ${component}


Verify VPD Field Data
    [Documentation]  Verify field data of given VPD component.
    [Arguments]  ${vpd_records}  ${component}
    # Description of arguments:
    # vpd_records     All VPD data Via vpdtool.
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  type  LocationCode
    FOR  ${field}  IN  @{vpd_fields}
      Valid Value  vpd_records['${component}']['${field}']  ['${VPD_DETAILS['${component}']['${field}']}']
    END

    # Verify if "SN" and "PN" fields of VPD has alphanumeric value.
    Should Match Regexp  ${vpd_records['${component}']['SN']}  [a-zA-Z0-9]
    Should Match Regexp  ${vpd_records['${component}']['PN']}  [a-zA-Z0-9]
