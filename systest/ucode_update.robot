*** Settings ***
Documentation  Update internal storage devices uCode for solid-state drives (SSDs)
...  and hard disk drives (HDDs).
# TEST REQUIREMENTS:
# 1. Firmware file must be suffixed with an underscore, followed by the size
# range it supports in terabytes, e.g: if IBM_5100_MJ06.bin supports 960 GB to
# 1.92TB then change the file name to IBM_5100_MJ06_.96-1.92T.bin
# 2. uCode files on OS should be in: root/SSD_HDDucode and
# supported extensions are ".lod" (for HDDs) and ".bin" (for SSDS).

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_PASSWORD            The BMC password.
#   OPENBMC_USERID              The BMC user id.
#   OS_HOST            .        The OS Host IP address.
#   OS_USERNAME        .        The OS Host user name.
#   OS_PASSWORD        .        The OS Host password.

Resource            ../syslib/utils_os.robot
Library             ../lib/utils_files.py
Library             ../lib/firmware_utils.py

Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail


*** Variables ***

${ucode_dir}            SSD_HDDucode
${FwRev}                'firmware_revision'
${rota}                 'ro'
${size}                 'size'


*** Test Cases ***

Perform Update On Hard Disks
    [Documentation]  Perform update on hard disks.
    [Tags]  Perform_Update_On_Hard_Disks
    # @TODO: I'm assumming the system only has one type at a time -
    # either HDDs or SDDs. This may need to be changed.
    Update Hard Disk  ${sdb_info}  sdb
    Update Hard Disk  ${sda_info}  sda


Reboot OS And Verify uCode Update
    [Documentation]  Reboot the OS and Verifies that the update was successful.
    [Tags]  Reboot_OS_And_Verify_uCode_Update
    Host Reboot
    Login To OS
    &{sdb_post_update}=  Get Hard Disk Info  /dev/sdb
    &{sda_post_update}=  Get Hard Disk Info  /dev/sda
    Run Keyword If  "${sdb_info[${FwRev}]}" != "${sdb_post_update[${FwRev}]}"
    ...  Log  sdb uCode update complete.
    ...  ELSE
    ...  Log  sdb uCode update not successful FwRev still the same.
    Run Keyword If  "${sda_info[${FwRev}]}" != "${sda_post_update[${FwRev}]}"
    ...  Log  sda uCode update complete.
    ...  ELSE
    ...  Log  sda uCode update not successful FwRev still the same.


*** Keywords ***

Test Setup Execution
    [Documentation]  Get info for hard disks and set suite variables.
    Login To OS
    &{sdb_info}=  Get Hard Disk Info  /dev/sdb
    &{sda_info}=  Get Hard Disk Info  /dev/sda
    Log  ${sdb_info}
    Log  ${sda_info}
    Set Suite Variable  &{sdb_info}
    Set Suite Variable  &{sda_info}


Update Hard Disk
    [Documentation]  Perform update hard disk.
    [Arguments]  ${harddisk_info}  ${name}
    ${ext}=    Set Variable If
    ...  "${harddisk_info[${rota}]}" == "0"  bin
    ...  "${harddisk_info[${rota}]}" == "1"  lod
    ${file_names}=  Execute Command On OS  cd /${OS_USERNAME}/${ucode_dir}/ && ls *.${ext}
    ${file_list}=  Split String  ${file_names}
    ${ucode_file}=  Find uCode File  ${file_list}  ${harddisk_info[${size}]}  ${ext}
    ${disk_update}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload
    ...  /${OS_USERNAME}/${ucode_dir}/${ucode_file} /dev/${name}
    # I'm using this as opposed to "Execute Command On OS" because that
    # keyword notes the message 'fwdownload: xfer_mode=3 min=1 max=255 size=512'
    # which pops up after the fw update command as an std error.
    Execute Command  ${disk_update}
    
Find uCode File
    [Documentation]  Find uCode file for disk size.
    [Arguments]  ${file_list}  ${size}  ${ext}
    ${ucode_file}  Set Variable  ''
    :FOR  ${file}  IN  @{file_list}
    \  ${r_temp}=  Remove String Using Regexp  ${file}  T.${ext}
    \  ${s_temp}=  Split String  ${r_temp}  _
    \  ${range}=  Split String  ${s_temp[-1]}  -
    \  ${ucode_file}=  Set Variable  ${file}
    \  Run Keyword If  "${size}" >= "${range[0]}" and "${size}" <= "${range[1]}"  Exit For Loop
    [Return]  ${ucode_file}