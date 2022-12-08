*** Settings ***
Documentation    Module to test IPMI DCMI functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/bmc_network_utils.robot
Resource         ../lib/boot_utils.robot
Variables        ../data/ipmi_raw_cmd_table.py
Variables        ../data/dcmi_raw_cmd_table.py
Variables        ../data/ipmi_variable.py
Library          ../lib/bmc_network_utils.py
Library          ../lib/ipmi_utils.py
Library          ../lib/utilities.py
Library          JSONLibrary

Suite Setup  Verify Power Management Supported

*** Variables ***
${power_reading_json_file}      /usr/share/ipmi-providers/power_reading.json

*** Test Cases ***
Verify DCMI Get Power Reading
    [Documentation]  Verify IPMI DCMI raw command for get power reading.
    [Tags]  Verify_DCMI_Get_Power_Reading

    ${get_power_reading_resp}=  Run External IPMI Raw Command
    ...  ${DCMI_RAW_CMD['DCMI']['Get_Power_Reading'][0]}
    Log To Console  ${get_power_reading_resp}
    Verify Power reading  ${get_power_reading_resp}


Verify DCMI Get Power Reading With Invalid Request Data
    [Documentation]  Verify IPMI DCMI raw command with invalid request data anc expect the error code.
    [Tags]  Verify_DCMI_Get_Power_Reading_With_Invalid_Request_Data

    Verify Invalid IPMI Command  ${DCMI_RAW_CMD['DCMI']['Get_Power_Reading'][1]}
    ...  ${DCMI_RAW_CMD['DCMI']['Get_Power_Reading'][3]}


Verify DCMI Get Power Reading With Invalid Data Field In Request
    [Documentation]  Verify IPMI DCMI raw command with invalid data field in request anc expect the error code.
    [Tags]  Verify_DCMI_Get_Power_Reading_With_Invalid_Data_Field_In_Request

    Verify Invalid IPMI Command  ${DCMI_RAW_CMD['DCMI']['Get_Power_Reading'][2]}
    ...  ${DCMI_RAW_CMD['DCMI']['Get_Power_Reading'][4]}

*** Keywords ***
Get Content From Json File
    [Documentation]  Will get the content form the json file and return in JSON
    ...  format.
    [Arguments]  ${json_file_name}

    ${json_file_resp}=  BMC Execute Command  cat ${json_file_name}
    Log To Console  ${json_file_resp}
    ${resp_in_dict}=  Convert String To JSON  ${json_file_resp[0]}

    [Return]  ${resp_in_dict}


Get Dbus Object From Json File
    [Documentation]  Will get the dbus object from the given json file.
    [Arguments]  ${json_file}

    ${busctl_resp_dict}=  Get Content From Json File  ${json_file}

    [Return]  ${busctl_resp_dict['path']}


Verify Current Power Reading With Busctl Command Response
    [Documentation]  Verify given current power reading value with busctl command response.
    [Arguments]  ${power_reading_value}

    ${dbus_object}=  Get Dbus Object From Json File  ${power_reading_json_file}
    ${busctl_cmd}=  Catenate  busctl introspect xyz.openbmc_project.VirtualSensor ${dbus_object}
    Log To Console  ${busctl_cmd}
    ${busctl_cmd_resp}=  BMC Execute Command  ${busctl_cmd}
    Log To Console  ${busctl_cmd_resp}
    ${current_power_value_from_dbus}=  Get Regexp Matches  ${busctl_cmd_resp[0]}
    ...  \\.Value\\s+property\\s+d\\s+(\\S+)\\s  1
    Log To Console  ${current_power_value_from_dbus}

    ${min_value}=  Evaluate  ${power_reading_value} - 10
    ${max_value}=  Evaluate  ${power_reading_value} + 10

    Should Be True  ${min_value} < ${current_power_value_from_dbus[0]} < ${max_value}


Verify Power reading
    [Documentation]  Verify current, maximum, minium average power reading are all same
    ...  in the given response.
    [Arguments]  ${ipmi_resp}

    # Python module:  convert_lsb_to_msb(string)
    ${current_power}=  Convert LSB To MSB  ${ipmi_resp[4:9]}
    ${minimum_power}=  Convert LSB To MSB  ${ipmi_resp[10:15]}
    ${maximum_power}=  Convert LSB To MSB  ${ipmi_resp[16:21]}
    ${average_power}=  Convert LSB To MSB  ${ipmi_resp[22:27]}

    Should Be Equal  ${current_power}  ${minimum_power}
    Should Be Equal  ${current_power}  ${maximum_power}
    Should Be Equal  ${current_power}  ${average_power}

    Verify Current Power Reading With Busctl Command Response  ${current_power}


Verify Power Management Supported
    [Documentation]  Will issue Get capabilities info IPMI command, get power management status and
    ...  skip testcase if that is not supported.

    ${resp}=  Run External IPMI Raw Command
    ...  ${DCMI_RAW_CMD['DCMI']['Get_DCMI_Capabilities_Info'][0]}

    ${resp}=  Split String  ${resp}
    ${resp}=  Convert To Binary  ${resp[-2]}  base=16  length=8
    ${power_management_status}=  Set Variable If  ${resp[-1]} == 1
    ...  ${True}
    ...  ${False}

    Skip If  '${power_management_status}' == '${False}'
    ...  msg= Power Management is not supported, so skipping the power reading testcases.
