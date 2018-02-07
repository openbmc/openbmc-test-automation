*** Settings ***
Documentation  Update internal storage devices uCode for SSDs and HDDs
#    TEST REQUIREMENTS:
#        Install sshgen - utility for running ssh using “keyboard-interactive” mode for password authentication
#        Firmware File must be postfixed with an underscore and the largest size the uCode supports
#            e.g    ->     if IBM_5100_MJ06.bin supports 960 to 1.92TB then change the file name to IBM_5100_MJ06_1.92TB.bin
#                          A file that supports 3.84TB could look like IBM_5100_MK06_4TB.bin
#        uCode files on lcb should be in /fspmount/witherspoon/SSD_HDDucode    |    extensions    -> .lod (HDDs)    .bin (SSDs)
#
#    TEST PARAMETERS
#        OS_HOST            |        OS Host IP Address
#        OS_USERNAME        |        OS Host User Name
#        OS_PASSWORD        |        OS Host Password
#        lcb_ip             |        LCB IP Address
#        lcb_user_id        |        LCB User ID
#        lcb_password       |        LCB User Password
#    EXPECTED
#    sdb uCode update complete OR sda uCode update complete upon completion will be logged to console, if not, check the log.html
#    to look at the sdb_fw and sda_fw compare to sdb_fw_post_reboot and sda_fw_post_reboot (Test Section "Get Current Firmware Level, Disk Storage Type and Size" and "Verify uCode Update",
#    either it failed or the ucode had already
#    been updated.
#        

Resource            ../syslib/utils_os.robot

Suite Setup    Log To Console    Starting Suite
Suite Teardown    Log To Console    Completed Suite

*** Variables ***
${ucode_temp_dir}       ucode_temp_dir/
${ucode_dir}            SSD_HDDucode
${sdb_hdparm_cmd}       hdparm -i /dev/sdb
${sda_hdparm_cmd}       hdparm -i /dev/sda
${sdb_lsblk_cmd}        lsblk /dev/sdb
${sda_lsblk_cmd}        lsblk /dev/sda

*** Test Cases ***
Get Current Firmware Level, Disk Storage Type and Size
    Login To OS
    # get firmware level
    ${sdb_hdparm}=    Execute Command On OS    ${sdb_hdparm_cmd}
    @{sdb_hdparm}=    Split String    ${sdb_hdparm}
    ${sdb_fw}=    Set Variable    ${sdb_hdparm[4]}
    ${sda_hdparm}=    Execute Command On OS    ${sda_hdparm_cmd}
    @{sda_hdparm}=    Split String    ${sda_hdparm}
    ${sda_fw}=    Set Variable    ${sda_hdparm[4]}
    Set Suite Variable    ${sdb_fw}
    Set Suite Variable    ${sda_fw}
    # get disk storage type
    ${sdb_lsblk}=    Execute Command On OS    ${sdb_lsblk_cmd}
    @{sdb_lsblk}=    Split String    ${sdb_lsblk}
    ${sdb_size}=    Set Variable    ${sdb_lsblk[10]}
    ${sdb_rota}=    Set Variable    ${sdb_lsblk[11]}
    ${sda_lsblk}=    Execute Command On OS    ${sda_lsblk_cmd}
    @{sda_lsblk}=    Split String    ${sda_lsblk}
    ${sda_size}=    Set Variable    ${sda_lsblk[10]}
    ${sda_rota}=    Set Variable    ${sda_lsblk[11]}
    
    Set Suite Variable    ${sdb_size}
    Set Suite Variable    ${sda_size}
    Set Suite Variable    ${sdb_rota}
    Set Suite Variable    ${sda_rota}
    

