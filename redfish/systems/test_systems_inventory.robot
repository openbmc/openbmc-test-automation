*** Settings ***
Documentation       Inventory of hardware resources under systems.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Teardown       Test Teardown Execution

*** Variables ***

# The passing criteria.  Must have at least this many.
${min_count_dimm}   2
${min_count_cpu}    1


*** Test Cases ***

Get Processor Inventory Via Redfish And Verify
    [Documentation]  Get the number of CPUs that are functional and enabled.
    [Tags]  Get_Processor_Inventory_Via_Redfish_And_Verify

    Count System Inventory Items  Processors  ${min_count_cpu}  CPUs


Get Memory Inventory Via Redfish And Verify
    [Documentation]  Get the number of DIMMs that are functional and enabled.
    [Tags]  Get_Memory_Inventory_Via_Redfish_And_Verify

    Count System Inventory Items  Memory  ${min_count_dimm}  DIMMs


Get Serial And Verify Not Blank

    ${SerialNumber}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Systems/system  SerialNumber
    Rprint Vars  SerialNumber
    Should Not Be Empty  ${SerialNumber}  msg=SerialNumber attribute is empty.


Get Model And Verify Not Blank

    ${Model}=  Redfish.Get Attribute
    ...  ${REDFISH_BASE_URI}Systems/system  Model
    Rprint Vars  Model
    Should Not Be Empty  ${Model}  msg=Model attribute is empty.


*** Keywords ***


Count System Inventory Items
    [Arguments]  ${general_resource}  ${min_item_count}  ${item_name}

    # Description of Argument(s):
    # general_resource  The name of the location under Systems/system where
    #                   individual hardware items are found.  Specifically,
    #                   /redfish/v1/Systems/system/${general_resource}.
    # min_item_count    The minimum acceptable number of hardware items found
    #                   within the specified general_resource.
    # item_name         The generic name of the items, for example "DIMMs"
    #                   or "CPUs".

    Log To Console  Checking number of ${item_name}.

    # num_found is the number of items under the general_resource that
    # report as "OK" and "Enabled".
    ${num_found}=  Get Num Valid FRUs  ${general_resource}
    Rprint Vars  num_found

    Run Keyword If  ${num_found} < ${min_item_count}  Fail
    ...  msg=Expecting at least ${min_item_count} ${item_name}.


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
