*** Settings ***

Documentation    Test firmware boot side switch using pldmtool.

# Test Procedure:
# 1. Power off the host or post firmware is updated.
# 2. Check the firmware boot side ( login to BMC and execute )
#    Example:
#    pldmtool bios GetBIOSAttributeCurrentValueByHandle -a fw_boot_side
#
#    It should return response either Temp or Perm
# 3. Set the firmware boot side to Temp or Perm accordingly
#    Example:
#    pldmtool bios SetBIOSAttributeCurrentValue -a fw_boot_side -d Temp
#
# 4. Power on
# 5. BMC take reset during power on ( expected )
# 6. Check the system booted to Runtime
# 7. Verify the boot side is still same which was set.

Library          Collections
Library          ../lib/tftp_update_utils.py
Resource         ../lib/bmc_redfish_resource.robot
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

Test Tags       Firmware_Boot_Side

*** Variables ***

# By default 2, to ensure, it performs both Perm and Temp side switch and boot.
${LOOP_COUNT}     2

# This dictionary is for Temp -> Perm or vice versa in the test code.
&{FW_BOOT_SIDE_DICT}  Perm=Temp  Temp=Perm

*** Test Cases ***

Test Firmware Boot Side Using Pldmtool
    [Documentation]   Power off the host , set the firmware boot side via pldmtool,
    ...               power on the host and confirm the fw_boot_side attribute is
    ...               still set.
    [Tags]  Test_Firmware_Boot_Side_Using_Pldmtool
    [Template]  Firmware Side Switch Power On Loop

    # iteration
    ${LOOP_COUNT}


*** Keywords ***

Firmware Side Switch Power On Loop
    [Documentation]   Number of iteration, test should perform switch side and boot.
    [Arguments]  ${iteration}

    # Description of argument(s):
    # iteration      Number of switch it needs to perform.

    FOR  ${count}  IN RANGE  0  ${iteration}
        Print Timen  The Current Loop Count is ${count} of ${iteration}

        # Get the current system state before BMC reset.
        ${state}=  Get Pre Reboot State

        Redfish Power Off  stack_mode=skip

        ${cur_boot_side}=  PLDM Get BIOS Attribute  fw_boot_side
        Print Timen  Current BIOS attribute fw_boot_side: ${cur_boot_side}

        ${next_boot_side}=  Set Variable  ${FW_BOOT_SIDE_DICT["${cur_boot_side["CurrentValue"]}"]}
        Print Timen  Set BIOS attribute fw_boot_side: ${next_boot_side}
        PLDM Set BIOS Attribute  fw_boot_side  ${next_boot_side}

        ${cur_boot_side}=  PLDM Get BIOS Attribute  fw_boot_side
        Print Timen   Next boot will apply BIOS attribute fw_boot_side: ${cur_boot_side}

        Print Timen  Perform power on operation and expect BMC to take reset.
        Redfish Power Operation  On
        Print Timen  Wait for the BMC to take reset and come back online.
        Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}  wait_state_check=0

        Print Timen  BMC rebooted, wait for host to boot to Runtime.
        # Post BMC reset, host should auto power on back to runtime.
        Wait Until Keyword Succeeds  ${power_on_timeout}  20 sec
        ...  Is Boot Progress Runtime Matched

        # Verify the system is booting up with the new fw_boot_side set.
        ${cur_boot_side}=  PLDM Get BIOS Attribute  fw_boot_side
        Should Be Equal As Strings  ${cur_boot_side["CurrentValue"]}  ${next_boot_side}
        Print Timen  Current: ${cur_boot_side["CurrentValue"]} and set side: ${next_boot_side} are same.
    END


Is Boot Progress Runtime Matched
    [Documentation]  Get BootProgress state and expect boot state mismatch.

    # Match any of the BootProgress state SystemHardwareInitializationComplete|OSBootStarted|OSRunning
    ${boot_progress}  ${host_state}=  Redfish Get Boot Progress
    Should Contain Any  ${boot_progress}  SystemHardwareInitializationComplete  OSBootStarted  OSRunning
