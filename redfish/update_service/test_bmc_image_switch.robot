*** Settings ***
Documentation            Redfish test to switch image sides and boot.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Library                  ../../lib/tftp_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Teardown            FFDC On Test Case Fail

*** Test Cases ***

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

    Set Backup Firmware To Functional  ${image_version}

    Match BMC Release And Redifsh Firmware Version
    Log To Console  The backup firmware image ${image_version} is now functional.


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    Run Keyword And Ignore Error  Redfish Purge Event Log
    Redfish Power Off  stack_mode=skip


Match BMC Release And Redifsh Firmware Version
    [Documentation]  The /etc/os-release vs Redfish FirmwareVersion attribute value from
    ...             /redfish/v1/Managers/bmc should match.

    # Python module: get_bmc_release_info()
    ${bmc_release_info}=  utils.Get BMC Release Info
    ${bmc_release}=  Set Variable  ${bmc_release_info['version_id']}
    Rprint Vars  bmc_release

    ${firmware_version}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  FirmwareVersion
    Rprint Vars  firmware_version

    Should Be Equal As Strings   ${bmc_release}   ${firmware_version}
    ...  msg=${bmc_release} does not match redfish version ${firmware_version}


Set Backup Firmware To Functional
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
    ${firmware_version}=  Redfish.Get Attribute  /redfish/v1/Managers/bmc  FirmwareVersion
    Should Be Equal As Strings   ${image_version}   ${firmware_version}
    ...  msg=${image_version} does not match redfish version ${firmware_version}
