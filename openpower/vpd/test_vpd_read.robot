*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) read functionality of vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py
Resource        ../../lib/openbmc_ffdc.robot

Test Teardown   FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

Verify All VPD Details
    [Documentation]  Verify all VPD details via vpdtool '-i' option.
    [Tags]  Verify_ALL_VPD_Details

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


*** Keywords ***

Verify VPD Field Data
    [Documentation]  Verify field data of given VPD component.
    [Arguments]  ${vpd_records}  ${component}
    # Description of arguments:
    # vpd_records     All VPD data Via vpdtool.
    # component       VDP component (e.g. /system/chassis/motherboard/vdd_vrm1).

    # Verification of "CC" and "FN" will be added later.
    @{vpd_fields}=  Create List  DR  type  LocationCode
    FOR  ${field}  IN  @{vpd_fields}
      Log  ${VPD_DETAILS['${component}']['${field}']}
      Log  ${vpd_records['${component}']['${field}']}
      Valid Value  vpd_records['${component}']['${field}']  ['${VPD_DETAILS['${component}']['${field}']}']

      # Verify if "SN" and "PN" fields of VPD has alphanumeric value.
      Should Match Regexp  ${vpd_records['${component}']['SN']}  [a-zA-Z0-9]
      Should Match Regexp  ${vpd_records['${component}']['PN']}  [a-zA-Z0-9]
    END

