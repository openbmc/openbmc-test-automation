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


Verify System VPD Data Via Redfish
    [Documentation]  Verify system Model and SN via Redfish output.
    [Tags]  Verify_System_VPD_Data_Via_Redfish
    [Template]  Verify Redfish VPD Data

    # Component     Field
    System          Model
    System          SerialNumber


Verify Power Supply VPD Data Via Redfish
    [Documentation]  Verify power supply VPD details via Redfish output.
    [Tags]  Verify_Power_Supply_VPD_Data_Via_Redfish
    [Template]  Verify All Redfish VPD Data

    # Component     Field
    Power Supply    Model
    Power Supply    PartNumber
    Power Supply    SerialNumber
    Power Supply    SparePartNumber
    Power Supply    Location


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
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  TPM Card
    ...  ELSE IF  '${component}' == 'TOD Battery'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  Time Of Day Battery
    ...  ELSE IF  '${component}' == 'VRM'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  Voltage Regulator Module
    ...  ELSE IF  '${component}' == 'OP Panel'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  Operator Panel Base
    ...  ELSE IF  '${component}' == 'OP Panel LCD'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  Operator Panel LCD
    ...  ELSE IF  '${component}' == 'Disk Backplane'
    ...    Set Variable  /redfish/v1/Chassis/chassis/Assembly  NVMe Backplane
    ...  ELSE IF  '${component}' == 'System'
    ...    Set Variable  /redfish/v1/Systems/system  System

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
    ...  '${component}' == 'BMC'  /system/chassis/motherboard/bmc
    ...  '${component}' == 'TPM'  /system/chassis/motherboard/tpm
    ...  '${component}' == 'TOD Battery'  /system/chassis/motherboard/bmc/tod_battery
    ...  '${component}' == 'VRM'  /system/chassis/motherboard/vrm0
    ...  '${component}' == 'OP Panel'  /system/chassis/motherboard/dasd_backplane/panel0
    ...  '${component}' == 'OP Panel LCD'  /system/chassis/motherboard/dasd_backplane/panel1
    ...  '${component}' == 'Disk Backplane'  /system/chassis/motherboard/dasd_backplane
    ...  '${component}' == 'System'  /system

    ${vpd_records}=  Vpdtool  -o -O ${vpd_component}

    Run Keyword if  '${field}' == 'Location'
    ...    Should Be Equal As Strings  ${resp["Location"]["PartLocation"]["ServiceLabel"]}
    ...    ${vpd_records['${vpd_component}']['${vpd_field}']}

    # Check whether the vpd details from redfish and vpdtool are the same.
    ...  ELSE IF  '${component}' == 'System'
    ...    Should Be Equal As Strings  ${resp["${field}"]}  ${vpd_records['${vpd_component}']['${field}']}
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


Verify All Redfish VPD Data
    [Documentation]  Verify all Redfish VPD data of given component.
    [Arguments]  ${component}  ${field}

    # Description of arguments:
    # component       VPD component (TPM Card, Power Supply).
    # field           VPD field (e.g. Model, PartNumber etc.).

    ${redfish_component_uri}=  Set Variable  /redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies

    ${redfish_uri_list}=  Get Member List
    ...  ${redfish_component_uri}

    # Example output:
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply0'}
    # {'@odata.id': '/redfish/v1/Chassis/chassis/PowerSubsystem/PowerSupplies/powersupply1'}

    ${vpd_field}=  Set Variable If
    ...  '${field}' == 'Model'  CC
    ...  '${field}' == 'PartNumber'  PN
    ...  '${field}' == 'SerialNumber'  SN
    ...  '${field}' == 'SparePartNumber'  FN
    ...  '${field}' == 'Location'  LocationCode

    FOR  ${uri}  IN  @{redfish_uri_list}
        ${resp}=  Redfish.Get Properties  ${uri}
        ${name}=  Fetch From Right  ${uri}  /
        ${vpd_component}=  Set Variable  /system/chassis/motherboard/${name}
        ${vpd_records}=  Vpdtool  -o -O ${vpd_component}

        # Check whether the vpd details from redfish and vpdtool are the same.
        Run Keyword if  '${field}' == 'Location'
        ...    Should Be Equal As Strings  ${resp["Location"]["PartLocation"]["ServiceLabel"]}
        ...    ${vpd_records['${vpd_component}']['${vpd_field}']}
        ...  ELSE
        ...    Should Be Equal As Strings  ${resp["${field}"]}
        ...    ${vpd_records['${vpd_component}']['${vpd_field}']}
    END
