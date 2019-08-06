*** Settings ***
Documentation       Inventory of hardware FRUs under redfish/systems.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Library             ../../lib/gen_robot_valid.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
####Test Teardown       Test Teardown Execution

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

    Rprint Vars  num_cpu_uris  min_num_cpus
    Valid Range  num_cpu_uris  ${min_num_cpus}


Get Available CPU Cores And Verify
    [Documentation]  Get the total number of cores in the system and
    ...              verify that it is at or above the minimum.
    [Tags]  Get_Available_CPU_Cores_And_Verify

    ${total_num_cores}=  Set Variable  ${0}

    :FOR  ${processor}  IN  @{cpu_uris}
        ${is_functional}=  Check If FRU Is Functional  ${processor}
        Run Keyword If  not ${is_functional}  Continue For Loop
        ${processor_cores}=   Get CPU TotalCores  ${processor}
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

    :FOR  ${powersupply_uri}  IN  @{powersupply_uris}
        ${is_functional}=  Check If FRU Is Functional  ${powersupply_uri}
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


Count GPUs Having OK Health
    [Documentation]  Count number of GPUs that report Health = "OK".
    ...              This number should match the number of GPU URIs.
    [Tags]  Count_GPUs_Having_OK_Health

    # Any GPU that has {status['Health']}" == "OK is counted.

    Rprint Vars  num_gpu_uris

    ${total_num_ok_gpus}=  Set Variable  ${0}

    :FOR  ${gpu_uri}  IN  @{gpu_uris}
        # Example uri: /redfish/v1/Systems/system/Processors/gv100card0.
        ${status}=  Redfish.Get Attribute  ${gpu_uri}  Status
        Run Keyword If  not "${status['Health']}" == "OK"  Continue For Loop
        ${total_num_ok_gpus}=  Evaluate  $total_num_ok_gpus + ${1}
    END

    Rprint Vars   total_num_ok_gpus

    # Fail if total_num_ok_gpus does not match the number of GPU URIs.
    Valid Range  total_num_ok_gpus  ${num_gpu_uris}


GPU State Check
    [Documentation]  Check the State of the GPUs in the system. State
    ...              should be "Absent", "Enabled", or "UnavailableOffline".
    ...              Fail if not one of these values.
    [Tags]  GPU_State_Check.

    :FOR  ${gpu_uri}  IN  @{gpu_uris}
        # Example uri: /redfish/v1/Systems/system/Processors/gv100card0.
        ${status}=  Redfish.Get Attribute  ${gpu_uri}  Status
        ${state}=  Set Variable  ${status['State']}
        ${good_state}=  Evaluate
        ...  any(x in '${state}' for x in ('Absent', 'Enabled', 'UnavailableOffline'))
        Rprint Vars  gpu_uri  state
        Run Keyword If  not ${good_state}  Fail
        ...  msg=GPU State is not Absent, Enabled, or UnavailableOffline.
    END


*** Keywords ***


Get Inventory URIs
    [Documentation]  Get and return a tuple of lists of URIs for CPU,
    ...              GPU and PowerSupplies.

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

    ${chassis_uris}=  Redfish_Utils.Get Member List  ${REDFISH_CHASSIS_URI}
    # Example of chassis_uris:
    # /redfish/v1/Chassis/chasis
    # /redfish/v1/Chassis/motherboard
    # /redfish/v1/Chassis/powersupply0
    # /redfish/v1/Chassis/powersupply1

    ${powersupply_uris}=  Get Matches  ${chassis_uris}  *powersupp*

    [Return]  ${cpu_uris}  ${gpu_uris}  ${powersupply_uris}


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
    [Arguments]  ${powersupply_uri}

    # Description of Argument(s):
    # powersupply_uri    The Redfish URI of a power supply
    #                    (e.g. "/redfish/v1/Chassis/powersupply0").

    ${status}=  Redfish.Get Attribute  ${powersupply_uri}  Status

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

    Redfish Power On  stack_mode=skip
    Redfish.Login

    ${cpu_uris}  ${gpu_uris}  ${powersupply_uris}=  Get Inventory URIs

    Set Suite Variable  ${cpu_uris}
    Set Suite Variable  ${gpu_uris}
    Set Suite Variable  ${powersupply_uris}

    ${num_cpu_uris}=  Get Length  ${cpu_uris}
    ${num_gpu_uris}=  Get Length  ${gpu_uris}

    Set Suite Variable  ${num_cpu_uris}
    Set Suite Variable  ${num_gpu_uris}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
