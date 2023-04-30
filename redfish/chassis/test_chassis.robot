*** Settings ***
Documentation    Chassis Validation.

Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/rest_client.robot
Library          ../../lib/bmc_redfish_utils.py
Library          ../../lib/utils.py
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/sensor_info_record.robot

Library          OperatingSystem
Library          Collections

Suite Setup     Suite Setup Execution
Suite Teardown  Redfish.Logout

*** Variables ***
&{chassis_properties}
@{chassis_uri_list}

*** Test Case ***
Check Chassis Collections Count Is Not Reduced When Host Was Rebooted
    [Documentation]  chassis collection count should not be reduced when host was rebooted.
    [Tags]  Check_Chassis_Collections_Count_Is_Not_Reduced_When_Host_Was_Rebooted

    ${count_bfr_host_reboot}=  Get Respective Sensor Property Value Via Redfish  /redfish/v1/Chassis
    ...  Members@odata.count
    ${mbr_lst_before_host_reboot}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    Redfish Power On  stack_mode=normal  quiet=1
    ${count_afr_host_reboot}=  Get Respective Sensor Property Value Via Redfish  /redfish/v1/Chassis
    ...  Members@odata.count
    ${mbr_lst_after_host_reboot}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    ${missing_chassis_id}=  return_missing_value_from_list  ${mbr_lst_before_host_reboot}
    ...  ${mbr_lst_after_host_reboot}
    Run Keyword And Continue On Failure  Should Be Equal  ${count_bfr_host_reboot}  ${count_afr_host_reboot}
    ...  message=chassis count is not matched after host reboot, missing chassis id are ${missing_chassis_id}

Check Property Response Were Not Empty For All Chassis Instances
    [Documentation]  Manufacture, model, part number and serial number property in redfish response
    ...  for all chassis instance should not be empty.
    [Tags]  Check_Property_Response_Were_Not_Empty

    FOR  ${chassis_uri}  IN  @{chassis_uri_list}
      Check Property Response Were Not Empty  ${chassis_uri}
    END

Validate Property Value With Dbus Value
    [Documentation]  Compare manufacturer, model, part number and serial number property with
    ...  dbus command response.
    [Tags]  Validate_Property_Value_With_Dbus_Value
    [Template]  Validate Redfish Response With Dbus

    FOR  ${chassis_uri}  IN  @{chassis_uri_list}
      ${chassis_uri}  Manufacturer
      ${chassis_uri}  Model
      ${chassis_uri}  PartNumber
      ${chassis_uri}  SerialNumber
    END

Check Proper Values Are Showing For Properties In Redfish Response
    [Documentation]  Check properties values are showing properly in redfish.
    [Tags]  Check_Proper_Values_Are_Showing_For_Properties_In_Redfish_Response
    [Template]  Check Proper Property Response Is Showing In Redfish Response

    FOR  ${chassis_uri}  IN  @{chassis_uri_list}
      ${chassis_uri}  Manufacturer
      ${chassis_uri}  Model
      ${chassis_uri}  PartNumber
      ${chassis_uri}  SerialNumber
    END

*** Keywords ***
Suite Setup Execution
    [Documentation]  Do suite setup execution.

    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1
    ${chassis_members_list}=  redfish_utils.get_member_list  /redfish/v1/Chassis/
    FOR  ${chassis_uri}  IN  @{chassis_members_list}
      &{tmp_dict}=  Create Dictionary
      ${cpld_status}=  Run Keyword And Return Status  Should Contain  ${chassis_uri}  Luna
      Continue For Loop IF  ${cpld_status} == False
      Append To List  ${chassis_uri_list}  ${chassis_uri}
      ${sensor_properties}=  Redfish.Get Properties  ${chassis_uri}
      ${manufacturer}=  Set Variable  ${sensor_properties['Manufacturer']}
      ${model}=  Set Variable  ${sensor_properties['Model']}
      ${part_number}=  Set Variable  ${sensor_properties['PartNumber']}
      ${serial_number}=  Set Variable  ${sensor_properties['SerialNumber']}
      Set To Dictionary  ${tmp_dict}  Manufacturer  ${manufacturer}
      Set To Dictionary  ${tmp_dict}  Model  ${model}
      Set To Dictionary  ${tmp_dict}  PartNumber  ${part_number}
      Set To Dictionary  ${tmp_dict}  SerialNumber  ${serial_number}
      Set To Dictionary  ${chassis_properties}  ${chassis_uri}  ${tmp_dict}
    END

Validate Redfish Response With Dbus
    [Documentation]  Validate redfish property value with dbus.
    [Arguments]  ${redfish_uri}  ${property}

    ${redfish_property_value}=  Set Variable  ${chassis_properties['${redfish_uri}']['${property}']}
    ${cmd}=  Catenate  busctl get-property xyz.openbmc_project.EntityManager
    ...  /xyz/openbmc_project/inventory/system/board/${redfish_uri.split("/")[-1]}
    ...  xyz.openbmc_project.Inventory.Decorator.Asset ${property}
    ${dbus_command_response}=  BMC Execute Command  ${cmd}
    ${dbus_cmd_response}=  Get From List  ${dbus_command_response}  0
    ${dbus_rsp}=  Set Variable  ${dbus_cmd_response.split(" ")[-1].split('"')[1]}
    Should Not Be Empty  ${dbus_rsp}
    ...  msg=${property} property value is showing as empty in dbus.
    Run Keyword And Continue On Failure  Should Be Equal As Strings  ${redfish_property_value}  ${dbus_rsp}
    ...  msg=${property} property for ${redfish_uri} and respective chassis id dbus cmd rsp is mismatched

Check Proper Property Response Is Showing In Redfish Response
    [Documentation]  Validate response is showing properly in redfish.
    [Arguments]  ${redfish_uri}  ${property}

    ${redfish_property_value}=  Set Variable  ${chassis_properties['${redfish_uri}']['${property}']}
    ${redfish_value_status}=  Run Keyword And Return Status  Should Not Contain  ${redfish_property_value}  $
    Run Keyword IF  ${redfish_value_status} == False
    ...  Fail  msg=${property} property in "${redfish_uri}" uri shows response as, ${redfish_property_value}

Check Property Response Were Not Empty
    [Documentation]  Property response should not be empty.
    [Arguments]  ${chassis_uri}

    ${manufacturer}=  Set Variable  ${chassis_properties['${chassis_uri}']['Manufacturer']}
    Run Keyword And Continue On Failure  Should Not Be Empty  ${manufacturer}
    ...  msg=${chassis_uri} Manufacturer property value was showing as empty.
    ${model}=  Set Variable  ${chassis_properties['${chassis_uri}']['Model']}
    Run Keyword And Continue On Failure  Should Not Be Empty  ${model}
    ...  msg=${chassis_uri} Model property value was showing as empty.
    ${part_number}=  Set Variable  ${chassis_properties['${chassis_uri}']['PartNumber']}
    Run Keyword And Continue On Failure  Should Not Be Empty  ${part_number}
    ...  msg=${chassis_uri} PartNumber property value was showing as empty.
    ${serial_number}=  Set Variable  ${chassis_properties['${chassis_uri}']['SerialNumber']}
    Run Keyword And Continue On Failure  Should Not Be Empty  ${serial_number}
    ...  msg=${chassis_uri} SerialNumber property value was showing as empty.
