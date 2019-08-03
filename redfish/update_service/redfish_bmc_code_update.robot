*** Settings ***
Documentation     Update firmware on a target BMC via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH    The path to the BMC image file.
#
# Firmware update states:
#     Enabled        Image is installed and either functional or active.
#     Disabled       Image installation failed or ready for activation.
#     Updating       Image installation currently in progress.

Resource          ../../lib/resource.robot
Resource          ../../lib/bmc_redfish_resource.robot
Resource          ../../lib/openbmc_ffdc.robot
Resource          ../../lib/common_utils.robot
Resource          ../../lib/code_update_utils.robot
Resource          ../../lib/dump_utils.robot
Resource          ../../lib/logging_utils.robot
Resource          ../../lib/redfish_code_update_utils.robot
Library           ../../lib/gen_robot_valid.py
Library           ../../lib/tftp_update_utils.py

Suite Setup       Suite Setup Execution
Suite Teardown    Redfish.Logout
Test Setup        Printn
Test Teardown     FFDC On Test Case Fail

Force Tags   BMC_Code_Update

*** Variables ***
${immediate}      Immediate
${onreset}        OnReset

*** Test Cases ***

Redfish Code Update With ApplyTime OnReset
    [Documentation]  Update the firmaware image with ApplyTime of OnReset.
    [Tags]  Redfish_Code_Update_With_ApplyTime_OnReset
    [Template]  Redfish Update Firmware

    # policy
    ${onreset}


Redfish Code Update With ApplyTime Immediate
    [Documentation]  Update the firmaware image with ApplyTime of Immediate.
    [Tags]  Redfish_Code_Update_With_ApplyTime_Immediate
    [Template]  Redfish Update Firmware

    # policy
    ${immediate}


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login

    # Delete BMC dump and Error logs
    Delete All BMC Dump
    Redfish Purge Event Log

    # Checking for file existence.
    OperatingSystem.File Should Exist  ${IMAGE_FILE_PATH}


Redfish Update Firmware
    [Documentation]  Code update with ApplyTime and verify installation.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # policy     ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    Set ApplyTime  policy=${apply_time}

    Redfish Upload Image  ${REDFISH_BASE_URI}UpdateService  ${IMAGE_FILE_PATH}

    ${image_id}=  Get Latest Image ID
    Rprint Vars  image_id

    Check Image Update Progress State
    ...  match_state='Disabled', 'Updating'  image_id=${image_id}

    # Wait a few seconds to check if the update progress started.
    Sleep  5s
    Check Image Update Progress State
    ...  match_state='Updating'  image_id=${image_id}

    Wait Until Keyword Succeeds  8 min  20 sec
    ...  Check Image Update Progress State
    ...    match_state='Enabled'  image_id=${image_id}

    Reboot BMC And Verify BMC Image
    ...  ${apply_time}  start_boot_seconds=${state['epoch_seconds']}


Reboot BMC And Verify BMC Image
    [Documentation]  Reboot or wait for BMC standby post reboot and
    ...  verify installed image is functional.
    [Arguments]  ${apply_time}  ${start_boot_seconds}

    # Description of argument(s):
    # policy                ApplyTime allowed values (e.g. "OnReset", "Immediate").
    # start_boot_seconds    See 'Wait For Reboot' for details.

    Run Keyword if  'OnReset' == '${apply_time}'
    ...  Run Keywords
    ...      Redfish OBMC Reboot (off)  AND
    ...      Redfish.Login  AND
    ...      Redfish Verify BMC Version  ${IMAGE_FILE_PATH}
    ...  ELSE
    ...    Run Keywords
    ...        Wait For Reboot  start_boot_seconds=${start_boot_seconds}  AND
    ...        Redfish.Login  AND
    ...        Redfish Verify BMC Version  ${IMAGE_FILE_PATH}

