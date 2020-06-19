*** Settings ***
Documentation       Inventory of hardware FRUs under redfish.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution

*** Variables ***

# The passing criteria.  Must have at least this many.
${min_num_dimms}   2
${min_num_cpus}    1
${min_num_cores}   18
${min_num_power_supplies}  1


*** Test Cases ***


Verify CPU And Core Count
    [Documentation]  Get the total number of CPUs and cores in the system.
    ...              Verify counts are above minimums.
    [Tags]  Verify_CPU_And_Core_Count

    # Select only CPUs with Health = "OK".
    ${cpus_ok}=  Filter Struct  ${cpu_info}  [('Health', 'OK')]
    ${num_cpus}=   Get Length  ${cpus_ok}

    Rprint Vars  num_cpus  min_num_cpus

    # Assert that num_cpus is greater than or equal to min_num_cpus.
    Valid Range  num_cpus  ${min_num_cpus}

    # Get the number of cores.
    ${total_num_cores}=  Set Variable  ${0}
    FOR  ${cpu}  IN  @{cpus_ok}
        ${cores}=   Get CPU TotalCores  ${cpu}
        ${total_num_cores}=  Evaluate  $total_num_cores + ${cores}
    END

    Rprint Vars  total_num_cores  min_num_cores

    # Assert that total_num_cores is greater than or equal to
    # min_num_cores.
    Valid Range  total_num_cores  ${min_num_cores}


Get Memory Inventory Via Redfish And Verify
    [Documentation]  Get the number of DIMMs that are functional and enabled.
    [Tags]  Get_Memory_Inventory_Via_Redfish_And_Verify

    Verify FRU Inventory Minimums  Memory  ${min_num_dimms}


Get Memory Summary State And Verify Enabled
    [Documentation]  Check that the state of the MemorySummary attribute
    ...              under /redfish/v1/Systems/system is 'Enabled'.
    [Tags]  Get_Memory_Summary_State_And_Verify_Enabled

    ${status}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  MemorySummary
    ${memory_summary_state}=  Set Variable  ${status['Status']['State']}
    Rprint Vars  memory_summary_state

    Should Be Equal As Strings  Enabled  ${memory_summary_state}
    ...  msg=MemorySummary State is not 'Enabled'.


Get System Serial And Verify Populated
    [Documentation]  Check that the System SerialNumber is non-blank.
    [Tags]  Get_System_Serial_And_Verify_Populated

    ${serial_number}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  SerialNumber
    Valid Value  serial_number
    Rprint Vars  serial_number


Get Model And Verify Populated
    [Documentation]  Check that the Model is non-blank.
    [Tags]  Get_Model_And_Verify_Populated

    ${model}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  Model
    Valid Value  model
    Rprint Vars  model


Get Available Power Supplies And Verify
    [Documentation]  Get the number of functional power supplies and
    ...              verify that it is at or above the minimum.
    [Tags]  Get_Available_Power_Supplies_And_Verify

    # Select only power supplies with Health = "OK".
    ${power_supplies_ok}=  Filter Struct  ${power_supplies}  [('Health', 'OK')]

    # Count the power supplies that are Enabled or StandbyOffline.
    ${total_num_supplies}=  Set Variable  ${0}
    FOR  ${power_supply}  IN  @{power_supplies_ok}
        # Example of power_supply:
        # power_supply = {'@odata.id': '/redfish/v1/Chassis/chassis/Power#/PowerSupplies/0',
        # 'Manufacturer': '', 'MemberId': 'powersupply0', 'Model': '2100', 'Name':
        # 'powersupply0', 'PartNumber': 'PNPWR123', 'PowerInputWatts': 394.0,
        # 'SerialNumber': '75B12W', 'Status': {'Health': 'OK', 'State': 'Enabled'}}
        ${state}=  Set Variable  ${power_supply['Status']['State']}
        ${good_state}=  Evaluate
        ...  any(x in '${state}' for x in ('Enabled', 'StandbyOffline'))
        Run Keyword If  not ${good_state}  Continue For Loop
        ${total_num_supplies}=  Evaluate  $total_num_supplies + ${1}
    END

    Rprint Vars  total_num_supplies  min_num_power_supplies

    Valid Range  total_num_supplies  ${min_num_power_supplies}


