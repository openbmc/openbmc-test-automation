*** Settings ***

Documentation  Verify that the uCode can be updated on supported
...  Non-Volatile Memory Express (NVMe) adapters on RedHat.

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#   ADAPTER_UCODE_URL           The url for the microcode file to be
#                               loaded.
#   DEVICE NAMES                A comma-seperated list containing the
#                               names of devices to be upgraded
#                               (e.g "nvme0n1,nvme1n1").
#
# Example:
#   robot -v ADAPTER_UCODE_URL:http://someurl.com/ucode/file.img
#   -v DEVICE_NAMES:nvme0n1,nvme1n1 adapter_ucode_update.robot

Resource         ../syslib/utils_install.robot

Suite Setup      Suite Setup Execution

*** Variables ***


*** Test Cases ***
Load And Activate uCode On Adapters
    [Documentation]  Load and activate firmware on the given adapters.
    [Tags]  Load_And_Activate_uCode_On_Adapters

    Rprintn
    # Format parms.
    # Ensure that nvme (pci-e storage utility) tool exists.
    ${device_names}=  Split String  ${DEVICE_NAMES}  ,
    OS Execute Command  yes | yum install nvme-cli
    Tool Exist  nvme
    # Load and activate firmware on the devices.
    :FOR  ${device_name}  in  @{device_names}
    \  Load And Activate Firmware On Device  ${device_name}


Reboot And Verify Code Update
    [Documentation]  Reboot the OS and verify that the firmware update
    ...  was successful.
    [Tags]  Reboot_And_Verify_Code_Update

    Host Reboot
    # Reboot and verify success
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  nvme list | grep nvme0 | awk '{print $NF'}
    Should Contain  ${image_file_name}  ${stdout}
    ...  msg=The code update was not successful.


*** Keywords ***
Load And Activate Firmware On Device
    [Documentation]  Load and activate firmware on device specified.
    [Arguments]  ${device_name}  ${image_file_name}=${image_file_name}

    # Description of argument(s):
    # device_name              The name of the NVMe device to be loaded
    #                          and activated (e.g. "nvme0n1").
    # image_file_name          The name of the firmware image file.

    :FOR  ${slot_id}  IN RANGE  1  4
    \  Execute Commands On Slot
    \  ...  ${device_name}  ${slot_id}  ${image_file_name}


Execute Commands On Slot
    [Documentation]  Execute load and activate commands on given slot.
    [Arguments]  ${device_name}  ${slot_id}
    ...  ${image_file_name}=${image_file_name}

    # Description of argument(s):
    # device_name              The name of the NVMe device to be loaded
    #                          and activated (e.g. "nvme0n1").
    # slot_id                  The NVMe device slot id to be activated
    #                          (e.g. "0","1", etc.).
    # image_file_name          The name of the firmware image file.

    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  nvme fw-download /dev/${device_name} --fw=${image_file_name}
    Should Contain  ${stdout}  Firmware download success
    ...  msg=${image_file_name} could not be loaded on slot:${slot}
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  nvme fw-activate /dev/${device_name} -a 0 -s ${slot_id}
    Should Contain  ${stdout}  Success activating firmware
    ...  msg=Could not activate slot:${slot_id} on ${device_name}.


Suite Setup Execution
    [Documentation]  Setup parms used in suite and download ucode file.

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  wget ${ADAPTER_UCODE_URL}
    ${image_dir_path_url}  ${image_file_name}=
    ...  Split Path  ${ADAPTER_UCODE_URL}
    Set Global Variable  ${image_file_name}