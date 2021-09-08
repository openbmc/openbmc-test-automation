*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) using Redfish.

Resource        ../../lib/openbmc_ffdc.robot
Library         ../../lib/vpd_utils.py

Suite Setup     Redfish.Login
Suite Teardown  Redfish.Logout
Test Teardown   FFDC On Test Case Fail


*** Test Cases ***

Verify BMC VPD Data Via Redfish
    [Documentation]  Verify BMC VPD details via Redfish output.
    [Tags]  Verify_BMC_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component  Field
    BMC          Model
    BMC          PartNumber
    BMC          SerialNumber
    BMC          SparePartNumber
    BMC          Location


Verify Chassis VPD Data Via Redfish
    [Documentation]  Verify Chassis VPD details via Redfish output.
    [Tags]  Verify_Chassis_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Skipping chassis's spare part number test because it has issue.
    # Component  Field
    Chassis      Model
    Chassis      PartNumber
    Chassis      SerialNumber
    #Chassis      SparePartNumber
    Chassis      Location


Verify CPU VPD Data Via Redfish
    [Documentation]  Verify CPU VPD details via Redfish output.
    [Tags]  Verify_CPU_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component  Field
    CPU          Model
    CPU          PartNumber
    CPU          SerialNumber
    CPU          SparePartNumber
    CPU          Location


Verify TPM VPD Data Via Redfish
    [Documentation]  Verify TPM VPD details via Redfish output.
    [Tags]  Verify_TPM_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    TPM             Model
    TPM             PartNumber
    TPM             SerialNumber
    TPM             SparePartNumber
    TPM             Location


Verify TOD Battery VPD Data Via Redfish
    [Documentation]  Verify TOD battery VPD details via Redfish output.
    [Tags]  Verify_TOD_Battery_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    TOD Battery     Model
    TOD Battery     PartNumber
    TOD Battery     SerialNumber
    TOD Battery     SparePartNumber
    TOD Battery     Location


Verify VRM VPD Data Via Redfish
    [Documentation]  Verify voltage regulator module VPD details via Redfish output.
    [Tags]  Verify_VRM_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    VRM             Model
    VRM             PartNumber
    VRM             SerialNumber
    VRM             SparePartNumber
    VRM             Location


Verify OP Panel VPD Data Via Redfish
    [Documentation]  Verify operator panel VPD details via Redfish output.
    [Tags]  Verify_OP_Panel_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    OP Panel        Model
    OP Panel        PartNumber
    OP Panel        SerialNumber
    OP Panel        SparePartNumber
    OP Panel        Location


Verify OP Panel LCD VPD Data Via Redfish
    [Documentation]  Verify operator panel LCD VPD details via Redfish output.
    [Tags]  Verify_OP_Panel_LCD_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    OP Panel LCD    Model
    OP Panel LCD    PartNumber
    OP Panel LCD    SerialNumber
    OP Panel LCD    SparePartNumber
    OP Panel LCD    Location


Verify Disk Backplane VPD Data Via Redfish
    [Documentation]  Verify disk backplane VPD details via Redfish output.
    [Tags]  Verify_Disk_Backplane_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    Disk Backplane  Model
    Disk Backplane  PartNumber
    Disk Backplane  SerialNumber
    Disk Backplane  SparePartNumber
    Disk Backplane  Location


*** Keywords ***

Verify Redfish VPD Data
    [Documentation]  Verify Redfish VPD data of given component.
    [Arguments]  ${component}  ${field}

    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD field (e.g. Model, PartNumber etc.).

    ${redfish_component_uri}  ${redfish_component_name}=  Run Keyword If
    ...  '${component}' == 'BMC'  Set Variable  /redfish/v1/Managers/bmc  OpenBmc Manager
    ...  ELSE IF  '${component}' == 'Chassis'
    ...    Set Variable  /redfish/v1/Chassis/chassis  RackMount
    ...  ELSE IF  '${component}' == 'CPU'
    ...    Set Variable  /redfish/v1/Systems/system/Processors/cpu0  Processor
    ...  ELSE IF  '${component}' == 'TPM'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  tpm_wilson
    ...  ELSE IF  '${component}' == 'TOD Battery'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  tod_battery
    ...  ELSE IF  '${component}' == 'VRM'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  vdd_vrm0
    ...  ELSE IF  '${component}' == 'OP Panel'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  base_op_panel_blyth
    ...  ELSE IF  '${component}' == 'OP Panel LCD'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  lcd_op_panel_hill
    ...  ELSE IF  '${component}' == 'Disk Backplane'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  disk_backplane0

    ${resp}=  Run Keyword If  '${redfish_component_uri}' == '/redfish/v1/Chassis/chassis/Assembly'
    ...  Get Assembly Component VPD  ${redfish_component_name}
    ...  ELSE  Redfish.Get Properties  ${redfish_component_uri}

    ${vpd_field}=  Set Variable If
    ...  '${field}' == 'Model'  CC
    ...  '${field}' == 'PartNumber'  PN
    ...  '${field}' == 'SerialNumber'  SN
    ...  '${field}' == 'SparePartNumber'  FN
    ...  '${field}' == 'Location'  LocationCode

    ${vpd_component}=  Set Variable If
    ...  '${component}' == 'CPU'  /system/chassis/motherboard/dcm0/cpu0
    ...  '${component}' == 'Chassis'  /system/chassis
    ...  '${component}' == 'BMC'  /system/chassis/motherboard/ebmc_card_bmc
    ...  '${component}' == 'TPM'  /system/chassis/motherboard/tpm_wilson
    ...  '${component}' == 'TOD Battery'  /system/chassis/motherboard/tod_battery
    ...  '${component}' == 'VRM'  /system/chassis/motherboard/vdd_vrm0
    ...  '${component}' == 'OP Panel'  /system/chassis/motherboard/base_op_panel_blyth
    ...  '${component}' == 'OP Panel LCD'  /system/chassis/motherboard/lcd_op_panel_hill
    ...  '${component}' == 'Disk Backplane'  /system/chassis/motherboard/disk_backplane0

    ${vpd_records}=  Vpdtool  -o -O ${vpd_component}

    Run Keyword if  '${field}' == 'Location'
    ...    Should Be Equal As Strings  ${resp["Location"]["PartLocation"]["ServiceLabel"]}
    ...    ${vpd_records['${vpd_component}']['${vpd_field}']}
    ...  ELSE
    ...    Should Be Equal As Strings  ${resp["${field}"]}  ${vpd_records['${vpd_component}']['${vpd_field}']}


Get Assembly Component VPD
    [Documentation]  Returns Redfish VPD data of given assembly component.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name  Assembly's component name (e.g. tpm_wilson, tod_battery).

    ${resp}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Assembly
    FOR  ${assembly_component}  IN  @{resp["Assemblies"]}
        ${output}=  Set Variable If
        ...  "${component_name}" == "${assembly_component["Name"]}"  ${assembly_component}
        Exit For Loop IF  "${component_name}" == "${assembly_component["Name"]}"
    END
    [Return]  ${output}
