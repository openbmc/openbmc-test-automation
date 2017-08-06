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
Test Setup         RAS Test Setup
Test Teardown      FFDC On Test Case Fail

*** Variables ***

${HOST_SETTINGS}    ${SETTINGS_URI}host0

*** Test Cases ***

###  MCACALIFIR related error injection ###

Verify MCACALIFIR RE With TH Limit 1
    [Documentation]  Verify MCACALIFIR RE With TH Limit 1 through HOST.
    [Tags]  Inject_MCACALIFIR_RE_With_TH_Limit_1

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${DES_MCA_RECV1}  ${err_log_path}

Verify MCACALIFIR RE With TH Limit 32
    [Documentation]  Verify MCACALIFIR RE With TH Limit 32 through HOST.
    [Tags]  Inject_MCACALIFIR_RE_With_TH_Limit_32

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${DES_MCA_RECV32}  ${err_log_path}


Verify MCACALIFIR UE
    [Documentation]  Verify MCACALIFIR UE through HOST.
    [Tags]  Inject_MCACALIFIR_UE

    ${value}=  Get From Dictionary  ${Test_array}  MCACALIFIR_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcacalfir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${DES_MCA_UE}  ${err_log_path}

###  MCIFIR related error injection ###

Verify MCIFIR RE With TH Limit 1
    [Documentation]  Verify MCIFIR RE With TH Limit 1 through HOST.
    [Tags]  Inject_MCIFIR_RE_With_TH_Limit_1

    ${value}=  Get From Dictionary  ${Test_array}  MCS_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcifir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${DES_MCS_RECV1}  ${err_log_path}

Verify MCIFIR UE
    [Documentation]  Verify MCIFIR UE through HOST.
    [Tags]  Inject_MCIFIR_UE
    ${value}=  Get From Dictionary  ${Test_array}  MCS_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}mcifir
    Inject Unrecoverable Error Through Host
    ...  ${value[0]}  ${value[1]}  1  ${DES_MCS_UE}  ${err_log_path}

###  NXDMAENGFIR related error injection ###

Verify NXDMAENGFIR RE With TH Limit 1
    [Documentation]  Verify NXDMAENGFIR RE With TH Limit 1 through HOST.
    [Tags]  Inject_NXDMAENGFIR_RE_With_TH_Limit_1

    ${value}=  Get From Dictionary  ${Test_array}  NX_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}nxfir_th1
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  1  ${DESC_NX_RECV1}  ${err_log_path}


Verify NXDMAENGFIR RE With TH Limit 32
    [Documentation]  Verify NXDMAENGFIR RE With TH Limit 32 through HOST.
    [Tags]  Inject_NXDMAENGFIR_RE_With_TH_Limit_32

    ${value}=  Get From Dictionary  ${Test_array}  NX_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}nxfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${DESC_NX_RECV32}  ${err_log_path}

### CXAFIR related error injection ###
Verify CXAFIR RE With TH Limit 5
    [Documentation]  Verify CXAFIR RE With TH Limit 5 through HOST.
    [Tags]  Inject_CXAFIR_RE_With_TH_Limit_5

    ${value}=  Get From Dictionary  ${Test_array}  CXA_RECV5
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}cxafir_th5
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}   ${value[1]}  5  ${DESC_CXA_RECV5}  ${err_log_path}

Verify CXAFIR RE With TH Limit 32
    [Documentation]  Verify CXAFIR RE With TH Limit 32 through HOST.
    [Tags]  Inject_CXAFIR_RE_With_TH_Limit_32

    ${value}=  Get From Dictionary  ${Test_array}  CXA_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}cxafir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${DESC_CXA_RECV32}  ${err_log_path}

###  OBUSFIR  related error injection ###

Verify OBUSFIR RE With TH Limit 32
    [Documentation]  Verify OBUSFIR RE With TH Limit 32 through HOST.
    [Tags]  Inject_OBUSFIR_RE_With_TH_Limit_32

    ${value}=  Get From Dictionary  ${Test_array}  OBUS_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_PATH}obusfir_th32
    Inject Recoverable Error With Thershold Limit Through Host
    ...  ${value[0]}  ${value[1]}  32  ${DES_OBUS_RECV32}  ${err_log_path}

*** Keywords ***
Inject Error Through HOST
    [Documentation]  Inject checkstop on processor through HOST.
    ...              Test sequence:
    ...              1. Boot To HOST
    ...              2. Clear any existing gard records
    ...              3. Inject Error on processor/centaur
    [Arguments]      ${fru}  ${address}  ${th_limit}
    # Description of arguments:
    # fru            FRU value (e.g. 2011400).
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
    \   Run Keyword  Putscom Through OS  ${proc_id}  ${fru}  ${address}
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
    ${rc}  ${output} = 	Run and Return RC and Output
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
    [Arguments]      ${fru}  ${address}  ${th_limit}  ${signature_desc}  ${logpath}
    # Description of arguments:
    # fru            FRU value (e.g. 2011400).
    # address        Chip address (e.g ${value[1]}).
    # th_limit       Thershold limit (e.g 1, 5, 32).
    # signature_desc Error Log signature description.
    # logpath        Log path.

    Set Auto Reboot  yes
    Inject Error Through HOST  ${fru}  ${address}  ${th_limit}
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
    [Arguments]      ${fru}  ${address}  ${th_limit}  ${signature_desc}  ${logpath}

    Set Auto Reboot  yes
    Inject Error Through HOST  ${fru}  ${address}  ${th_limit}
    Wait Until Keyword Succeeds  500 sec  20 sec  Is Host Rebooted
    Wait for OS
    Verify And Clear Gard Records On OS
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
