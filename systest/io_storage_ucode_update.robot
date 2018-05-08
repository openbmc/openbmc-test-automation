*** Settings ***
Documentation  Update internal storage devices uCode for solid-state
...  drives (SSDs) and hard disk drives (HDDs).

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_PASSWORD            The BMC password.
#   OPENBMC_USERNAME            The BMC user name.
#   OS_HOST                     The OS host name or IP address.
#   OS_USERNAME                 The OS user name.
#   OS_PASSWORD                 The OS password.
#   SDA_UCODE_FILE_PATH         The path of the ucode file, on the OS
#                               for the sda disk (e.g "Code_File.bin").
#   SDA_DESIRED_LEVEL           The expected firmware level for sda
#                               after the firmware update (e.g "MJ06").
#   SDB_UCODE_FILE_PATH         The path of the ucode file, on the OS
#                               for the sdb disk (e.g "Code_File.bin").
#   SDB_DESIRED_LEVEL           The expected firmware level for sdb
#                               after the firmware update (e.g "MK06").

Resource            ../syslib/utils_os.robot
Library             ../lib/gen_robot_valid.py
Library             ../lib/firmware_utils.py


Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail


*** Variables ***


*** Test Cases ***

Load Microcode On Hard Disks
    [Documentation]  Load the microcode onto the hard disks.
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

    Host Reboot
    &{sdb_info}=  Get Hard Disk Info  /dev/sdb
    &{sda_info}=  Get Hard Disk Info  /dev/sda
    Should Be Equal  ${sdb_info['firmware_revision']}
    ...  ${SDB_DESIRED_LEVEL}  msg=Update failed for SDB
    Should Be Equal  ${sda_info['firmware_revision']}
    ...  ${SDA_DESIRED_LEVEL}  msg=Update failed for SDA


*** Keywords ***
Test Setup Execution
    [Documentation]  Do initial setup tasks.

    Rvalid Value  SDB_DESIRED_LEVEL
    Rvalid Value  SDA_DESIRED_LEVEL
    Rvalid Value  SDB_UCODE_FILE_PATH
    Rvalid Value  SDA_UCODE_FILE_PATH