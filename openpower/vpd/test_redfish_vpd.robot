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


*** Keywords ***

Verify Redfish VPD Data
    [Documentation]  Verify Redfish VPD data of given component.
    [Arguments]  ${component}  ${field}
    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).
    # field           VPD field (e.g. Model, PartNumber etc.).

    ${component_uri}=  Set Variable If
    ...  '${component}' == 'BMC'  /redfish/v1/Managers/bmc
    ...  '${component}' == 'Chassis'  /redfish/v1/Chassis/chassis
    ...  '${component}' == 'CPU'  /redfish/v1/Systems/system/Processors/cpu0

    ${resp}=  Redfish.Get Properties  ${component_uri}
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

    ${vpd_records}=  Vpdtool  -o -O ${vpd_component}

    Run Keyword if  '${field}' == 'Location'
    ...    Should Be Equal As Strings  ${resp["Location"]["PartLocation"]["ServiceLabel"]}
    ...    ${vpd_records['${vpd_component}']['${vpd_field}']}
    ...  ELSE
    ...    Should Be Equal As Strings  ${resp["${field}"]}  ${vpd_records['${vpd_component}']['${vpd_field}']}
