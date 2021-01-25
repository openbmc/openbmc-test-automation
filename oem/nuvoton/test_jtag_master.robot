*** Settings ***
Documentation    Module to test npcm750 JTAG Master.

Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/connection_client.robot

Suite Setup      Suite Setup Execution

*** Variables ***
${readid_svf}         readid.svf
${cpld_firmware1}     2A01.svf
${firmware_version1}  00 00 2a 01
${cpld_firmware2}     2A02.svf
${firmware_version2}  00 00 2a 02
${readusercode_svf}   read_usercode.svf
${jtag_dev}           /dev/jtag0
${power_cycle_cmd}    /usr/sbin/i2cset -f -y 8 0x11 0xd9
${wrong_cpld}         0
${program_cpld}       0

*** Test Cases ***

Test Read CPLD ID
    [Documentation]  Test Read CPLD ID.
    [Tags]  Test_Read_CPLD_ID

    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /var/${readid_svf}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Set Global Variable  ${wrong_cpld}  1
    Should Not Contain  ${stderr}  tdo check error
    Set Global Variable  ${wrong_cpld}  0


Test Program CPLD
    [Documentation]  Test Program CPLD.
    [Tags]  Test_Program_CPLD

    Pass Execution If  ${wrong_cpld}==1  Wrong CPLD chip
    Pass Execution If  ${program_cpld}==0  skip programming cpld

    Program CPLD  ${cpld_firmware2}  ${firmware_version2}
    Program CPLD  ${cpld_firmware1}  ${firmware_version1}

*** Keywords ***

Get File From SFTP Server
    [Documentation]  SCP Get File.
    [Arguments]      ${filename}

    Shell Cmd
    ...  scp ${SFTP_USER}@${SFTP_SERVER}:${SFTP_PATH}/${filename} ${filename}


Put File To BMC
    [Documentation]  SCP Put File.
    [Arguments]      ${filename}

    scp.Put File  ${filename}  /var/${filename}

Suite Setup Execution
    [Documentation]  Suite Setup Exection.

    ${status}=  Run Keyword And Return Status  Variable Should Exist
    ...  ${TEST_PROGRAM_CPLD}
    ${value}=  Set Variable if  ${status} == ${TRUE}  ${TEST_PROGRAM_CPLD}  0
    Set Global Variable  ${program_cpld}  ${value}

    Get File From SFTP Server  ${readid_svf}
    Run KeyWord If  ${program_cpld} == 1  Get File From SFTP Server  ${readusercode_svf}
    Run KeyWord If  ${program_cpld} == 1  Get File From SFTP Server  ${cpld_firmware1}
    Run KeyWord If  ${program_cpld} == 1  Get File From SFTP Server  ${cpld_firmware2}

    scp.Open connection  ${OPENBMC_HOST}  username=${OPENBMC_USERNAME}
    ...  password=${OPENBMC_PASSWORD}
    Put File To BMC  ${readid_svf}
    Run KeyWord If  ${program_cpld} == 1  Put File To BMC  ${readusercode_svf}
    Run KeyWord If  ${program_cpld} == 1  Put File To BMC  ${cpld_firmware1}
    Run KeyWord If  ${program_cpld} == 1  Put File To BMC  ${cpld_firmware2}
    Sleep  5s
    scp.Close Connection

Program CPLD
    [Documentation]  Program CPLD.
    [Arguments]      ${svf_file}  ${version}

    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /var/${svf_file}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Not Contain  ${stderr}  tdo check error

    # control hot swap controller to power cycle whole system
    BMC Execute Command  ${power_cycle_cmd}  ignore_err=1  fork=1

    Sleep  10s
    Run Keyword  Wait For Host To Ping  ${OPENBMC_HOST}  5 mins
    ${cmd}=  Catenate  loadsvf -d ${jtag_dev} -s /var/${readusercode_svf}
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Contain  ${output}  ${version}
