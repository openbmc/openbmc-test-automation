*** Settings ***
Documentation    Module to test npcm750 JTAG Master.

Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/connection_client.robot

Suite Setup      Suite Setup Execution

*** Variables ***
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

    # Description of argument(s):
    # filename   The file to be downloaded.

    Shell Cmd
    ...  scp ${SFTP_USER}@${SFTP_SERVER}:${SFTP_PATH}/${filename} ${filename}


Put File To BMC
    [Documentation]  SCP Put File.
    [Arguments]      ${filename}

    # Description of argument(s):
    # filename   The file to be uploaded.

    scp.Put File  ${filename}  /var/${filename}

Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    ${status}=  Run Keyword And Return Status  Variable Should Exist
    ...  ${TEST_PROGRAM_CPLD}
    ${value}=  Set Variable if  ${status} == ${TRUE}  ${TEST_PROGRAM_CPLD}  0
    Set Global Variable  ${program_cpld}  ${value}

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${olympus_json}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/oem/nuvoton/olympus.json'))  modules=json

    ${cpld_firmware1}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["fw1"]}
    ${cpld_firmware2}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["fw2"]}
    ${firmware_version1}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["fw1ver"]}
    ${firmware_version2}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["fw2ver"]}
    ${readusercode_svf}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["readusercode"]}
    ${readid_svf}=  Set Variable  ${olympus_json["npcm7xx"]["cpld"]["readid"]}
    ${jtag_dev}=  Set Variable  ${olympus_json["npcm7xx"]["jtag_dev"]}
    ${power_cycle_cmd}=  Set Variable  ${olympus_json["npcm7xx"]["power_cycle_cmd"]}

    Set Suite Variable  ${cpld_firmware1}
    Set Suite Variable  ${cpld_firmware2}
    Set Suite Variable  ${firmware_version1}
    Set Suite Variable  ${firmware_version2}
    Set Suite Variable  ${readusercode_svf}
    Set Suite Variable  ${readid_svf}
    Set Suite Variable  ${jtag_dev}
    Set Suite Variable  ${power_cycle_cmd}

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

    # Description of argument(s):
    # svf_file   The firmware file.
    # version    The firmware version.

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
