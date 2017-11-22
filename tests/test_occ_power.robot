*** Settings ***
Documentation   Suite to test OCC power module.

Resource        ../lib/open_power_utils.robot
Resource        ../lib/boot_utils.robot
Resource        ../lib/state_manager.robot
Resource        ../lib/openbmc_ffdc.robot
Resource        ../lib/utils.robot

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

Verify When Host Is Booted
    [Documentation]  Verify OCC state when host is booted.
    [Tags]  Verify_When_Host_Is_Booted

    Verify OCC State  ${1}

Verify OCC State After Host Reboot
    [Documentation]  Verify OCC state and count after host reboot.
    [Tags]  Verify_OCC_State_After_Host_Reboot

    ${occ_count_before} =  Count OCC Object Entry
    Verify OCC State  ${1}
    REST OBMC Reboot (run)  stack_mode=normal  quiet=1
    Verify OCC State  ${1}
    ${occ_count_after} =  Count OCC Object Entry
    Should be Equal  ${occ_count_before}  ${occ_count_after}

Verify OCC State After BMC Reset
    [Documentation]  Verify OCC state and count after BMC reset.
    [Tags]  Verify_OCC_State_After_BMC_Reset

    ${occ_count_before} =  Count OCC Object Entry
    OBMC Reboot (run)
    Verify OCC State  ${1}
    ${occ_count_after} =  Count OCC Object Entry
    Should be Equal  ${occ_count_before}  ${occ_count_after}

Verify OCC State At Standby
    [Documentation]  Verify OCC state at standby.
    [Tags]  Verify_OCC_State_At_Standby

    REST Power Off  stack_mode=normal
    Verify OCC State  ${0}

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
    Delete All Error Logs
    Close All Connections

Verify OCC State
    [Documentation]  Check OCC active state.
    [Arguments]  ${expected_occ_active}=${1}
    # Description of Argument(s):
    # expected_occ_active  The expected occ_active value (i.e. 1/0).

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
    \  Should Be Equal  ${occ_active}  ${expected_occ_active}  msg=OCC not in right state
