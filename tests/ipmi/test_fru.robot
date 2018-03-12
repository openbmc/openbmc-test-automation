*** Settings ***
Documentation  Test IPMI sensor IDs.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot

Suite setup             Setup The Suite
Test Setup              Open Connection And Log In
Test Teardown           Test Teardown Execution

*** Test Cases ***


Test CPU FRU Info At Power On
    [Documentation]  Verify CPU FRU info via IPMI and REST at power on.

    [Tags]  Test_CPU_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Test FRU Info  cpu  Product Name  Product Part Number  Product Version  Product Serial


*** Keywords ***

Get URL List
    [Documentation]  Get URL list of given component.
    [Arguments]  ${component}

    # Description of argument(s):
    # component    Component name.

    ${list}=  Get Dictionary Keys  ${SYSTEM_INFO}
    ${component_list}=  Get Matches  ${list}  regexp=^.*[0-9a-z_].${component}[0-9]*$
    [Return]  ${component_list}


Get FRU Info Via IPMI
    [Documentation]  Return IPMI FRU info of given component.
    [Arguments]  ${component}  ${field}

    # Description of argument(s):
    # component    Component name.

    # Example of IPMI SDR elist output.
    # FRU Device Description : Builtin FRU Device (ID 0)
    #  Device not present (Unspecified error)
    # 
    # FRU Device Description : cpu0 (ID 1)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090290
    #  Board Part Number     : 02AA860

    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090288
    #  Board Part Number     : 02AA860


    ${fru_print_output}=  Run Keyword And Continue On Failure  Run IPMI Standard Command  fru print -N 50
    Log To Console  ${fru_print_output}
    @{fru_section}=
    ...  Split String  ${fru_print_output}  FRU Device
    Log  ${fru_section}


    Log  ${component}
    ${last_index}=  Set Variable  0

    # Get index of FRU entry of given component.
    :FOR  ${fru}  IN  @{fru_section}
    \  ${fru_component_section}=  Get From List  ${fru_section}  ${last_index}
    \  ${status}=  Run Keyword And Return Status  Should Contain  ${fru_component_section}  ${component}
    \  Exit For Loop If  '${status}' == '${True}'
    \  ${last_index}=  Evaluate  ${last_index} + 1

    ${fru_component_section}=  Get From List  ${fru_section}  ${last_index}

    Log To Console  ${fru_component_section}

    ${field_line}=
    ...  Get Lines Containing String  ${fru_component_section}  ${field}
    ...  case-insensitive

    ${field_value}=  Fetch From Right  ${field_line}  :
    ${field_value}=  Strip String  ${field_value}
    [return]  ${field_value}


Verify FRU Info
    [Documentation]  Verify IPMI FRU info of given component
    ...  with REST.
    [Arguments]  ${component}  ${field1}=${EMPTY}  ${field2}=${EMPTY}
    ...  ${field3}=${EMPTY}  ${field3}=${EMPTY}  ${field4}=${EMPTY}
    ...  ${field5}=${EMPTY}

    # Description of argument(s):
    # component    Component name.

    # Example of inventory info via REST
    #     "/xyz/openbmc_project/inventory/system/chassis/motherboard/dimm14": {
    #       "BuildDate": "",
    #       "Cached": 0,
    #       "FieldReplaceable": 1,
    #       "Functional": 1,
    #       "Manufacturer": "0x2c80",
    #       "Model": "18ASF1G72PZ-2G6B1   ",
    #       "PartNumber": "",
    #       "Present": 1,
    #       "PrettyName": "0x0c",
    #       "SerialNumber": "0x1585f5ea",
    #       "Version": "0x31"

    ${mfg_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  Manufacturer

    ${serial_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  SerialNumber

    ${part_number_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  PartNumber

    ${product_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component}  PrettyName

    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090288
    #  Board Part Number     : 02AA860

    ${mfg_ipmi}=  Get FRU Info Via IPMI  ${component}  Board Mfg
    ${serial_ipmi}=  Get FRU Info Via IPMI  ${component}  Board Product
    ${part_number_ipmi}=  Get FRU Info Via IPMI  ${component}  Board Part Number
    ${product_ipmi}=  Get FRU Info Via IPMI  ${component}  Board Product

    Run Keyword If  '${field1}' != '${EMPTY}'
    ...    Should Be True  '${mfg_rest}' == '${mfg_ipmi}'

    Run Keyword If  '${field2}' != '${EMPTY}'
    ...    Should Be True  '${serial_rest}' == '${serial_ipmi}'

    Run Keyword If  '${field3}' != '${EMPTY}'
    ...    Should Be True  ${part_number_rest} == ${part_number_ipmi}

    Run Keyword If  '${field4}' != '${EMPTY}'
    ...    Should Be True  ${product_rest} == ${product_ipmi}



Test FRU Info
    [Documentation]  Test FRU info of given component.
    [Arguments]  ${component}  ${field1}=${EMPTY}  ${field2}=${EMPTY}
    ...  ${field3}=${EMPTY}  ${field3}=${EMPTY}  ${field4}=${EMPTY}
    ...  ${field5}=${EMPTY}

    # Description of argument(s):
    # component    Component name.

    ${component_url_list}=  Get URL List  ${component}
    : FOR  ${uri}  IN  @{component_url_list}
    \  ${component}=  Fetch From Right  ${uri}  motherboard/
    \  Log To Console  ${component}
    \  Verify FRU Info  ${component}  ${field1}  ${field2}  ${field3}  ${field4}  ${field5}


Setup The Suite
    [Documentation]  Do the initial suite setup.

    REST Power On  stack_mode=skip  quiet=1

    Open Connection And Log In
    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=90
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    #FFDC On Test Case Fail
    Close All Connections
