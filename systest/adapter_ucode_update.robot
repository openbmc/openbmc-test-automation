*** Settings ***

Documentation  Verify that the uCode on all supported adapters can
...  be updated successfully on RedHat.

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#   ADAPTER_UCODE_URL           The url for the microcode file to be
#                               loaded.
#   DEVICE NAMES                A list containing the names of devices
#                               to be upgraded (e.g nvme0N1,nvme1n1)
#
# Example:
#   robot -v ADAPTER_UCODE_URL:http://someurl.com/ucode/file.img
#   -v DEVICE_NAMES:nvme0n1,nvme1n1 adapter_ucode_update.robot

Resource         ../syslib/utils_install.robot

*** Variables ***


*** Test Cases ***
Load And Activate uCode On Adapters
    [Documentation]  Load and activate firmware on the given adapters.
    [Tags]  Load_And_Activate_uCode_On_Adapters

    Rprintn
    # Format parms and ensure that nvme exists.
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  wget ${ADAPTER_UCODE_URL}
    ${img_file_split}=  Split String  ${ADAPTER_UCODE_URL}  /
    ${img_file}=  Set Variable  ${img_file_split[-1]}
    Set Suite Variable  ${img_file}
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
    Should Contain  ${img_file}  ${stdout}
    ...  msg=The code update was not successful.


*** Keywords ***
Load And Activate Firmware On Device
    [Documentation]  Load and activate firmware on device specified.
    [Arguments]  ${device_name}
    # Description of argument(s):
    # device_name              The name of the nvme device to be loaded
    #                          and activated.

    :FOR  ${i}  IN RANGE  1  4
    \  Execute Commands On Slot  ${device_name}  ${i}


Execute Commands On Slot
    [Documentation]  Execute load and activate commands on given slot.
    [Arguments]  ${device_name}  ${slot}
    # Description of argument(s):
    # device_name              The name of the nvme device to be loaded
    #                          and activated.
    # slot                     The nvme device slot to be activated.

    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  nvme fw-download /dev/${device_name} --fw=${img_file}
    Should Contain  ${stdout}  Firmware download success
    ...  msg=${img_file} could not be loaded on slot:${slot}
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  nvme fw-activate /dev/${device_name} -a 0 -s ${slot}
    Should Contain  ${stdout}  Success activating firmware
    ...  msg=Could not activate firmware on slot:1 on ${device_name}