*** Settings ***
Documentation       This suite tests checkstop operations through HOST.
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ras/host_utils.robot
Resource            ../lib/resource.txt
Resource            ../lib/state_manager.robot
Resource            ../lib/openbmc_ffdc_methods.robot
Resource            ../lib/boot_utils.robot
Variables           ../lib/ras/variables.py

Library             DateTime
Library             OperatingSystem
Library             random
Library             Collections

Suite Setup         RAS Suite Setup
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail
Suite Teardown      RAS Suite Cleanup

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


Verify Unrecoverable Callout Handling For NXDMAENG
    [Documentation]  Verify unrecoverable callout handling for NXDMAENG.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_NXDMAENG

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_ue
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

*** Keywords ***

Inject Error Through HOST
    [Documentation]  Inject checkstop on processor through HOST.
    ...              Test sequence:
    ...              1. Boot To HOST
    ...              2. Clear any existing gard records
    ...              3. Inject Error on processor/centaur
    [Arguments]      ${fir}  ${chip_address}  ${threshold_limit}
    # Description of argument(s):
    # fir                 FIR (Fault isolation register) value (e.g. 2011400).
    # chip_address        chip address (e.g 2000000000000000).
    # threshold_limit     Threshold limit (e.g 1, 5, 32).

    Delete Error Logs
    Login To OS Host
    Gard Operations On OS  clear all

    # Fetch processor chip IDs.
    ${chip_ids}=  Get ProcChipId From OS  Processor
    ${proc_ids}=  Split String  ${chip_ids}
    ${proc_id}=  Get From List  ${proc_ids}  1

    ${threshold_limit}=  Convert To Integer  ${threshold_limit}
    :FOR  ${i}  IN RANGE  ${threshold_limit}
    \  Run Keyword  Putscom Operations On OS  ${proc_id}  ${fir}  ${chip_address}
    # Adding delay after each error injection.
    \  Sleep  10s
    # Adding delay to get error log after error injection.
    Sleep  120s

Verify And Clear Gard Records On HOST
    [Documentation]  Verify And Clear gard records on HOST.

    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all

Verify Error Log Entry
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${signature_desc}  ${log_prefix}
    # Description of argument(s):
    # signature_desc  Error log signature description.
    # log_prefix      Log path prefix.

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    Collect eSEL Log  ${log_prefix}
    ${error_log_file_path}=  Catenate  ${log_prefix}esel.txt
    ${rc}  ${output} =  Run and Return RC and Output
    ...  grep -i ${signature_desc} ${error_log_file_path}
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
    ...              4. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
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
    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted
    Wait for OS
    Verify And Clear Gard Records On HOST
    Verify Error Log Entry  ${signature_desc}  ${log_prefix}

Fetch FIR Address Translation Value
    [Documentation]  Fetch FIR address translation value through HOST.
    [Arguments]  ${proc_chip_id}  ${fir}  ${target_type}
    # Description of argument(s):
    # proc_chip_id      Processor chip ID (e.g '0', '8').
    # fir               FIR (Fault isolation register) value (e.g. 2011400).
    # core_id           Core ID (e.g. 9).
    # target_type       Target type (e.g. 'EX', 'EQ', 'C').

    Login To OS Host
    Copy Address Translation Utils To HOST OS

    ${core_ids}=  Get Core IDs From OS  0
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

RAS Suite Setup
    [Documentation]  Create RAS log directory to store all RAS test logs.


    ${RAS_LOG_DIR_PATH}=  Catenate  ${EXECDIR}/RAS_logs/
    Set Suite Variable  ${RAS_LOG_DIR_PATH}
    Create Directory  ${RAS_LOG_DIR_PATH}
    OperatingSystem.Directory Should Exist  ${RAS_LOG_DIR_PATH}
    Empty Directory  ${RAS_LOG_DIR_PATH}

RAS Suite Cleanup
    [Documentation]  Perform RAS suite cleanup and verify that host
    ...              boots after test suite run.

    # Boot to OS.
    REST Power On  quiet=${1}
    Delete Error Logs
    Gard Operations On OS  clear all
