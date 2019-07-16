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

    Verify FRU Inventory Minimums  Processors  ${min_num_cpus}


Get Available CPU Cores And Verify
    [Documentation]  Get the total number of cores in the system.
    [Tags]  Get_Available_CPU_Cores_And_Verify

    ${total_num_cores}=  Set Variable  ${0}

    ${processor_uris}=
    ...  Redfish_Utils.Get Member List  ${SYSTEM_BASE_URI}Processors
    # Example of processor_uris:
    # /redfish/v1/Systems/system/Processors/cpu0
    # /redfish/v1/Systems/system/Processors/cpu1

    :FOR  ${processor}  IN  @{processor_uris}
        # If the status of the processor is "OK" and "Enabled", get its number
        # of cores.
        ${status}=  Redfish.Get Attribute  ${processor}  Status
        ${processor_cores}=  Run Keyword If
        ...  "${status['Health']}" == "OK" and "${status['State']}" == "Enabled"
        ...     Redfish.Get Attribute  ${processor}  TotalCores
        ...  ELSE
        ...     Set Variable  ${0}
        # Add the number of processor_cores to the total.
        ${total_num_cores}=  Evaluate  $total_num_cores + $processor_cores
    END

    Rprint Vars  total_num_cores
    Run Keyword If  ${total_num_cores} < ${min_num_cores}
    ...  Fail  Too few CPU cores found.


Get Memory Inventory Via Redfish And Verify
    [Documentation]  Get the number of DIMMs that are functional and enabled.
    [Tags]  Get_Memory_Inventory_Via_Redfish_And_Verify

    Verify FRU Inventory Minimums  Memory  ${min_num_dimms}


Get Serial And Verify Populated
    [Documentation]  Check that the SerialNumber is non-blank.
    [Tags]  Get_Serial_And_Verify_Populated

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
    [Documentation]  Get the number of functional power supplies.
    [Tags]  Get_Available_Power_Supplies_And_Verify

    ${total_num_supplies}=  Set Variable  ${0}

    ${processor_uris}=  Redfish_Utils.Get Member List  /redfish/v1/Chassis
    :FOR  ${processor}  IN  @{processor_uris}
        ${is_supply}=  Evaluate  "powersupply" in $processor
        ${is_functional}=  Run Keyword If  ${is_supply}
        ...    Check If Supply Is Functional  ${processor}
        ...  ELSE
        ...    Set Variable  ${0}
        ${total_num_supplies}=  Evaluate  $total_num_supplies + $is_functional
    END

    Rprint Vars  total_num_supplies

    Run Keyword If  ${total_num_supplies} < ${min_num_powersupplies}
    ...  Fail  Too few power supplies found.


*** Keywords ***


Verify FRU Inventory Minimums
    [Documentation]  Verify a minimum number of FRUs.
    [Arguments]  ${fru_type}  ${min_num_frus}

    # Description of Argument(s):
    # fru_type      The type of FRU (e.g. "Processors", "Memory", etc.).
    # min_num_frus  The minimum acceptable number of FRUs found.

    # A valid FRU  will have a "State" key of "Enabled" and a "Health" key
    # of "OK".

    ${status}  ${num_valid_frus}=  Run Key U  Get Num Valid FRUs \ ${fru_type}

    Return From Keyword If  ${num_valid_frus} >= ${min_num_frus}
    Fail  Too few "${fru_type}" FRUs found, found only ${num_valid_frus}.


Check If Supply is Functional
    [Documentation]  Return 1 if a power supply is OK and Enabled, 0 otherwise.
    [Arguments]  ${supply_uri}

    # Description of Argument(s):
    # supply_uri    The Redfish uri of a power supply
    #               (e.g. "/redfish/v1/Chassis/powersupply0").

    ${status}=  Redfish.Get Attribute  ${supply_uri}  Status

    ${is_functional}=  Run Keyword If
    ...  "${status['Health']}" == "OK" and "${status['State']}" == "Enabled"
    ...     Set Variable  ${1}
    ...  ELSE
    ...     Set Variable  ${0]

    [Return]  ${is_functional}


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login
    Printn


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