Create uCode Directory and SCP uCode Files
    # remove the directory if it already exists, avoid errors
    ${rm}=    Catenate    rm -r /${OS_USERNAME}/${ucode_dir}
    Execute Command    ${rm}
    ${cmd_dir}=    Catenate    mkdir /${OS_USERNAME}/${ucode_dir}
    Execute Command On OS    ${cmd_dir}
    ${chg}=    Catenate    chmod 777 /${OS_USERNAME}/${ucode_dir}
    Execute Command On OS    ${chg}
    SSHLibrary.Close Connection
    
    # Get Files from LCB
    Run    mkdir ${ucode_temp_dir}
    ${get_files}=    Catenate    sshpass -p ${lcb_password} scp -r ${lcb_user_id}@${lcb_ip}:/fspmount/witherspoon/${ucode_dir}    ./${ucode_temp_dir}
    Run    ${get_files}
    ${cmd}=    Catenate    sshpass -p ${OS_PASSWORD} scp ./${ucode_temp_dir}/${ucode_dir}/*    ${OS_USERNAME}@${OS_HOST}:/${OS_USERNAME}/${ucode_dir}
    Run    ${cmd}

Update For sdb
    Login To OS
    ${cmd}=    Catenate    ls /${OS_USERNAME}/${ucode_dir}
    ${files}=    Execute Command On OS    ${cmd}
    # @TODO: I'm assumming the system only has one type at a time, either HDDs or SDDs, might need to be chnanged
    ${ext}=    Set Variable If
    ...    "${sdb_rota}" == "0"    bin
    ...    "${sdb_rota}" == "1"    lod
    ${files_filtered}=    Return Files With Extension    ${files}    ${ext}
    ${file}=    Select File With Postfix    ${files_filtered}    ${sdb_size}
    Log    ${file}
    ${sdb_update}=    Catenate    hdparm --yes-i-know-what-i-am-doing --please-destroy-my-drive --fwdownload /${OS_USERNAME}/${ucode_dir}/${file} /dev/sdb
    Execute Command    ${sdb_update}
    SSHLibrary.Close Connection
    
Update For sda
    Login To OS
    ${cmd}=    Catenate    ls /${OS_USERNAME}/${ucode_dir}
    ${files}=    Execute Command On OS    ${cmd}
    # @TODO: I'm assumming the system only has one type at a time, either HDDs or SDDs, might need to be chnanged
    ${ext}=    Set Variable If
    ...    "${sda_rota}" == "0"    bin
    ...    "${sda_rota}" == "1"    lod
    ${files_filtered}=    Return Files With Extension    ${files}    ${ext}
    ${file}=    Select File With Postfix    ${files_filtered}    ${sda_size}
    Log    ${file}
    ${sda_update}=    Catenate    hdparm --yes-i-know-what-i-am-doing --please-destroy-my-drive --fwdownload /${OS_USERNAME}/${ucode_dir}/${file} /dev/sda
    Execute Command    ${sda_update}
    
Reboot OS and Wait for Completion
    Execute Command On OS    reboot
    SSHLibrary.Close Connection
    Sleep    1m    # Wait for it to shutdown
    Log To Console    Waiting for system to reboot
    Wait For Host To Ping    host=${OS_HOST}    timeout=21m    interval=3m
    
Verify uCode Update
    Login To OS
    # get firmware level
    ${sdb_hdparm}=    Execute Command On OS    ${sdb_hdparm_cmd}
    @{sdb_hdparm}=    Split String    ${sdb_hdparm}
    ${sdb_fw_post_reboot}=    Set Variable    ${sdb_hdparm[4]}
    ${sda_hdparm}=    Execute Command On OS    ${sda_hdparm_cmd}
    @{sda_hdparm}=    Split String    ${sda_hdparm}
    ${sda_fw_post_reboot}=    Set Variable    ${sda_hdparm[4]}
    SSHLibrary.Close Connection
    
    Run Keyword If    "${sdb_fw}" != "${sdb_fw_post_reboot}"    Log To Console    sdb uCode update complete
    Run Keyword If    "${sda_fw}" != "${sda_fw_post_reboot}"    Log To Console    sda uCode update complete
    

*** Keywords ***
# None