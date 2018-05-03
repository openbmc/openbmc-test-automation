*** Settings ***

Documentation  Verify that connected USB device can be detected by the
...  OS and exercised in HTX or written to.

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_USERNAME            The BMC user name.
#   OPENBMC_PASSWORD            The BMC password.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS Host password.
#   USB_DEVICE_NAME             The USB device to be used in test.
#   TIMEOUT                     Amount of time to wait for the device
#                               being exercised to reach 1 cycle.

Resource           ../syslib/utils_os.robot

Test Setup         Test Setup Execution
Test Teardown      Test Teardown Execution

*** Variables ***


*** Test Cases ***

Verify Write To USB Device
    [Documentation]  Verify that the given device can be written to.
    [Tags]  Verify_Write_To_USB_Device

    OS Execute Command  mkdir -p /mount-dev/
    OS Execute Command  mount -rw /dev/${USB_DEVICE_NAME} /mount-dev/
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  echo "Write to file" /mount-dev/file.txt  ignore_err=1
    Should Be Empty  ${stderr}  msg=Could not write to USB device.


Exercise USB Device
    [Documentation]  Verify that the given device can be exercised with
    ...  HTX.
    [Tags]  Exercise_USB_Device

    Run MDT Profile
    # If the htxcmdline -status does not include this device then it is
    # not a device that can be exercised with HTX, fail.
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  htxcmdline -status | grep ${USB_DEVICE_NAME}

    Wait Until Keyword Succeeds
    ...  ${TIMEOUT}  10s  Verify Device Cycle Completion


*** Keywords ***

Verify Device Cycle Completion
    [Documentation]  Verify that the USB device has completed at least
    ...  one HTX cycle.

    # Grep htxcmdline -status to get the device's cycle count.
    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -status | grep ${USB_DEVICE_NAME} | awk '{print $5}'
    Should Not Be Empty  ${stdout}  msg=Device is not running HTX
    Run Keyword If  ${stdout} < 1
    ...  FAIL  msg=Device has not completed at least one cycle.


Test Setup Execution
    [Documentation]  Do initial test setup task(s).

    OS Execute Command  ls /dev/${USB_DEVICE_NAME}


Test Teardown Execution
    [Documentation]  Perform post test case tasks.

    # Even if the tests fails, device should be unmounted and HTX idle.
    Run Keyword If  '${TEST_NAME}' == 'Verify Write To USB Device'
    ...    OS Execute Command  umount /mount-dev/
    ...  ELSE
    ...    Shutdown HTX Exerciser
    FFDC On Test Case Fail