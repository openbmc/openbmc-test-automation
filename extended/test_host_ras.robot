*** Settings ***
Documentation       This suite tests checkstop operations through HOST.
Resource            ../lib/utils.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/ras/host_utils.robot
Resource            ../lib/resource.txt
Resource            ../lib/state_manager.robot
Resource            ../lib/openbmc_ffdc_methods.robot
Resource            ../lib/rest_client.robot
Resource            ../lib/boot_utils.robot
Variables           ../lib/ras/variables.py

Library             DateTime
Library             OperatingSystem

Suite Setup         RAS Suite Setup
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail
Suite Teardown      RAS Suite Cleanup

*** Variables ***

${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

###  MCACALIFIR related error injection ###

Verify Recoverable Callout Handling For MCA With Threshold 1
    [Documentation]  Verify Recoverable Callout Handling For MCA With
    ...              Threshold 1. 
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCA_With_Threshold_1

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For MCA With Threshold 32 
    [Documentation]  Verify Recoverable Callout Handling For MCA With
    ...              Threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCA_With_Threshold_32

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}


Verify Unrecoverable Callout Handling For MCA
    [Documentation]  Verify Unrecoverable Callout Handling For MCA.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_MCA

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

###  MCIFIR related error injection ###

Verify Recoverable Callout Handling For MCI With Threshold 1
    [Documentation]  Verify Recoverable Callout Handling For MCI With
    ..               Threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_MCI_With_Threshold_1

    ${value}=  Get From Dictionary  ${Test_array}  MCS_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcifir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Unrecoverable Callout Handling For MCI
    [Documentation]  Verify Unrecoverable Callout Handling For MCI.
    [Tags]  Verify_Unrecoverable_Callout_Handling_For_MCI 
    ${value}=  Get From Dictionary  ${Test_array}  MCS_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcifir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

###  NXDMAENGFIR related error injection ###

Verify Recoverable Callout Handling For NXDMAENG With Threshold 1
    [Documentation]  Verify Recoverable Callout Handling For NXDMAENG With
    ...              Threshold 1.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_1

    ${value}=  Get From Dictionary  ${Test_array}  NX_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}nxfir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


Verify Recoverable Callout Handling For NXDMAENG With Threshold 32
    [Documentation]  Verify Recoverable Callout Handling For NXDMAENG With
    ...              Threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_32

    ${value}=  Get From Dictionary  ${Test_array}  NX_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}nxfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

### CXAFIR related error injection ###

Verify Recoverable Callout Handling For CXA With Threshold 5
    [Documentation]  Verify Recoverable Callout Handling For CXA With
    ...              Threshold 5.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CXA_With_Threshold_5

    ${value}=  Get From Dictionary  ${Test_array}  CXA_RECV5
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}cxafir_th5
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}   ${value[1]}  5  ${value[2]}  ${err_log_path}

Verify Recoverable Callout Handling For CXA With Threshold 32
    [Documentation]  Verify Recoverable Callout Handling For CXA With
    ...              Threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_CXA_With_Threshold_32

    ${value}=  Get From Dictionary  ${Test_array}  CXA_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}cxafir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

###  OBUSFIR  related error injection ###

Verify Recoverable Callout Handling For OBUS With Threshold 32
    [Documentation]  Verify Recoverable Callout Handling For OBUS With
    ...              Threshold 32.
    [Tags]  Verify_Recoverable_Callout_Handling_For_OBUS_With_Threshold_32

    ${value}=  Get From Dictionary  ${Test_array}  OBUS_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}obusfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

### NPU0FIR related error injection ###

Verify Recoverable Callout Handling For NPU0 With Threshold 5
    [Documentation]  Verify Recoverable Callout Handling For NPU0 With
    ...              Threshold 32.
    [Tags]  Verify Recoverable Callout Handling For NPU0 With Threshold 5

    ${value}=  Get From Dictionary  ${Test_array}  NPU0_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}npu0fir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

