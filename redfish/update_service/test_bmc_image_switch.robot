*** Settings ***
Documentation            Redfish test to switch image sides and boot.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Library                  ../../lib/tftp_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Run Keyword And Ignore Error  Redfish.Logout
Test Teardown            FFDC On Test Case Fail

Force Tags               Bmc_Image_Switch

*** Variables ***

# Switch iteration count. By default it does only 2 switch.
# User can input -v LOOP_COUNT:n  to drive the switch back and forth for
# nth iteration.
${LOOP_COUNT}    ${2}

*** Test Cases ***

Test Firmware Image Switch Without Powering Host
    [Documentation]  Switch image at host powered off.
    [Tags]  Test_Firmware_Image_Switch_Without_Powering_Host
    [Template]  Firmware Switch Loop

    # iteration          power_on
    ${LOOP_COUNT}        NO


Test Firmware Image Switch And Power On Host
    [Documentation]  Switch image and power on host and verify that it boots.
    [Tags]  Test_Firmware_Image_Switch_And_Power_On_Host
    [Template]  Firmware Switch Loop

    # iteration          power_on
    ${LOOP_COUNT}        YES


*** Keywords ***

Firmware Switch Loop
    [Documentation]  Wrapper keyword for iteration for firmware side switch.
    [Arguments]  ${iteration}  ${power_on}

    # Description of argument(s):
    # iteration      Number of switch it needs to perform.
    # power_on       If YES, boot the system post firmware image switch,
    #                if NO, do not perform any poweron operation.

    FOR  ${count}  IN RANGE  0  ${iteration}
        Log To Console   LOOP_COUNT:${count} execution.
        Redfish BMC Switch Firmware Side

        Continue For Loop If  '${power_on}' == 'NO'

        Log To Console   Power on requested, issuing power on.
        Redfish Power On

        # Power Off for next iteration. Firmware image switch ideally needs to be
        # to be executed when Host is powered off.
        Log To Console   Power off requested, issuing power off.
        Redfish Power Off
    END


Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Redfish Power Off  stack_mode=skip


Redfish BMC Switch Firmware Side
    [Documentation]  Switch back up image to running and verify.
    [Tags]  Redfish_BMC_Switch_Firmware_Side

    # fw_inv_dict:
    #  [19a3ef3e]:
    #    [image_type]:                                 BMC image
    #    [image_id]:                                   19a3ef3e
    #    [functional]:                                 True
    #    [version]:                                    2.12.0-dev-1440-g8dada0a1a
    #  [62d16947]:
    #    [image_type]:                                 BMC image
    #    [image_id]:                                   62d16947
    #    [functional]:                                 False
    #    [version]:                                    2.12.0-dev-1441-g8deadbeef
    ${fw_inv_dict}=  Get Software Inventory State
    Rprint Vars  fw_inv_dict

    # Get the backup firmware version for reference.
    FOR  ${id}  IN  @{fw_inv_dict.keys()}
        Continue For Loop If  '${fw_inv_dict['${id}']['functional']}' == 'True'
        # Find the non functional id and fetch the version.
        ${image_version}=  Set Variable  ${fw_inv_dict['${id}']['version']}
    END

    Log To Console  Backup firmware version: ${image_version}

    Switch Firmware Side  ${image_version}

    Match BMC Release And Redifsh Firmware Version
    Log To Console  The backup firmware image ${image_version} is now functional.


Match BMC Release And Redifsh Firmware Version
    [Documentation]  The /etc/os-release vs Redfish FirmwareVersion attribute value from
    ...             /redfish/v1/Managers/${MANAGER_ID} should match.

    # Python module: get_bmc_release_info()
    ${bmc_release_info}=  utils.Get BMC Release Info
    ${bmc_release}=  Set Variable  ${bmc_release_info['version_id']}
    Rprint Vars  bmc_release

    ${firmware_version}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  FirmwareVersion
    Rprint Vars  firmware_version

    Should Be Equal As Strings   ${bmc_release}   ${firmware_version}
    ...  msg=${bmc_release} does not match redfish version ${firmware_version}


Switch Firmware Side
    [Documentation]  Set the backup firmware to functional and verify after BMC rebooted.
    [Arguments]  ${image_version}

    # Description of argument(s):
    # image_version     Version of image.

    ${state}=  Get Pre Reboot State

    Print Timen  Switch to back up and rebooting.
    Switch Backup Firmware Image To Functional
    Wait For Reboot  start_boot_seconds=${state['epoch_seconds']}
    Print Timen  Switch to back up completed.

    # Check if the BMC version after rebooted is the same version asked to switch.
    ${firmware_version}=  Redfish.Get Attribute  /redfish/v1/Managers/${MANAGER_ID}  FirmwareVersion
    Should Be Equal As Strings   ${image_version}   ${firmware_version}
    ...  msg=${image_version} does not match redfish version ${firmware_version}
