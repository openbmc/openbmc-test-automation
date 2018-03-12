*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot
Library                ../../lib/ipmi_utils.py

Variables              ../data/ipmi_rest_fru_field_map.py

Test Teardown          Test Teardown Execution
Suite Setup            Suite Setup Execution


*** Test Cases ***

Test FRU Info At Power On
    [Documentation]  Verify FRU info via IPMI and REST at power on.
    [Tags]  Test_FRU_Info_At_Power_On
    [Template]  Verify FRU Info

    # component_name
    cpu
    dimm
    fan
    bmc
    system
    powersupply
    gv100card


*** Keywords ***

Get Component Fru Info Via REST
    [Documentation]  Get FRU Information Via REST for the given component.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name  The name of the component (e.g. "cpu", "dimm", etc.).

    ${inventory_uris}=  Read Properties  ${HOST_INVENTORY_URI}list  quiet=${1}
    # From the inventory_uris, select just the ones for the component of
    # interest.
    ${component_uris}=  Get Matches  ${inventory_uris}
    ...  regexp=^.*[0-9a-z_].${component_name}[0-9]*$

    # Get the component information for each record.
    ${component_frus}=  Create List
    : FOR  ${component_uri}  IN  @{component_uris}
    \  ${result}=  Read Properties  ${component_uri}  quiet=${1}
    \  ${component}=  Fetch From Right  ${component_uri}  /
    \  Set To Dictionary  ${result}  fru_device_description  ${component}
    \  Append To List  ${component_frus}  ${result}
    [Return]  ${component_frus}


Verify FRU Info
    [Documentation]  Verify FRU information of given component.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name  The name of the component (e.g. "cpu", "dimm", etc.).

    ${ipmi_fru_component_info}=  Get Component FRU Info  ${component_name}
    ...  ${fru_objs}
    # Example of output from "Get Component FRU Info" keyword for CPU component.
    #
    #    ipmi_fru_info:
    #      ipmi_fru_info[0]:
    #        [fru_device_description]:  cpu0 (ID 1)
    #        [board_mfg_date]:          Sun Dec 31 18:00:00 1995
    #        [board_mfg]:               <Manufacturer Name>
    #        [board_product]:           PROCESSOR MODULE
    #        [board_serial]:            YA1934301835
    #        [board_part_number]:       02CY211
    #      ipmi_fru_info[1]:
    #        [fru_device_description]:  cpu1 (ID 2)
    #        [board_mfg_date]:          Sun Dec 31 18:00:00 1995
    #        [board_mfg]:               <Manufacturer Name>
    #        [board_product]:           PROCESSOR MODULE
    #        [board_serial]:            YA1934301834
    #        [board_part_number]:       02CY211

    ${rest_fru_component_info}=  Get Component FRU Info Via REST
    ...  ${component_name}
    # Example of output from "Get Component FRU Info Via REST" keyword for
    # CPU component.
    #
    #    rest_fru_info:
    #      rest_fru_info[0]:
    #        [FieldReplaceable]:        1
    #        [BuildDate]:               1996-01-01 - 00:00:00
    #        [fru_device_description]:  cpu0
    #        [Cached]:                  0
    #        [SerialNumber]:            YA1934301835
    #        [Functional]:              1
    #        [Version]:                 22
    #        [Model]:                   <blank>
    #        [PrettyName]:              PROCESSOR MODULE
    #        [PartNumber]:              02CY211
    #        [Present]:                 1
    #        [Manufacturer]:            <Manufacturer Name>
    #      rest_fru_info[1]:
    #        [FieldReplaceable]:        1
    #        [BuildDate]:               1996-01-01 - 00:00:00
    #        [fru_device_description]:  cpu1
    #        [Cached]:                  0
    #        [SerialNumber]:            YA1934301834
    #        [Functional]:              1
    #        [Version]:                 22
    #        [Model]:                   <blank>
    #        [PrettyName]:              PROCESSOR MODULE
    #        [PartNumber]:              02CY211
    #        [Present]:                 1
    #        [Manufacturer]:            <Manufacturer Name>

    ${inventory_uris}=  Read Properties
    ...  ${HOST_INVENTORY_URI}list  quiet=${1}

    # From the inventory_uris, select just the ones for the component of
    # interest. Example for cpu:
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1
    ${component_uris}=  Get Matches  ${inventory_uris}
    ...  regexp=^.*[0-9a-z_].${component_name}[0-9]*$

    : FOR  ${uri}  IN  @{component_uris}
    \  ${sub_component}=  Fetch From Right  ${uri}  /
    \  ${ipmi_index}=  Get Index Of FRU Sub Component Info
    \  ...  ${ipmi_fru_component_info}  ${sub_component}
    \  ${rest_index}=  Get Index Of FRU Sub Component Info
    \  ...  ${rest_fru_component_info}  ${sub_component}
    \  ${ipmi_fru_sub_component}=
    \  ...  Get From List  ${ipmi_fru_component_info}  ${ipmi_index}
    \  ${rest_fru_sub_component}=
    \  ...  Get From List  ${rest_fru_component_info}  ${rest_index}
    \  Compare IPMI And REST FRU Component Info  ${ipmi_fru_sub_component}
    \  ...  ${rest_fru_sub_component}  ${component_name}


