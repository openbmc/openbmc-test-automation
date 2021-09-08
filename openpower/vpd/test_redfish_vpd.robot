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

    # Component  Field
    TPM          Model
    TPM          PartNumber
    TPM          SerialNumber
    TPM          SparePartNumber
    TPM          Location


Verify TOD Battery VPD Data Via Redfish
    [Documentation]  Verify TOD battery VPD details via Redfish output.
    [Tags]  Verify_TOD_Battery_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component  Field
    TOD Battery  Model
    TOD Battery  PartNumber
    TOD Battery  SerialNumber
    TOD Battery  SparePartNumber
    TOD Battery  Location


*** Keywords ***

Verify Redfish VPD Data
    [Documentation]  Verify Redfish VPD data of given component.
    [Arguments]  ${component}  ${field}
    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD field (e.g. Model, PartNumber etc.).

    ${redfish_component_uri}  ${redfish_component_name}=  Run Keyword If
    ...  '${component}' == 'BMC'  Set Variable  /redfish/v1/Managers/bmc  OpenBmc Manager
    ...  ELSE IF  '${component}' == 'Chassis'  Set Variable  /redfish/v1/Chassis/chassis  RackMount
    ...  ELSE IF  '${component}' == 'CPU'  Set Variable  /redfish/v1/Systems/system/Processors/cpu0  Processor
    ...  ELSE IF  '${component}' == 'TPM'  Set Variable  /redfish/v1/Chassis/chassis/Assembly  tpm_wilson
    ...  ELSE IF  '${component}' == 'TOD Battery'  Set Variable  /redfish/v1/Chassis/chassis/Assembly  tod_battery

    ${resp}=  Run Keyword If  '${redfish_component_uri}' == '/redfish/v1/Chassis/chassis/Assembly'  Get Assembly Component VPD  ${redfish_component_name}
    ...  ELSE  Redfish.Get Properties  ${redfish_component_uri}

    ${vpd_field}=  Set Variable If
    ...  '${field}' == 'Model'  CC
    ...  '${field}' == 'PartNumber'  PN
    ...  '${field}' == 'SerialNumber'  SN
    ...  '${field}' == 'SparePartNumber'  FN
    ...  '${field}' == 'Location'  LocationCode

    ${vpd_component}=  Set Variable If
    ...  '${component}' == 'CPU'  /system/chassis/motherboard/cpu0
    ...  '${component}' == 'Chassis'  /system/chassis
    ...  '${component}' == 'BMC'  /system/chassis/motherboard/ebmc_card_bmc
    ...  '${component}' == 'TPM'  /system/chassis/motherboard/tpm_wilson
    ...  '${component}' == 'TOD Battery'  /system/chassis/motherboard/tod_battery

    ${vpd_records}=  Vpdtool  -o -O ${vpd_component}

    Run Keyword if  '${field}' == 'Location'
    ...    Should Be Equal As Strings  ${resp["Location"]["PartLocation"]["ServiceLabel"]}
    ...    ${vpd_records['${vpd_component}']['${vpd_field}']}
    ...  ELSE
    ...    Should Be Equal As Strings  ${resp["${field}"]}  ${vpd_records['${vpd_component}']['${vpd_field}']}


Get Assembly Component VPD
    [Documentation]  Returns Redfish VPD data of given assembly component.
    [Arguments]  ${component_name}
    # Description of arguments:
    # component_name  Assembly's component name (e.g. tpm_wilson, tod_battery).

    ${resp}=  Redfish.Get Properties  /redfish/v1/Chassis/chassis/Assembly
    FOR  ${assembly_component}  IN  @{resp["Assemblies"]}
        Log  ${assembly_component}
        ${output}=  Set Variable If  "${component_name}" == "${assembly_component["Name"]}"  ${assembly_component}
        Exit For Loop IF  "${component_name}" == "${assembly_component["Name"]}"
    END
    [Return]  ${output}
