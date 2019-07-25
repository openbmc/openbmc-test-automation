*** Settings ***
Documentation       Inventory of hardware FRUs under redfish/systems.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Teardown       Test Teardown Execution

*** Variables ***

# The passing criteria.  Must have at least this many.
${min_num_dimms}   2
${min_num_cpus}    1
${min_num_cores}   18
${min_num_powersupplies}  1


*** Test Cases ***


Get Processor Inventory Via Redfish And Verify
    [Documentation]  Get the number of CPUs that are functional and enabled.
    [Tags]  Get_Processor_Inventory_Via_Redfish_And_Verify

    ${num_valid_cpus}=  Get length  ${cpu_uris}

    Run Keyword If  ${num_valid_cpus} < ${min_num_cpus}
    ...  Fail  Too few CPUs found, found only ${num_valid_cpus}.


Get Available CPU Cores And Verify
    [Documentation]  Get the total number of cores in the system and
    ...              verify that it is at or above the minimum.
    [Tags]  Get_Available_CPU_Cores_And_Verify

    ${total_num_cores}=  Set Variable  ${0}

    :FOR  ${processor}  IN  @{cpu_uris}
        ${is_functional}=  Check If FRU Is Functional  ${processor}
        ${processor_cores}=  Run Keyword If  ${is_functional} == ${1}
         ...     Get CPU TotalCores  ${processor}
         ...  ELSE
         ...     Set Variable  ${0}
        ${total_num_cores}=  Evaluate  $total_num_cores + $processor_cores
    END

    Rprint Vars  total_num_cores

    Run Keyword If  ${total_num_cores} < ${min_num_cores}
    ...  Fail  Too few CPU cores found.


Get Memory Inventory Via Redfish And Verify
    [Documentation]  Get the number of DIMMs that are functional and enabled.
    [Tags]  Get_Memory_Inventory_Via_Redfish_And_Verify

    Verify FRU Inventory Minimums  Memory  ${min_num_dimms}


Get System Serial And Verify Populated
    [Documentation]  Check that the System SerialNumber is non-blank.
    [Tags]  Get_System_Serial_And_Verify_Populated

    ${serial_number}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  SerialNumber
    Rvalid Value  serial_number
    Rprint Vars  serial_number


Get Model And Verify Populated
    [Documentation]  Check that the Model is non-blank.
    [Tags]  Get_Model_And_Verify_Populated

    ${model}=  Redfish.Get Attribute  ${SYSTEM_BASE_URI}  Model
    Rvalid Value  model
    Rprint Vars  model


Get Available Power Supplies And Verify
    [Documentation]  Get the number of functional power supplies and
    ...              verify that it is at or above the minimum.
    [Tags]  Get_Available_Power_Supplies_And_Verify

    ${total_num_supplies}=  Set Variable  ${0}

    :FOR  ${chassis_uri}  IN  @{powersupply_uris}
        ${is_functional}=  Check If FRU Is Functional  ${chassis_uri}
        ${total_num_supplies}=  Evaluate  $total_num_supplies + $is_functional
    END

    Rprint Vars  total_num_supplies

    Run Keyword If  ${total_num_supplies} < ${min_num_powersupplies}
    ...  Fail  Too few power supplies found.


Get Motherboard Serial And Verify Populated
    [Documentation]  Check that the Motherboard SerialNumber is non-blank.
    [Tags]  Get_Motherboard_Serial_And_Verify_Populated

    ${serial_number}=  Redfish.Get Attribute
    ...  ${REDFISH_CHASSIS_URI}motherboard  SerialNumber
    Rvalid Value  serial_number
    Rprint Vars  serial_number


Get GPU Inventory Via Redfish
    [Documentation]  Get the number of GPUs.
    [Tags]  Get_GPU_Inventory_Via_Redfish

    # There may be 0-6 GPUs in a system.
    # GPUs may have one of three states:
    # "Absent", "Enabled", or "UnavailableOffline".
    # Or GPUs may not be listed at all under the URI
    # /redfish/v1/Systems/system/Processors.
    # So for now, only print the total of GPUs present.

    ${num_valid_gpus}=  Get length  ${gpu_uris}

    Rprint Vars  num_valid_gpus


*** Keywords ***


Get Processor URIs

    @{cpu_uris}=  Create List
    @{gpu_uris}=  Create List
    @{powersupply_uris}=  Create List

    ${processor_uris}=
    ...  Redfish_Utils.Get Member List  ${SYSTEM_BASE_URI}Processors
    # Example of processor_uris:
    # /redfish/v1/Systems/system/Processors/cpu0
    # /redfish/v1/Systems/system/Processors/cpu1
    # /redfish/v1/Systems/system/Processors/gv100card0
    # /redfish/v1/Systems/system/Processors/gv100card1
    # /redfish/v1/Systems/system/Processors/gv100card2
    # /redfish/v1/Systems/system/Processors/gv100card3
    # /redfish/v1/Systems/system/Processors/gv100card4

    ${cpu_uris}=  Get Matches  ${processor_uris}  *cpu*
    ${gpu_uris}=  Get Matches  ${processor_uris}  *gv*

    Set Suite Variable  ${cpu_uris}  children=true
    Set Suite Variable  ${gpu_uris}  children=true

    ${chassis_uris}=  Redfish_Utils.Get Member List  ${REDFISH_CHASSIS_URI}
    # Example of chassis_uris:
    # /redfish/v1/Chassis/chasis
    # /redfish/v1/Chassis/motherboard
    # /redfish/v1/Chassis/powersupply0
    # /redfish/v1/Chassis/powersupply1

    ${powersupply_uris}=  Get Matches  ${chassis_uris}  *powersupp*
    Set Suite Variable  ${powersupply_uris}  children=true


Get CPU TotalCores
    [Documentation]  Return the number of the CPU's reported TotalCores.
    ...              Return 0 if this attribute is missing or NONE.
    [Arguments]      ${processor}

    # Description of Argument(s):
    # chassis_uri    The Redfish uri of a power supply

    ${num_cores}=  Redfish.Get Attribute  ${processor}  TotalCores
    Return From Keyword If  ${num_cores} is ${NONE}  ${0}
    [Return]  ${num_cores}


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


Check If FRU Is Functional
    [Documentation]  Return 1 if a power supply is OK and either
    ...   Enabled or StandbyOffline.  Return 0 otherwise.
    [Arguments]  ${chassis_uri}

    # Description of Argument(s):
    # chassis_uri    The Redfish uri of a power supply
    #                (e.g. "/redfish/v1/Chassis/powersupply0").

    ${status}=  Redfish.Get Attribute  ${chassis_uri}  Status

    ${state_check}=  Set Variable  "${status['Health']}" == "OK" and
    ${state_check}=  Catenate  ${state_check}  ("${status['State']}" == "StandbyOffline" or
    ${state_check}=  Catenate  ${state_check}  "${status['State']}" == "Enabled")

    ${is_functional}=  Run Keyword If  ${state_check}
    ...     Set Variable  ${1}
    ...  ELSE
    ...     Set Variable  ${0}

    [Return]  ${is_functional}


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Get Processor URIs
    Printn


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
