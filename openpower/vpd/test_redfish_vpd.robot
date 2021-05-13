*** Settings ***
Documentation   This suite tests Vital Product Data (VPD) using Redfish.

Resource        ../../lib/openbmc_ffdc.robot
Library         ../../lib/vpd_utils.py

Test Teardown   FFDC On Test Case Fail


*** Variables ***

${CMD_GET_PROPERTY_INVENTORY}  busctl get-property xyz.openbmc_project.Inventory.Manager
${DR_WRITE_VALUE}              XYZ Component
${PN_WRITE_VALUE}              XYZ1234
${SN_WRITE_VALUE}              ABCD12345678

*** Test Cases ***

Verify Redfish TPM VPD
    [Documentation]  Verify TPM VPD details with Redfish output.
    [Tags]  Verify_Redfish_CPU_VPD

    Verify Redfish VPD data  TPM


*** Keywords ***

Verify Redfish VPD data
    [Documentation]  Verify Redfish VPD data of given component.
    [Arguments]  ${component}
    # Description of arguments:
    # component       VPD component (e.g. /system/chassis/motherboard/vdd_vrm1).

    ${component_uri}=  Set Variable If
    ...  '${component}' == 'CPU'  /redfish/v1/Systems/system/Processors
    ...  '${component}' == 'TPM'  /redfish/v1/Chassis/chassis/Assembly

    ${resp}=  Redfish.Get  ${component_uri}
    ${resp_list}=  Redfish_Utils.List Request  ${component_uri}

    # Example o/p:
    # [{'@odata.id': '/redfish/v1/Chassis/chassis/Assembly#/Assemblies/0'},
    #  {'@odata.id': '/redfish/v1/Chassis/chassis/Assembly#/Assemblies/1}]

    FOR  ${value}  IN  @{resp_list}
      ${component_uri_new}=  Set Variable  ${value}
      ${name}=  Redfish.Get Attribute  ${value}  Name
      ${status}=  Run Keyword And Return Status  Should Contain  ${name}  ${component}
      Exit For Loop If  '${status}' == '${True}'
    END
    Log  ${component_uri_new}
    Verify Redfish VPD  ${component}  /redfish/v1/Chassis/chassis/Assembly#/Assemblies/0  SerialNumber


Verify Redfish VPD
    [Documentation]  Verify Redfish VPD of given URI.
    [Arguments]  ${component}  ${component_uri}  ${field}
    # Description of arguments:
    # componet_uri       Redfish VPD uri (e.g. /redfish/v1/Systems/system/Processors/cpu1).
    # field              Redfish VPD field (Model)

    ${resp}=  Redfish.Get Properties  ${component_uri}
    Log  ${resp}
    #Valid Value  resp['Model']  ['SessionService']

    ${vpd_field}=  Set Variable If
    ...  '${field}' == 'Model'  CC
    ...  '${field}' == 'PartNumber'  PN
    ...  '${field}' == 'SerialNumber'  SN
    ...  '${field}' == 'SparePartNumber'  FN

    ${vpd_component}=  Set Variable If
    ...  '${component}' == 'TPM'  /system/chassis/motherboard/tpm_wilson
    ...  '${compoment}' == 'OP PANEL'  /system/chassis/motherboard/base_op_panel_blyth

    ${vpd_records}=  Vpdtool  -r -O ${vpd_component} -R VINI -K ${vpd_field}
    Should Be Equal As Strings  Y130UF05W01T  ${vpd_records['${vpd_component}']['${vpd_field}']}

