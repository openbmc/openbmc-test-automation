*** Settings ***
Documentation   This suite tests System Vital Product Data (VPD) using vpdtool.

Library         ../../lib/vpd_utils.py
Variables       ../../data/vpd_variables.py

Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/boot_utils.robot
Resource        ../../lib/vpd_tool_resource.robot

Test Teardown   FFDC On Test Case Fail

Test Tags       VPD_Tool

*** Variables ***

${CMD_GET_PROPERTY_INVENTORY}  busctl get-property xyz.openbmc_project.Inventory.Manager

*** Test Cases ***

Verify System VPD Data Via Vpdtool
    [Documentation]  Verify the system VPD details via vpdtool output.
    [Tags]  Verify_System_VPD_Data_Via_Vpdtool
    [Template]  Verify VPD Data Via Vpdtool

    # Component     Field
    System          Model
    System          SerialNumber
    System          LocationCode


Verify VPD Component Read
    [Documentation]  Verify details of all VPD component via vpdtool.
    [Tags]  Verify_VPD_Component_Read

    ${vpd_records}=  Vpdtool  -i
    ${components}=  Get Dictionary Keys  ${vpd_records}
    FOR  ${component}  IN  @{components}
        Verify VPD Component Read Operation  ${component}
    END


Verify VPD Field Read
    [Documentation]  Verify reading VPD field value via vpdtool.
    [Tags]  Verify_VPD_Field_Read

    ${vpd_records}=  Vpdtool  -i
    ${components}=  Get Dictionary Keys  ${vpd_records}
    FOR  ${component}  IN  @{components}
       # Drive component field values response in ascii format
       # due to that skipping here.
       IF  'drive' in '${component}'
           CONTINUE
       ELSE
           Verify VPD Field Read Operation  ${component}
       END
    END


Verify VPD Field Write
    [Documentation]  Verify writing VPD field value via vpdtool.
    [Tags]  Verify_VPD_Field_Write

    # Put system to power off state before VPD write operation.
    Redfish Power Off  stack_mode=skip

    ${components}=  Get Dictionary Keys  ${VPD_DETAILS}
    FOR  ${component}  IN  @{components}
        # VPD fields "DR", "CC" and "FN" will be added later.
        @{vpd_fields}=  Create List  SN  PN
        ${field}=  Evaluate  random.choice($vpd_fields)  random
        Verify VPD Field Write Operation  ${component}  ${field}
    END