Get Index Of FRU Sub Component Info
    [Documentation]  Get index of FRU sub component info from FRU component
    ...  data.
    [Arguments]  ${fru_component_info}  ${sub_component}
    # fru_component_info  FRU component data as a list of dictionaries.
    #  ipmi_cpu_fru_info[0]:
    #    fru_device_description:                 cpu0 (ID 1)
    #    board_mfg_date:                         Sun Dec 31 18:00:00 1995
    #    board_mfg:                              <Manufacturer Name>
    #    board_product:                          PROCESSOR MODULE
    #    board_serial:                           YA1934302970
    #    board_part_number:                      02CY211
    #  ipmi_cpu_fru_info[1]:
    #    fru_device_description:                 cpu1 (ID 2)
    #    board_mfg_date:                         Sun Dec 31 18:00:00 1995
    #    board_mfg:                              <Manufacturer Name>
    #    board_product:                          PROCESSOR MODULE
    #    board_serial:                           YA1934302965
    #    board_part_number:                      02CY211
    # sub_component       Sub component name (e.g. "cpu0", "cpu1", etc.).

    ${sub_component_count}=  Get Length  ${fru_component_info}
    ${index}=  Set Variable  ${0}

    : FOR  ${rest_fru_sub_component}  IN  @{fru_component_info}
    \  ${fru_component_section}=
    \  ...  Get From List  ${fru_component_info}  ${index}
    \  ${status}=  Run Keyword And Return Status  Should Contain
    \  ...  ${fru_component_section['fru_device_description']}
    \  ...  ${sub_component}
    \  Exit For Loop If  '${status}' == '${True}'
    \  ${index}=  Evaluate  ${index} + 1
    \  Exit For Loop If  ${index} >= ${sub_component_count}

    [Return]  ${index}


Compare IPMI And REST FRU Component Info
    [Documentation]  Compare IPMI And REST FRU Component data objects.
    [Arguments]  ${ipmi_fru_component_obj}  ${rest_fru_component_obj}
    ...  ${component_name}

    # Description of argument(s):
    # ipmi_fru_component_obj  IPMI FRU component data in dictionary.
    # Example:
    #    fru_device_description:                 cpu0 (ID 1)
    #    board_mfg_date:                         Sun Dec 31 18:00:00 1995
    #    board_mfg:                              <Manufacturer Name>
    #    board_product:                          PROCESSOR MODULE
    #    board_serial:                           YA1934302970
    #    board_part_number:                      02CY211
    # rest_fru_component_obj  REST FRU component data in dictionary.
    # Example:
    #    FieldReplaceable:                       1
    #    BuildDate:                              1996-01-01 - 00:00:00
    #    Cached:                                 0
    #    SerialNumber:                           YA1934302970
    #    Functional:                             1
    #    Version:                                22
    #    Model:                                  <blank>
    #    PrettyName:                             PROCESSOR MODULE
    #    PartNumber:                             02CY211
    #    Present:                                1
    #    Manufacturer:                           <Manufacturer Name>
    # component_name      The name of the component (e.g. "cpu", "dimm", etc.).

    # Get key_map from ipmi_rest_fru_field_map.
    ${key_map}=  Set Variable  ${ipmi_rest_fru_field_map['${component_name}']}
    : FOR  ${ipmi_key}  IN  @{ipmi_rest_fru_field_map['${component_name}'].keys()}
    \  ${rest_key}=  Set Variable  ${key_map['${ipmi_key}']}
    \  Should Contain  ${rest_fru_component_obj['${rest_key}']}
    ...  ${ipmi_fru_component_obj['${ipmi_key}']}
    ...  msg=Comparison failed.


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail


Suite Setup Execution
    [Documentation]  Do test setup initialization.

    REST Power On  stack_mode=skip  quiet=1
    ${fru_objs}=  Get Fru Info
    Set Suite Variable  ${fru_objs}

