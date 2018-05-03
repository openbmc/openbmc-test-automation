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
#   DEVICE                      USB device to be used in test.
#   TEST                        The test to be performed on the device
#                               "Write" to write to the device or
#                               "Exercise" to run the HTX exerciser.
#   WAIT_TIME                   Amount of time to wait for the device
#                               being exercised to reach 1 cycle.

Resource           ../syslib/utils_os.robot

Test Teardown      FFDC On Test Case Fail
Suite Teardown     Suite Teardown Execution

*** Variables ***
${OPENBMC_HOST}  9.5.166.198
${OPENBMC_PASSWORD}  0penBmc
${OPENBMC_USERNAME}  root
${OS_HOST}  9.5.166.199
${OS_USERNAME}  root
${OS_PASSWORD}  G1trdone
${WAIT_TIME}      5m


*** Test Cases ***

Verify Device Detected
    [Documentation]  Verify that the device can be detected.
    [Tags]  Verify_Device_Detected

    ${stdout}  ${stderr}  ${rc}  OS Execute Command  ls /dev/${DEVICE}
    Should Not Contain  ${stdout}  No such file or directory
    ...  msg=Device ${DEVICE} not found.


Test Device
    [Documentation]   Perform specified test on the device.
    [Tags]  Test_Device

    Run Keyword If  '${TEST}'=='Write'
    ...  Write To Device
    ...  ELSE IF  '${TEST}'=='Exercise'  Run Keywords
    ...  Run MDT Profile
    ...  AND  Wait Until Keyword Succeeds
    ...  ${WAIT_TIME}  10s  Exercise Device
    ...  ELSE  FAIL  msg=Invalid function: ${TEST}


*** Keywords ***

Write To Device
    [Documentation]  Verify that the given device can be written to.

    OS Execute Command  mkdir /mount-dev/
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  mount -rw /dev/${DEVICE} /mount-dev/
    ${stdout}  ${stderr}  ${rc}  OS Execute Command
    ...  echo "Write to file" /mount-dev/file.txt  ignore_err=1
    Should Be Empty  ${stderr}  msg=Could not write to device.
    OS Execute Command  umount /mount-dev/


Exercise Device
    [Documentation]  Verify that the given device can be exercised with
    ...  HTX.

    ${stdout}  ${stderr}  ${rc}=  OS Execute Command
    ...  htxcmdline -status | grep ${DEVICE} | awk '{print $5}'
    Run Keyword If  ${stdout} != 1
    ...  FAIL  msg=Device cycle not completed.


Suite Teardown Execution
    [Documentation]  Do post suite teardown execution.

    Run Keyword If  '${TEST}'=='Write'
    ...  OS Execute Command  yes | rm -r /mount-dev/
    ...  ELSE IF  '${TEST}'=='Exercise'  Shutdown HTX Exerciser