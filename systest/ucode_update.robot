*** Settings ***
Documentation  Update internal storage devices uCode for SSDs and HDDs.
# TEST REQUIREMENTS:
# 1. Firmware file must be postfixed with an underscore and the largest.
# size the uCode supports. e.g: if IBM_5100_MJ06.bin supports 960 to 1.92T
# then change the file name to IBM_5100_MJ06_1.92T.bin.
# 2. uCode files on OS should be in: root/SSD_HDDucode
# known extensions lod (HDDs) and bin (SSDs).

# TEST PARAMETERS
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_PASSWORD            The BMC PASSWORD.
#   OS_HOST            |        OS Host IP Address.
#   OS_USERNAME        |        OS Host User Name.
#   OS_PASSWORD        |        OS Host Password.

# EXPECTED
#   "sdb/sda uCode update complete" upon completion should be logged to
#   console, if not, check the log.html to look at the firmware levels
#  in the sdb/sda_info and sdb/sda_post_update dictionary.

Resource            ../syslib/utils_os.robot
Library             ../lib/utils_files.py
Library             ../lib/firmware_utils.py

Test Setup  Get Disk Info
Test Teardown  FFDC On Test Case Fail


*** Variables ***
${ucode_temp_dir}       ucode_temp_dir
${ucode_dir}            SSD_HDDucode
${FwRev}                'firmware_revision'
${rota}                 'ro'
${size}                 'size'


*** Test Cases ***

Update For SDB
    [Documentation]  Performs update for sdb.
    [Tags]  Update_For_SDB
    ${cmd}=  Catenate  ls /${OS_USERNAME}/${ucode_dir}
    ${files}=  Execute Command On OS  ${cmd}
    # @TODO: I'm assumming the system only has one type at a time
    # either HDDs or SDDs, might need to be changed.
    ${ext}=    Set Variable If
    ...  "${sdb_info[${rota}]}" == "0"  bin
    ...  "${sdb_info[${rota}]}" == "1"  lod
    ${files_filtered}=  Return Files With Extension  ${files}  ${ext}
    ${file}=  Select File With Postfix  ${files_filtered}  ${sdb_info[${size}]}
    Log  ${file}
    ${sdb_update}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload
    ...  /${OS_USERNAME}/${ucode_dir}/${file} /dev/sdb
    Execute Command  ${sdb_update}


Update For SDA
    [Documentation]  Performs update for sda.
    [Tags]  Update_For_SDA
    ${cmd}=  Catenate  ls /${OS_USERNAME}/${ucode_dir}
    ${files}=  Execute Command On OS  ${cmd}
    ${ext}=  Set Variable If
    ...  "${sda_info[${rota}]}" == "0"  bin
    ...  "${sda_info[${rota}]}" == "1"  lod
    ${files_filtered}=  Return Files With Extension  ${files}  ${ext}
    ${file}=  Select File With Postfix  ${files_filtered}  ${sda_info[${size}]}
    Log  ${file}
    ${sda_update}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload
    ...  /${OS_USERNAME}/${ucode_dir}/${file} /dev/sda
    Execute Command  ${sda_update}


Reboot OS And Verify uCode Update
    [Documentation]  Reboots the OS and Verifies that the update was successful.
    [Tags]  Reboot_OS_And_Verify_uCode_Update
    Host Reboot
    Login To OS
    &{sdb_post_update}=  Get Hard Disk Info  /dev/sdb
    &{sda_post_update}=  Get Hard Disk Info  /dev/sda
    Run Keyword If  "${sdb_info[${FwRev}]}" != "${sdb_post_update[${FwRev}]}"
    ...  Log To Console  sdb uCode update complete.
    ...  ELSE
    ...  Log To Console  sdb uCode update not successful FwRev still the same.
    Run Keyword If  "${sda_info[${FwRev}]}" != "${sda_post_update[${FwRev}]}"
    ...  Log To Console  sda uCode update complete.
    ...  ELSE
    ...  Log To Console  sda uCode update not successful FwRev still the same.


*** Keywords ***

Get Disk Info
    [Documentation]  Gets info for hard disks and set suite variables.
    Login To OS
    &{sdb_info}=  Get Hard Disk Info  /dev/sdb
    &{sda_info}=  Get Hard Disk Info  /dev/sda
    Set Suite Variable  &{sdb_info}
    Set Suite Variable  &{sda_info}