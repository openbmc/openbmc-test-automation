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

    ${num_cpus}=  Count OK And Enabled  cpu  Processors
    Rprint Vars  num_cpus
    Run Keyword If  ${num_cpus} < ${min_count_cpu}
    ...  Fail  msg=Insufficient CPU count.


Get Memory Inventory Via Redfish And Verify
    [Documentation]  Get the number of DIMMs that are functional and enabled.
    [Tags]  Get_Memory_Inventory_Via_Redfish_And_Verify

    ${num_dimms}=  Count OK And Enabled  dimm  Memory
    Rprint Vars  num_dimms
    Run Keyword If  ${num_dimms} < ${min_count_dimm}
    ...  Fail  msg=Insufficient DIMM count.


*** Keywords ***


Count OK And Enabled
    [Documentation]  Return the number of items that are OK and Enabled.
    [Arguments]  ${item}  ${general_resource}

    # Count the number of OK and Enabled items within a general_resource.
    # Example:   Count the number of cpus under
    # /redfish/v1/Systems/system/Processors

    # Description of Argument(s):
    # item              A hardware item within a general resource that has
    #                   "Health" and "State" attributes,  E.g. "cpu" or "dimm".
    # general_resource  A systems resource type that contains these items, such
    #                   as "Processors", or "Memory".

    ${num_items}=  Set Variable  0

    ${resources}=  Redfish_Utils.List Request
    ...  /redfish/v1/Systems/system/${general_resource}
    #  Example response if general_resource = "Memory":
    #   /redfish/v1/Systems/system/Memory
    #   /redfish/v1/Systems/system/Memory/dimm0
    #   /redfish/v1/Systems/system/Memory/dimm1
    #   /redfish/v1/Systems/system/Memory/dimm2
    #   etc.
    #  Example response if general_resource = "Processors":
    #   /redfish/v1/Systems/system/Processors
    #   /redfish/v1/Systems/system/Processors/cpu0
    #   /redfish/v1/Systems/system/Processors/cpu1

    :FOR  ${resource}  IN  @{resources}
    \  ${valid}=  Is Item Enabled And Health Ok  ${item}  ${resource}
    \  ${increment}=  Run Keyword If
    ...  ${valid}  Set Variable  ${1}  ELSE  Set Variable  ${0}
    \  ${num_items}=  Evaluate  ${num_items}+${increment}

    [Return]  ${num_items}


Is Item Enabled And Health Ok
    [Documentation]  Return ${True} if the item is OK and Enabled.
    [Arguments]  ${item}  ${resource}

    # Description of Argument(s):
    # item          A hardware item within a general resource that has
    #               "Health" and "State" attributes,  E.g. "dimm".
    # resource      An individual resource to check, for example,
    #               "/redfish/v1/Systems/system/Memory/dimm0".

    # Return if item is not in the resource string.  This
    # might be a top-level resource which is not a specific hardware item.
    # Example:  Return if resource = "/redfish/v1/Systems/system/Memory" but
    # continue if resource = "/redfish/v1/Systems/system/Memory/dimm1".
    ${valid_parameter}=  Evaluate  "${item}" in "${resource}"
    Return From Keyword If  not ${valid_parameter}  ${False}

    ${status_detail}=  Redfish.Get
    ...  ${resource}  valid_status_codes=[${HTTP_OK}]

    ${health}=   Set Variable  ${status_detail.dict["Status"]["Health"]}
    ${state}=  Set Variable  ${status_detail.dict["Status"]["State"]}

    Return From Keyword If
    ...  "${health}" == "OK" and "${state}" == "Enabled"  ${True}

    [Return]  ${False}


Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout


Suite Setup Execution
    [Documentation]  Do test case setup tasks.

    Redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