Get Motherboard Serial And Verify Populated
    [Documentation]  Check that the Motherboard SerialNumber is non-blank.
    [Tags]  Get_Motherboard_Serial_And_Verify_Populated

    ${serial_number}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_URI}motherboard  SerialNumber
    Valid Value  serial_number
    Rprint Vars  serial_number


Verify Motherboard Manufacturer Field Value Populated
    [Documentation]  Check that the Motherboard manufacturer is non-blank.
    [Tags]  Verify_Motherboard_Manufacturer_Field_Value_Populated

    ${motherboard_manufacturer}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_URI}motherboard  Manufacturer
    Valid Value  motherboard_manufacturer


Verify Motherboard Partnumber Field Value Populated
    [Documentation]  Check that the Motherboard partnumber is non-blank.
    [Tags]  Verify_Motherboard_Partnumber_Field_Value_Populated

    ${motherboard_part_number}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_URI}motherboard  PartNumber
    Valid Value  motherboard_part_number


Check GPU States When Power On
    [Documentation]  Check the State of each of the GPUs
    ...              in the system.  A system may have 0-6 GPUs.
    [Tags]  Check_GPU_States_When_Power_On

    # System was powered-on in Suite Setup.
    GPU State Check


Check GPU States When Power Off
    [Documentation]  Check the State of the GPUs when power is Off.
    [Tags]  Check_GPU_States_When_Power_Off

    Redfish Power Off
    GPU State Check


*** Keywords ***


Get CPU TotalCores
    [Documentation]  Return the TotalCores of a CPU.
    ...              Return 0 if this attribute is missing or NONE.
    [Arguments]      ${processor}

    # Description of Argument(s):
    # processor     The Redfish URI of a CPU (e.g.
    #               "/redfish/v1/Systems/system/Processors/cpu0").

    ${total_cores}=  Redfish.Get Attribute  ${processor}  TotalCores
    Return From Keyword If  ${total_cores} is ${NONE}  ${0}
    [Return]  ${total_cores}


GPU State Check
    [Documentation]  The state of every "OK" GPU should be
    ...              "Absent", "Enabled", or "UnavailableOffline".

    # Select only GPUs with Health = "OK".
    ${gpus_ok}=  Filter Struct  ${gpu_info}  [('Health', 'OK')]

    FOR  ${gpu}  IN  @{gpus_ok}
        ${status}=  Redfish.Get Attribute  ${gpu}  Status
        ${state}=  Set Variable  ${status['State']}
        ${good_state}=  Evaluate
        ...  any(x in '${state}' for x in ('Absent', 'Enabled', 'UnavailableOffline'))
        Rprint Vars  gpu  state
        Run Keyword If  not ${good_state}  Fail
        ...  msg=GPU State is not Absent, Enabled, or UnavailableOffline.
    END


Get Inventory URIs
    [Documentation]  Get and return a tuple of lists of URIs for CPU,
    ...              GPU and PowerSupplies.

    ${processor_info}=  Redfish_Utils.Enumerate Request
    ...  ${SYSTEM_BASE_URI}Processors  return_json=0

    ${cpu_info}=  Filter Struct  ${processor_info}
    ...  [('ProcessorType', 'CPU')]  regex=1

    ${gpu_info}=  Filter Struct  ${processor_info}
    ...  [('ProcessorType', 'Accelerator')]  regex=1

    ${power_supplies}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_POWER_URI}  PowerSupplies

    [Return]  ${cpu_info}  ${gpu_info}  ${power_supplies}


Verify FRU Inventory Minimums
    [Documentation]  Verify a minimum number of FRUs.
    [Arguments]  ${fru_type}  ${min_num_frus}

    # Description of Argument(s):
    # fru_type      The type of FRU (e.g. "Processors", "Memory", etc.).
    # min_num_frus  The minimum acceptable number of FRUs found.

    # A valid FRU  will have a "State" key of "Enabled" and a "Health" key
    # of "OK".

    ${status}  ${num_valid_frus}=  Run Key U  Get Num Valid FRUs \ ${fru_type}

    Rprint Vars  fru_type  num_valid_frus  min_num_frus

    Return From Keyword If  ${num_valid_frus} >= ${min_num_frus}
    Fail  Too few "${fru_type}" FRUs found, found only ${num_valid_frus}.


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Redfish Power On  stack_mode=skip

    ${cpu_info}  ${gpu_info}  ${power_supplies}=  Get Inventory URIs

    Set Suite Variable  ${cpu_info}
    Set Suite Variable  ${gpu_info}
    Set Suite Variable  ${power_supplies}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
