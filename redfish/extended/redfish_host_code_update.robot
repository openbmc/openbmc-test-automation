*** Settings ***
Documentation            Update the BMC code on a target BMC via Redifsh.

# Test Parameters:
# IMAGE_FILE_PATH        The path to the BMC image file.
#
# Firmware update states:
#     Enabled            Image is installed and either functional or active.
#     Disabled           Image installation failed or ready for activation.
#     Updating           Image installation currently in progress.

Resource                 ../../lib/resource.robot
Resource                 ../../lib/bmc_redfish_resource.robot
Resource                 ../../lib/openbmc_ffdc.robot
Resource                 ../../lib/common_utils.robot
Resource                 ../../lib/code_update_utils.robot
Resource                 ../../lib/redfish_code_update_utils.robot
Resource                 ../../lib/utils.robot
Library                  ../../lib/gen_robot_valid.py
Library                  ../../lib/var_funcs.py
Library                  ../../lib/gen_robot_keyword.py
Library                  ../../lib/code_update_utils.py

Suite Setup              Suite Setup Execution
Suite Teardown           Redfish.Logout
Test Setup               Printn
Test Teardown            FFDC On Test Case Fail

# Force the test to timedout to prevent test hanging.
Test Timeout             30 minutes

*** Test Cases ***

Redfish Host Code Update
    [Documentation]  Update the firmware image.
    [Tags]  Redfish_Host_Code_Update

    ${image_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    Rprint Vars  image_version

    ${sw_inv}=  Get Functional Firmware  Host image
    ${functional_sw_inv}=  Get Non Functional Firmware  ${sw_inv}  True

    ${num_records}=  Get Length  ${functional_sw_inv}

    Run Keyword If  ${num_records} != 0  Redfish Firmware Is PreInstall  ${functional_sw_inv}  ${image_version}

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state

    # Check if the existing firmware is functional.
    #Pass Execution If  '${functional_version}' == '${image_version}'
    #...  The existing ${image_version} firmware is already functional.

   Print Timen  Performing firmware update ${image_version}.

   Redfish Update Firmware


*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Redfish.Login
    # Delete BMC dump and Error logs.
    Run Keyword And Ignore Error  Redfish Delete All BMC Dumps
    Run Keyword And Ignore Error  Redfish Purge Event Log
    # Checking for file existence.
    Valid File Path  IMAGE_FILE_PATH


Redfish Firmware Is PreInstall
    [Documentation]  Check fimrware is pre-install.
    [Arguments]  ${functional_sw_inv}  ${image_version}

    # Description of argument(s):
    # functional_sw_inv    Functional host inventory.
    # image_version        New firmware version.

    ${functional_version}=  Set Variable  ${functional_sw_inv['version']}
    Rprint Vars  functional_version

    Pass Execution If  '${functional_version}' == '${image_version}'
    ...  The existing ${image_version} firmware is already functional.


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface.

    Redfish.Login
    ${post_code_update_actions}=  Get Post Boot Action
    Rprint Vars  post_code_update_actions
    Run Keyword And Ignore Error  Set ApplyTime  policy=OnReset
    Redfish Upload Image And Check Progress State
    ${tar_version}=  Get Version Tar  ${IMAGE_FILE_PATH}
    ${image_info}=  Get Software Inventory State By Version  ${tar_version}
    Run Key  ${post_code_update_actions['${image_info["image_type"]}']['OnReset']}
    Redfish.Login
    Redfish Verify Host Version  ${IMAGE_FILE_PATH}

