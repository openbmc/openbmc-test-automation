*** Settings ***
Documentation  Update internal storage devices uCode for solid-state drives
...  (SSDs) and hard disk drives (HDDs).
# TEST REQUIREMENTS:
# 1. Firmware file must be suffixed with an underscore, followed by the size
# range it supports in terabytes, e.g: if IBM_5100_MJ06.bin supports 960 GB to
# 1.92TB then change the file name to IBM_5100_MJ06_.96-1.92T.bin
# 2. uCode files on OS should be in root/SSD_HDDucode and
# supported extensions are ".lod" (for HDDs) and ".bin" (for SSDS).

# TEST PARAMETERS:
#   OPENBMC_HOST                The BMC host name or IP address.
#   OPENBMC_PASSWORD            The BMC password.
#   OPENBMC_USERNAME            The BMC user name.
#   OS_HOST                     The OS Host or IP address.
#   OS_USERNAME        .        The OS Host user name.
#   OS_PASSWORD        .        The OS Host password.

Resource            ../syslib/utils_os.robot
Library             ../lib/utils_files.py
Library             ../lib/firmware_utils.py
Library             ../lib/bmc_ssh_utils.py

Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail


*** Variables ***

${FwRev}                'firmware_revision'
${rota}                 'ro'


*** Test Cases ***

Perform Update On Hard Disks
    [Documentation]  Perform update on hard disks.
    [Tags]  Perform_Update_On_Hard_Disks
    Update Hard Disk  ${sdb_info}  sdb
    Update Hard Disk  ${sda_info}  sda


Reboot OS And Verify uCode Update
    [Documentation]  Reboot the OS and verify that the update was successful.
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
    [Documentation]  Update hard disk.
    [Arguments]  ${hard_disk_info}  ${device_name}

    # Description of Argument(s):
    # hard_disk_info       A dictionary of firwmare information for the
    # device which can be obtained via a call to 'Get Hard Disk Info'.
    # name                 The name of the hard disk, e.g: sdb, sda.

    ${ucode_dir_name}=  Set Variable  SSD_HDDucode
    ${ext}=  Set Variable If
    ...  "${hard_disk_info[${rota}]}" == "0"  bin
    ...  "${hard_disk_info[${rota}]}" == "1"  lod
    ${file_names}  ${stderr}  ${rc}=  OS Execute Command
    ...  cd /${OS_USERNAME}/${ucode_dir_name}/ && ls *.${ext}
    ${file_list}=  Split String  ${file_names}
    ${ucode_file}=  Find uCode File  ${file_list}  ${hard_disk_info['size'][:-1]}
    ${disk_update}=  Catenate  hdparm --yes-i-know-what-i-am-doing
    ...  --please-destroy-my-drive --fwdownload
    ...  /${OS_USERNAME}/${ucode_dir_name}/${ucode_file} /dev/${device_name}
    OS Execute Command  ${disk_update}

Find uCode File
    [Documentation]  Return uCode file that corresponds to device size.
    [Arguments]  ${file_names}  ${device_size}

    # Description of Argument(s):
    # file_list          A list of available ucode file.
    # size               The size of the hard disk.
    # ext                The supported file extension for the hard disk.
    # For example, given the following input:
    #
    # file_list:
    #  file_list[0]:   IBM_5100_MJ06_.96-1.92T.bin
    #  file_list[1]:   IBM_5100_MK06_2-3.84T.bin
    # device_size:     1.8T
    # This keyword will return "IBM_5100_MJ06_.96-1.92T.bin".

    :FOR  ${file_name}  IN  @{file_names}
    \  ${range_string}=  Remove String Using Regexp  ${file_name}  .*_  T.*
    \  ${range}=  Split String  ${range_string}  -
    \  Return From Keyword If
    ...  "${device_size}" >= "${range[0]}" and "${device_size}" <= "${range[1]}"
    ...  ${file_name}

    Fail  msg=Failed to find uCode file in list: ${file_names}.
    [Return]  ${file_name}