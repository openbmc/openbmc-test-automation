*** Settings ***
Documentation       Inventory of hardware resources under systems.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/bmc_redfish_utils.robot
Resource            ../../lib/openbmc_ffdc.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Printn
Test Teardown       Test Teardown Execution

*** Variables ***

# The passing criteria.  Must have at least this many.
${min_num_dimms}   2
${min_num_cpus}    1


*** Test Cases ***

Redfish Systems Inventory Processors
    [Documentation]  Get the number of CPUs that are both OK and Enabled.
    [Tags]  Redfish_Systems_Inventory_Processors
    ${num_cpus}=  Get Num Valid FRUs  Processors
    Rprint Vars  min_num_cpus  num_cpus
    Run Keyword If  ${num_cpus} < ${min_num_cpus}
    ...  Fail  msg=Insufficient CPU count.


Redfish Systems Inventory Memory
    [Documentation]  Get the number of DIMMs that are both OK and Enabled.
    [Tags]  Redfish_Systems_Inventory_Memory
    ${num_dimms}=  Get Num Valid FRUs  Memory
    Rprint Vars  min_num_dimms  num_dimms
    Run Keyword If  ${num_dimms} < ${min_num_dimms}
    ...  Fail  msg=Insufficient DIMM count.


*** Keywords ***
Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do suite case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
