*** Settings ***
Documentation   Suite to test OCC power module.

Resource        ../lib/open_power_utils.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

*** Test Cases ***

Verify OCC Object Count
    [Documentation]  Verify that OCC and inventory entries match.
    [Tags]  Verify_OCC_Object_Count

    # Example:
    # /org/open_power/control/enumerate
    # {
    #    "/org/open_power/control/host0": {},
    #    "/org/open_power/control/occ0": {
    #       "OccActive": 0
    #   },
    # "/org/open_power/control/occ1": {
    #       "OccActive": 0
    #   }
    # }

    # Inventory counterpart cpu's:
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0",
    # "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1",

    ${inventory_count}=  Count Object Entries
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/  cpu*

    Should Be Equal  ${occ_count}  ${inventory_count}
    ...  msg=OCC and inventory entry counts are mismatched.


Verify OCC Active State
    [Documentation]  Check OCC active state.
    [Tags]  Verify_OCC_Active_State

    # Example cpu_list data output:
    #  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0
    #  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu1
    ${cpu_list}=  Get Endpoint Paths
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/  cpu*

    :FOR  ${endpoint_path}  IN  @{cpu_list}
    \  ${is_functional}=  Read Object Attribute  ${endpoint_path}  Functional
    \  Continue For Loop If  ${is_functional} == ${0}
    \  ${num}=  Set Variable  ${endpoint_path[-1]}
    \  ${occ_active}=  Get OCC Active State  ${OPENPOWER_CONTROL}occ${num}
    \  Should Be True  ${occ_active}  msg=OCC ${num} is not active.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the initial test suite setup.
    # - Power off.
    # - Boot Host.

    Smart Power Off
    REST Power On
    Count OCC Object Entry


Count OCC Object Entry
    [Documentation]  Count OCC object entry and set count.

    ${object_count}=  Count Object Entries  ${OPENPOWER_CONTROL}  occ*
    Set Suite Variable  ${occ_count]  ${object_count}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    # - Capture FFDC on test failure.
    # - Delete error logs.
    # - Close all open SSH connections.

    FFDC On Test Case Fail
    Delete Error Logs
    Close All Connections