*** Keywords ***
Inject Error Through HOST
    [Documentation]  Inject checkstop on processor through HOST.
    ...              Test sequence:
    ...              1. Boot To HOST
    ...              2. Clear any existing gard records
    ...              3. Inject Error on processor/centaur
    [Arguments]      ${fri}  ${address}  ${th_limit}
    # Description of arguments:
    # fri            FRI value (e.g. 2011400).
    # address        chip address (e.g ${value[1]}).

    Delete Error Logs
    Login To OS Host
    Gard Operations On OS  clear all

    # Fetch Processor chip IDs.
    ${output}=  Get ChipID From OS  Processor
    ${proc_ids}=  Split String  ${output}
    ${proc_id}=  Get From List  ${proc_ids}  1

    ${th_limit}=  Convert To Integer  ${th_limit}
    :FOR  ${i}  IN RANGE  ${th_limit}
    \   Run Keyword  Putscom Through OS  ${proc_id}  ${fri}  ${address}
    \   Sleep  3s
    Sleep  30s

Verify And Clear Gard Records On HOST
    [Documentation]  Verify And Clear gard records on HOST.

    Login To OS Host
    ${output}=  Gard Operations On OS  list
    Should Not Contain  ${output}  'No GARD entries to display'
    Gard Operations On OS  clear all

Verify Error Log Entry
    [Documentation]  Verify error log entry & signature description.
    [Arguments]  ${signature_desc}  ${logpath}

    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/list
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    Collect eSEL Log  ${logpath}
    ${logpath}=  Catenate  ${logpath}esel.txt
    ${rc}  ${output} =  Run and Return RC and Output
    ...     cat ${logpath} | grep ${signature_desc}
    Should Not Be Empty  ${output}

Inject Recoverable Error With Thershold Limit Through Host
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting
    ...              2. Inject Error on processor/centaur
    ...              3. Check If HOST is running.
    ...              4. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${fri}  ${address}  ${th_limit}  ${signature_desc}
    ...              ${logpath}
    # Description of arguments:
    # fri            FRI value (e.g. 2011400).
    # address        Chip address (e.g ${value[1]}).
    # th_limit       Thershold limit (e.g 1, 5, 32).
    # signature_desc Error Log signature description.
    # logpath        Log path.

    Set Auto Reboot  1
    Inject Error Through HOST  ${fri}  ${address}  ${th_limit}
    Is Host Running
    ${output}=  Gard Operations On OS  list
    Should Contain  ${output}  No GARD
    Verify Error Log Entry  ${signature_desc}  ${logpath}


Inject Unrecoverable Error Through Host
    [Documentation]  Inject and verify recoverable error on processor through
    ...              host.
    ...              Test sequence:
    ...              1. Enable Auto Reboot Setting
    ...              2. Inject Error on processor/centaur
    ...              3. Check If HOST is rebooted.
    ...              4. Verify error log entry & signature description.
    ...              4. Verify & clear gard records.
    [Arguments]      ${fri}  ${address}  ${th_limit}  ${signature_desc}
    ...              ${logpath}
    # Description of arguments:
    # fri            FRI value (e.g. 2011400).
    # address        Chip address (e.g ${value[1]}).
    # th_limit       Thershold limit (e.g 1, 5, 32).
    # signature_desc Error Log signature description.
    # logpath        Log path.

    Set Auto Reboot  1
    Inject Error Through HOST  ${fri}  ${address}  ${th_limit}
    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted
    Wait for OS
    Verify And Clear Gard Records On HOST
    Verify Error Log Entry  ${signature_desc}  ${logpath}


RAS Test SetUp
    [Documentation]  Validates input parameters.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

RAS Suite Setup
    [Documentation]  Create RAS Log directory to store all RAS test logs.

    ${RAS_LOG_PATH}=  Catenate  ${EXECDIR}/RAS_logs/
    Set Suite Variable  ${RAS_LOG_PATH}
    Create Directory  ${RAS_LOG_PATH}
    OperatingSystem.Directory Should Exist  ${RAS_LOG_PATH}
    Empty Directory  ${RAS_LOG_PATH}

RAS Suite Cleanup
    [Documentation]  Perform RAS suite cleanup.

    # Boot to OS.
    REST Power On
    Delete Error Logs
    Login To OS Host
    Gard Operations On OS  clear all
