*** Settings ***
Documentation       Utility for RAS test scenarios through HOST & BMC. 
Resource            ../../lib/utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/openbmc_ffdc_utils.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Resource            ../../lib/ras/host_utils.robot
Resource            ../../lib/resource.robot
Resource            ../../lib/state_manager.robot
Resource            ../../lib/boot_utils.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py
Resource            ../../lib/dump_utils.robot

Library             DateTime
Library             OperatingSystem
Library             random
Library             Collections

*** Variables ***
${stack_mode}       normal

*** Keywords ***

Verify And Clear Gard Records On HOST
    [Documentation]  Verify And Clear gard records on HOST.

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  No GARD
    Gard Operations On OS  clear all

Verify Error Log Entry
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # signature_desc  Error log signature description.
    # log_prefix      Log path prefix.

    Error Logs Should Exist

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output}=  Run and Return RC and Output
    ...  grep -i ${signature_desc} ${error_log_file_path}
    Should Be Equal  ${rc}  ${0}
    Should Not Be Empty  ${output}

Inject Recoverable Error With Threshold Limit
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting.
    ...              2. Inject Error on processor/centaur.
    ...              3. Check If HOST is running.
    ...              4. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${interface_type}  ${fir}  ${chip_address}  ${threshold_limit}
    ...              ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # interface_type      Inject error through 'BMC' or 'HOST'.
    # fir                 FIR (Fault isolation register) value (e.g. 2011400).
    # chip_address        Chip address (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).
    # signature_desc      Error log signature description.
    # log_prefix          Log path prefix.

    Set Auto Reboot  1
    Run Keyword If  '${interface_type}' == 'HOST'
    ...     Inject Error Through HOST  ${fir}  ${chip_address}  ${threshold_limit}
    ...     ${master_proc_chip}
    ...  ELSE
    ...     Inject Error Through BMC  ${fir}  ${chip_address}  ${threshold_limit}
    ...     ${master_proc_chip}

    Is Host Running
    ${output}=  Gard Operations On OS  list
    Should Contain  ${output}  No GARD
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}


Inject Unrecoverable Error Through Host
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting.
    ...              2. Inject Error on processor/centaur.
    ...              3. Check If HOST is rebooted.
    ...              4. Verify & clear gard records.
    ...              5. Verify error log entry & signature description.
    ...              6. Verify & clear dump entry.
    [Arguments]      ${fir}  ${chip_address}  ${threshold_limit}
    ...              ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # fir                 FIR (Fault isolation register) value (e.g. 2011400).
    # chip_address        Chip address (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).
    # signature_desc      Error Log signature description.
    #                     (e.g 'mcs(n0p0c0) (MCFIR[0]) mc internal recoverable')
    # log_prefix          Log path prefix.

    Set Auto Reboot  1
    Inject Error Through HOST  ${fir}  ${chip_address}  ${threshold_limit}
    ...  ${master_proc_chip}
    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted
    Wait for OS
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    Delete All BMC Dump
    Verify And Clear Gard Records On HOST

Fetch FIR Address Translation Value
    [Documentation]  Fetch FIR address translation value through HOST.
    [Arguments]  ${fir}  ${target_type}
    # Description of argument(s):
    # fir                  FIR (Fault isolation register) value (e.g. '2011400').
    # core_id              Core ID (e.g. '9').
    # target_type          Target type (e.g. 'EX', 'EQ', 'C').

    Login To OS Host
    Copy Address Translation Utils To HOST OS

    # Fetch processor chip IDs.
    ${proc_chip_id}=  Get ProcChipId From OS  Processor  ${master_proc_chip}
    # Example output:
    # 00000000

    ${core_ids}=  Get Core IDs From OS  ${proc_chip_id[-1]}
    # Example output:
    #./probe_cpus.sh | grep 'CHIP ID: 0' | cut -c21-22
    # ['14', '15', '16', '17']

    # Ignoring master core ID.
    ${output}=  Get Slice From List  ${core_ids}  1
    # Feth random non-master core ID.
    ${core_ids_sub_list}=   Evaluate  random.sample(${core_ids}, 1)  random
    ${core_id}=  Get From List  ${core_ids_sub_list}  0
    ${translated_fir_addr}=  FIR Address Translation Through HOST
    ...  ${fir}  ${core_id}  ${target_type}

    [Return]  ${translated_fir_addr}

RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...  ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...  ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...  ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On  quiet=${1}
    # Adding delay after host bring up.
    Sleep  60s

RAS Suite Setup
    [Documentation]  Create RAS log directory to store all RAS test logs.

    ${RAS_LOG_DIR_PATH}=  Catenate  ${EXECDIR}/RAS_logs/
    Set Suite Variable  ${RAS_LOG_DIR_PATH}
    Set Suite Variable  ${master_proc_chip}  False

    Create Directory  ${RAS_LOG_DIR_PATH}
    OperatingSystem.Directory Should Exist  ${RAS_LOG_DIR_PATH}
    Empty Directory  ${RAS_LOG_DIR_PATH}

    Should Not Be Empty  ${ESEL_BIN_PATH}
    Set Environment Variable  PATH  %{PATH}:${ESEL_BIN_PATH}

    # Boot to Os.
    REST Power On  quiet=${1}

    # Check Opal-PRD service enabled on host.
    ${opal_prd_state}=  Is Opal-PRD Service Enabled
    Run Keyword If  '${opal_prd_state}' == 'disabled'
    ...  Enable Opal-PRD Service On HOST

RAS Suite Cleanup
    [Documentation]  Perform RAS suite cleanup and verify that host
    ...              boots after test suite run.

    # Boot to OS.
    REST Power On  quiet=${1}
    Delete Error Logs
    Gard Operations On OS  clear all
