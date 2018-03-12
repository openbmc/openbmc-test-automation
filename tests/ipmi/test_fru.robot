*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot
Library                ../../lib/ipmi_utils.py

Variables              ../data/ipmi_fru_table.py

Test Teardown          Test Teardown Execution

Force Tags             FRU_Test


*** Test Cases ***

Test CPU FRU Info At Power On
    [Documentation]  Verify CPU FRU info via IPMI and REST at power on.

    [Tags]  Test_CPU_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  cpu


Test DIMM FRU Info At Power On
    [Documentation]  Verify DIMM FRU info via IPMI and REST at power on.

    [Tags]  Test_DIMM_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  dimm


Test Fan FRU Info At Power On
    [Documentation]  Verify Fan FRU info via IPMI and REST at power on.

    [Tags]  Test_Fan_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  fan

Test BMC FRU Info At Power On
    [Documentation]  Verify BMC FRU info via IPMI and REST at power on.

    [Tags]  Test_BMC_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  bmc


Test System FRU Info At Power On
    [Documentation]  Verify system FRU info via IPMI and REST at power on.

    [Tags]  Test_System_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  system


Test Power Supply FRU Info At Power On
    [Documentation]  Verify power supply FRU info via IPMI and REST at
    ...  power on.

    [Tags]  Test_Power_Supply_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  powersupply


Test GPU FRU Info At Power On
    [Documentation]  Verify GPU FRU info via IPMI and REST at
    ...  power on.

    [Tags]  Test_GPU_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Verify FRU Info  gv100card


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

    # Example of CPU FRU info via IPMI
    # FRU Device Description : cpu0 (ID 1)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934108636
    #  Board Part Number     : 02AA862
    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934108643
    #  Board Part Number     : 02AA862

    ${ipmi_fru_component_info}=  Get Component FRU Info  ${component_name}

    ${rest_fru_component_info}=  Get Component Fru Info Via REST
    ...  ${component_name}

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
    #    board_mfg:                              IBM
    #    board_product:                          PROCESSOR MODULE
    #    board_serial:                           YA1934302970
    #    board_part_number:                      02CY211
    #  ipmi_cpu_fru_info[1]:
    #    fru_device_description:                 cpu1 (ID 2)
    #    board_mfg_date:                         Sun Dec 31 18:00:00 1995
    #    board_mfg:                              IBM
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
    [Documentation]  Compare IPMI And REST FRU Component data.
    [Arguments]  ${ipmi_fru_component_info}  ${rest_fru_component_info}
    ...  ${component_name}

    # Description of argument(s):
    # ipmi_fru_component_info  IPMI FRU component data in dictionary.
    # Example: 
    #    fru_device_description:                 cpu0 (ID 1)
    #    board_mfg_date:                         Sun Dec 31 18:00:00 1995
    #    board_mfg:                              IBM
    #    board_product:                          PROCESSOR MODULE
    #    board_serial:                           YA1934302970
    #    board_part_number:                      02CY211
    # rest_fru_component_info  REST FRU component data in dictionary.
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
    #    Manufacturer:                           IBM
    # component_name      The name of the component (e.g. "cpu", "dimm", etc.).

    # Get pre-defined set list from data/ipmi_fru_table.py for given component.
    # Example:
    # ['board_mfg', 'board_product', 'board_serial', '"board_part_number"']

    ${items}=  Get Dictionary Items  ${ipmi_fru_dict}
    ${fru_field_dict}=  Get From Dictionary  ${ipmi_fru_dict}  ${component_name}
    @{fru_field_list}=  Get Dictionary Keys  ${fru_field_dict}

    : FOR  ${field_name}  IN  @{fru_field_list}
    \  ${rest_field_name}=
    \  ...  Get From Dictionary  ${fru_field_dict}  ${field_name}
    \  ${ipmi_fru_field_value}=
    \  ...  Get From Dictionary  ${ipmi_fru_component_info}  ${field_name}
    \  ${rest_fru_field_value}=
    \  ...  Get From Dictionary  ${rest_fru_component_info}  ${rest_field_name}
    \  Should Contain  ${rest_fru_field_value}  ${ipmi_fru_field_value}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
