*** Settings ***
Documentation       This suite tests checkstop operations through HOST.
Resource            ../../lib/utils.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/ras/host_utils.robot
Resource            ../../lib/resource.txt
Resource            ../../lib/state_manager.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Resource            ../../lib/boot_utils.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py
Resource            ../../lib/dump_utils.robot

Library             DateTime
Library             OperatingSystem
Library             random
Library             Collections

Suite Setup         RAS Suite Setup
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail
Suite Teardown      RAS Suite Cleanup

Force Tags          Host_RAS
*** Variables ***
${stack_mode}       normal

*** Test Cases ***
# Memory channel (MCACALIFIR) related error injection.

Verify Recoverable Callout Handling For MCA With Threshold 1
    [Documentation]  Verify recoverable callout handling for MCACALIFIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCA_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


Verify Recoverable Callout Handling For MCA With Threshold 32
    [Documentation]  Verify recoverable callout handling for MCACALIFIR with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCA_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For MCA
    [Documentation]  Verify unrecoverable callout handling for MCACALIFIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_MCA

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  Memory buffer (MCIFIR) related error injection.

Verify Recoverable Callout Handling For MCI With Threshold 1
    [Documentation]  Verify recoverable callout handling for mci with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCI_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCS_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For MCI
    [Documentation]  Verify unrecoverable callout handling for mci.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_MCI

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCS_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# CAPP accelerator (CXAFIR) related error injection.

Verify Recoverable Callout Handling For CXA With Threshold 5
    [Documentation]  Verify recoverable callout handling for  CXA with
    ...              threshold 5.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CXA_With_Threshold_5

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_RECV5
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_th5
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  5  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For CXA With Threshold 32
    [Documentation]  Verify recoverable callout handling for  CXA with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CXA_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For CXA
    [Documentation]  Verify unrecoverable callout handling for CXAFIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_CXA

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_ue
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  OBUSFIR  related error injection.

Verify Recoverable Callout Handling For OBUS With Threshold 32
    [Documentation]  Verify recoverable callout handling for  OBUS with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_OBUS_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  OBUS_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}obusfir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

# Nvidia graphics processing units (NPU0FIR) related error injection.

Verify Recoverable Callout Handling For NPU0 With Threshold 32
    [Documentation]  Verify recoverable callout handling for  NPU0 with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NPU0_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NPU0_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}npu0fir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

#  Nest accelerator NXDMAENGFIR related error injection.

Verify Recoverable Callout Handling For NXDMAENG With Threshold 1
    [Documentation]  Verify recoverable callout handling for  NXDMAENG with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


Verify Recoverable Callout Handling For NXDMAENG With Threshold 32
    [Documentation]  Verify recoverable callout handling for  NXDMAENG with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For NXDMAENG
    [Documentation]  Verify unrecoverable callout handling for NXDMAENG.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_NXDMAENG

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_ue
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


#  L2FIR related error injection.

Verify Recoverable Callout Handling For L2FIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for L2FIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_L2FIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For L2FIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L2FIR with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_L2FIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For L2FIR
    [Documentation]  Verify unrecoverable callout handling for L2FIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_L2FIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_ue
    Inject Unrecoverable Error Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  L3FIR related error injection.

Verify Recoverable Callout Handling For L3FIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for L3FIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_L3FIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For L3FIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L3FIR with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_L3FIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For L3FIR
    [Documentation]  Verify unrecoverable callout handling for L3FIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_L3FIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_ue
    Inject Unrecoverable Error Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# On chip controller (OCCFIR) related error injection.

Verify Recoverable Callout Handling For OCC With Threshold 1
    [Documentation]  Verify recoverable callout handling for OCCFIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_OCC_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  OCCFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}occfir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Core management engine (CMEFIR) related error injection.

Verify Recoverable Callout Handling For CMEFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for CMEFIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CMEFIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CMEFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cmefir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Nest control vunit (NCUFIR) related error injection.

Verify Recoverable Callout Handling For NCUFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for NCUFIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NCUFIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For NCUFIR
    [Documentation]  Verify unrecoverable callout handling for NCUFIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_NCUFIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_ue
    Inject Unrecoverable Error Through Host
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Core FIR related error injection.

Verify Recoverable Callout Handling For CoreFIR With Threshold 5
    [Documentation]  Verify recoverable callout handling for CoreFIR with
    ...              threshold 5.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CoreFIR_With_Threshold_5

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_RECV5
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_th5
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  5  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For CoreFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for CoreFIR with
    ...              threshold 1.
    [Tags]  Verify_Recoverable_Callout_CoreFIR_Handling_For_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_th1
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For CoreFIR
    [Documentation]  Verify unrecoverable callout handling for CoreFIR.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_CoreFIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_ue
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For EQFIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L3FIR with
    ...              threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_EQFIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  EQFIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EQ
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}eqfir_th32
    Inject Recoverable Error With Threshold Limit Through Host
    ...  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}


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

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output}=  Run and Return RC and Output
    ...  grep -i ${signature_desc} ${error_log_file_path}
    Should Be Equal  ${rc}  ${0}
    Should Not Be Empty  ${output}

Inject Recoverable Error With Threshold Limit Through Host
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting
    ...              2. Inject Error on processor/centaur
    ...              3. Check If HOST is running.
    ...              4. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${fir}  ${chip_address}  ${threshold_limit}
    ...              ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # fir                 FIR (Fault isolation register) value (e.g. 2011400).
    # chip_address        Chip address (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).
    # signature_desc      Error log signature description.
    # log_prefix          Log path prefix.

    Set Auto Reboot  1
    Inject Error Through HOST  ${fir}  ${chip_address}  ${threshold_limit}
    ...  ${master_proc_chip}

    Is Host Running
    ${output}=  Gard Operations On OS  list
    Should Contain  ${output}  No GARD
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}


Inject Unrecoverable Error Through Host
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting
    ...              2. Inject Error on processor/centaur
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
    Verify And Clear Gard Records On HOST
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}
    Delete All BMC Dump

Fetch FIR Address Translation Value
    [Documentation]  Fetch FIR address translation value through HOST.
    [Arguments]  ${fir}  ${target_type}
    # Description of argument(s):
    # fir                  FIR (Fault isolation register) value (e.g. 2011400).
    # core_id              Core ID (e.g. 9).
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
