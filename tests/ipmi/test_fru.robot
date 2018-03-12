*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../../lib/rest_client.robot
Resource               ../../lib/ipmi_client.robot
Resource               ../../lib/openbmc_ffdc.robot
Resource               ../../lib/boot_utils.robot
Library                ../../lib/ipmi_utils.py

Suite setup            Suite Setup Execution
Test Teardown          Test Teardown Execution

Force Tags             FRU_Test


*** Test Cases ***

Test CPU FRU Info At Power On
    [Documentation]  Verify CPU FRU info via IPMI and REST at power on.

    [Tags]  Test_CPU_FRU_Info_At_Power_On

    REST Power On  stack_mode=skip  quiet=1
    Test FRU Info  cpu  Board Mfg  Board Product  Board Serial
    ...  Board Part Number


*** Keywords ***


Get Component URIs
    [Documentation]  Get URIs for given component from given URIs
    ...  and return as a list.
    [Arguments]  ${component_name}  ${uri_list}=${SYSTEM_URI}

    # A sample result returned for the "cpu" component:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu", "dimm", etc.).
    # uri_list          URI list. Example :
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0,
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1,
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/gv100card5,
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/fan1,
    #     /xyz/openbmc_project/inventory/system/chassis/motherboard/fan0,

    ${component_uris}=  Get Matches  ${uri_list}
    ...  regexp=^.*[0-9a-z_].${component_name}[0-9]*$
    [Return]  ${component_uris}


Get FRU Info Via IPMI
    [Documentation]  Return IPMI FRU field info of given component.
    [Arguments]  ${component_name}  ${field_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu", "dimm", etc.).
    # field_name        FRU field name (e.g. "Board Mfg", "Board Product").

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
    #
    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090288
    #  Board Part Number     : 02AA860


    ${fru_print_output}=  Get FRU Info

    ${index}=  Set Variable  0

    # Get index of FRU section of given component.
    :FOR  ${fru_component_section}  IN  @{fru_print_output}
    \  ${fru_component_section}=  Get From List  ${fru_print_output}  ${index}
    \  ${status}=  Run Keyword And Return Status  Should Contain
    \  ...  ${fru_component_section['fru_device_description']}
    \  ...  ${component_name}
    \  Exit For Loop If  '${status}' == '${True}'
    \  ${index}=  Evaluate  ${index} + 1

    ${fru_component_section}=  Get From List  ${fru_print_output}  ${index}

    # Convert field name to lower case and replace " " with "_".
    # e.g. 'Board Product' to 'board_product'.
    ${field_name}=  Replace String  ${field_name}  ${SPACE}  _
    ${field_name}=  Convert To Lowercase  ${field_name}

    ${field_value}=
    ...  Get From Dictionary  ${fru_component_section}  ${field_name}

    [return]  ${field_value}


Verify FRU
    [Documentation]  Verify IPMI FRU info of given component.
    ...  with REST.
    [Arguments]  ${component_name}  ${field1}=${EMPTY}  ${field2}=${EMPTY}
    ...  ${field3}=${EMPTY}  ${field4}=${EMPTY}  ${field5}=${EMPTY}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu0", "dimm0", etc.).
    # field1            FRU field name (e.g. Board Mfg, Board Product).

    # Example of FRU info via IPMI
    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090288
    #  Board Part Number     : 02AA860


    @{field_list}=  Create List  ${field1}  ${field2}  ${field3}  ${field4}  ${field5}
    : FOR  ${element}  IN  @{field_list}
    \  Run Keyword If  '${element}' != '${EMPTY}'
    \  ...    Verify FRU Field  ${component_name}  ${element}


Verify FRU Field
    [Documentation]  Verify IPMI FRU field info of given component.
    ...  with REST.
    [Arguments]  ${component_name}  ${field_name}

    # component_name    Component name (e.g. "cpu0", "dimm0", etc.).
    # field_name        FRU field name (e.g. Board Mfg, Board Product, etc.).

    ${rest_name}  ${ipmi_name}=
    ...  Run Keyword If  '${field_name}' == 'Board Mfg'
    ...  Set Variable  Manufacturer  Board Mfg
    ...  ELSE IF  '${field_name}' == 'Board Product'
    ...  Set Variable  PrettyName  Board Product
    ...  ELSE IF  '${field_name}' == 'Board Serial'
    ...  Set Variable  SerialNumber  Board Serial
    ...  ELSE IF  '${field_name}' == 'Board Part Number'
    ...  Set Variable  PartNumber  Board Part Number

    # Example of inventory info via REST
    #    "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0": {
    #      "BuildDate": "1996-01-01 - 00:00:00",
    #      "Cached": 0,
    #      "FieldReplaceable": 1,
    #      "Functional": 1,
    #      "Manufacturer": "IBM",
    #      "Model": "",
    #      "PartNumber": "02CY211",
    #      "Present": 1,
    #      "PrettyName": "PROCESSOR MODULE",
    #      "SerialNumber": "YA1934302963",
    #      "Version": "22"

    ${rest_output}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component_name}
    ...  ${rest_name}

    # Example of FRU info via IPMI
    # FRU Device Description : cpu1 (ID 2)
    #  Board Mfg Date        : Sun Dec 31 18:00:00 1995
    #  Board Mfg             : IBM
    #  Board Product         : PROCESSOR MODULE
    #  Board Serial          : YA1934090288
    #  Board Part Number     : 02AA860

    ${ipmi_output}=  Get FRU Info Via IPMI  ${component_name}  ${ipmi_name}

    Should Be True  '${rest_output}'  '${ipmi_output}'


Test FRU Info
    [Documentation]  Test FRU information of given component.
    [Arguments]  ${component_name}  ${field1}=${EMPTY}  ${field2}=${EMPTY}
    ...  ${field3}=${EMPTY}  ${field4}=${EMPTY}  ${field5}=${EMPTY}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu", "dimm", etc.).
    # field1            FRU field name (e.g. Board Mfg, Board Product).

    # Example of IPMI FRU print output.
    # FRU Device Description : cpu0 (ID 1)
    # Board Mfg Date        : Sun Dec 31 18:00:00 1995
    # Board Mfg             : IBM
    # Board Product         : PROCESSOR MODULE
    # Board Serial          : YA1934108636
    # Board Part Number     : 02AA862

    ${component_url_list}=  Get Component URIs  ${component_name}
    : FOR  ${uri}  IN  @{component_url_list}
    \  ${component}=  Fetch From Right  ${uri}  motherboard/
    \  Verify FRU  ${component}  ${field1}  ${field2}  ${field3}  ${field4}  ${field5}


Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    REST Power On  stack_mode=skip  quiet=1

    ${uri_list}=  Read Properties  ${OPENBMC_BASE_URI}list
    Set Suite Variable  ${SYSTEM_URI}  ${uri_list}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
