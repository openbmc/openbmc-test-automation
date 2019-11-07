*** Settings ***
Documentation       This suite tests checkstop operations through BMC using
...                 pdbg utility during HOST Boot path.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/openbmc_ffdc_utils.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Resource            ../../openpower/ras/ras_utils.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py

Library             DateTime
Library             OperatingSystem
Library             random
Library             Collections

Suite Setup         RAS Suite Setup
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail
Suite Teardown      RAS Suite Cleanup

Force Tags          Host_boot_RAS

*** Variables ***
${stack_mode}       normal

*** Test Cases ***

Verify Pdbg Recoverable Callout Handling For MCA During Host Boot

    [Documentation]  Verify recoverable callout handling for MCACALIFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_MCA_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir_th1

    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

#  Memory buffer (MCIFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For MCI During Host Boot
    [Documentation]  Verify recoverable callout handling for MCI
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_MCI_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCI_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir_th1

    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}


Verify Pdbg Recoverable Callout Handling For NXDMAENG During Host Boot
    [Documentation]  Verify recoverable callout handling for  NXDMAENG
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NXDMAENG_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_th1

    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}


#  L2FIR related error injection.

Verify Pdbg Recoverable Callout Handling For L2FIR During Host Boot
    [Documentation]  Verify recoverable callout handling for L2FIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_L2FIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_th1

    Inject Error At HOST Boot Path  ${translated_fir}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}


# On chip controller (OCCFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For OCC During Host Boot
    [Documentation]  Verify recoverable callout handling for OCCFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_OCC_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  OCCFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}occfir_th1


    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

# Nest control vunit (NCUFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For NCUFIR During Host Boot
    [Documentation]  Verify recoverable callout handling for NCUFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NCUFIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_th1

    Inject Error At HOST Boot Path  ${translated_fir}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For NCUFIR During Host Boot
    [Documentation]  Verify unrecoverable callout handling for NCUFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_NCUFIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_ue
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For L3FIR During Host Boot
    [Documentation]  Verify unrecoverable callout handling for L3FIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_L3FIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_ue
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For L2FIR During Host Boot
    [Documentation]  Verify unrecoverable callout handling for L2FIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_L2FIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_ue
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For CXA During Host Boot
    [Documentation]  Verify unrecoverable callout handling for CXAFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_CXA_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_ue
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For MCA During Host Boot
    [Documentation]  Verify unrecoverable callout handling for MCACALIFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_MCA_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For MCI During Host Boot
    [Documentation]  Verify unrecoverable callout handling for MCI
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_MCI_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCI_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For CoreFIR During Host Boot
    [Documentation]  Verify unrecoverable callout handling for CoreFIR
    ...              using pdbg tool during Host Boot path.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_CoreFIR_During_Host_Boot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_ue
    Inject Error At HOST Boot Path  ${value[0]}  ${value[1]}
    ...  ${value[2]}  ${err_log_path}
