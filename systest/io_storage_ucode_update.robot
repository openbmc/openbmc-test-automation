*** Settings ***
Documentation  Update internal storage devices uCode for solid-state
...  drives (SSDs) and hard disk drives (HDDs).

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_PASSWORD            The BMC password.
#   OPENBMC_USERNAME            The BMC user name.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME        .        The OS Host user name.
#   OS_PASSWORD        .        The OS Host password.
#   SDA_UCODE_FILE_PATH         The path of the ucode file, on the OS
#                               for the sda disk (e.g Code_File.bin).
#   SDA_DESIRED_LEVEL           The expected firmware level for sda
#                               after the firmware update.
#   SDB_UCODE_FILE_PATH         The path of the ucode file, on the OS
#                               for the sdb disk (e.g Code_File.bin).
#   SDB_DESIRED_LEVEL           The expected firmware level for sdb
#                               after the firmware update.

Resource            ../syslib/utils_os.robot
Library            ../lib/firmware_utils.py


Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

Load Microcode On Hard Disks
    [Documentation]  Load the microcode unto the hard disks.
    [Tags]  Load_Microcode_On_Hard_Disks

    # Load firmware.
    ${sda_update_cmd}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload ${SDA_UCODE_FILE_PATH}
    ...  /dev/sda
    ${sdb_update_cmd}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload ${SDB_UCODE_FILE_PATH}
    ...  /dev/sdb

    OS Execute Command  ${sda_update_cmd}
    OS Execute Command  ${sdb_update_cmd}


Reboot OS And Verify Code Update
    [Documentation]  Reboot the OS and verify that the firmware revision
    ...  now reflects the desired levels.
    [Tags]  Reboot_OS_And_Verify_Code_Update

    Initiate OS Host Reboot
    Wait for OS
    &{sdb_info}=  Get Hard Disk Info  /dev/sdb
    &{sda_info}=  Get Hard Disk Info  /dev/sda
    Run Keyword Unless
    ...  '${sda_info['firmware_revision']}' == '${SDA_DESIRED_LEVEL}'
    ...  FAIL  msg=update failed for sda.
    Run Keyword Unless
    ...  '${sdb_info['firmware_revision']}' == '${SDB_DESIRED_LEVEL}'
    ...  FAIL  msg=update failed for sdb..


*** Keywords ***
Test Setup Execution
    [Documentation]  Do initial setup tasks.

    Should Not Be Empty  ${SDA_UCODE_FILE_PATH}
    ...  msg=SDA ucode file path cannot be empty.
    Should Not Be Empty  ${SDB_UCODE_FILE_PATH}
    ...  msg=SDB ucode file path cannot be empty.