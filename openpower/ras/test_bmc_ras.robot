*** Settings ***
Documentation       This suite tests checkstop operations through BMC using
                    pdbg utility.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Resource            ../../lib/openbmc_ffdc_utils.robot
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

Force Tags          BMC_RAS

*** Variables ***
${stack_mode}       normal


*** Test Cases ***

# Memory Controller Async (MCACALIFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For MCA With Threshold 1
    [Documentation]  Verify recoverable callout handling for MCACALIFIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_MCA_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For MCA With Threshold 32
    [Documentation]  Verify recoverable callout handling for MCACALIFIR
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_MCA_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For MCA
    [Documentation]  Verify unrecoverable callout handling for MCACALIFIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_MCA

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcacalfir
    Inject Unrecoverable Error  BMC
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  Memory controller Interface (MCIFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For MCI With Threshold 1
    [Documentation]  Verify recoverable callout handling for MCI
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_MCI_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCI_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For MCI
    [Documentation]  Verify unrecoverable callout handling for mci
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_MCI

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCI_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}mcifir
    Inject Unrecoverable Error  BMC
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


# CAPP accelerator (CXAFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For CXA With Threshold 5
    [Documentation]  Verify recoverable callout handling for CXA
    ...              with threshold 5 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_CXA_With_Threshold_5

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_RECV5
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_th5
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  5  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For CXA With Threshold 32
    [Documentation]  Verify recoverable callout handling for CXA
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_CXA_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For CXA
    [Documentation]  Verify unrecoverable callout handling for CXAFIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_CXA

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CXA_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cxafir_ue
    Inject Unrecoverable Error  BMC
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  Optical BUS (OBUSFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For OBUS With Threshold 32
    [Documentation]  Verify recoverable callout handling for OBUS
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_OBUS_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  OBUS_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}obusfir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

# NVIDIA graphics processing units (NPU0FIR) related error injection.

Verify Pdbg Recoverable Callout Handling For NPU0 With Threshold 32
    [Documentation]  Verify recoverable callout handling for NPU0
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NPU0_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NPU0_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}npu0fir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

#  NEST accelerator DMA Engine (NXDMAENGFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For NXDMAENG With Threshold 1
    [Documentation]  Verify recoverable callout handling for NXDMAENG
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}


Verify Pdbg Recoverable Callout Handling For NXDMAENG With Threshold 32
    [Documentation]  Verify recoverable callout handling for NXDMAENG
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NXDMAENG_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_RECV32
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For NXDMAENG
    [Documentation]  Verify unrecoverable callout handling for NXDMAENG
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_NXDMAENG

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NX_UE
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}nxfir_ue
    Inject Unrecoverable Error  BMC
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  L2FIR related error injection.

Verify Pdbg Recoverable Callout Handling For L2FIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for L2FIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_L2FIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For L2FIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L2FIR
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_L2FIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For L2FIR
    [Documentation]  Verify unrecoverable callout handling for L2FIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_L2FIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_ue
    Inject Unrecoverable Error  BMC
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

#  L3FIR related error injection.

Verify Pdbg Recoverable Callout Handling For L3FIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for L3FIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_L3FIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For L3FIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L3FIR
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_L3FIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For L3FIR
    [Documentation]  Verify unrecoverable callout handling for L3FIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_L3FIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_ue
    Inject Unrecoverable Error  BMC
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# On chip controller (OCCFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For OCC With Threshold 1
    [Documentation]  Verify recoverable callout handling for OCCFIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_OCC_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  OCCFIR_RECV1
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}occfir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Core management engine (CMEFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For CMEFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for CMEFIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_CMEFIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  CMEFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}cmefir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Nest control vunit (NCUFIR) related error injection.

Verify Pdbg Recoverable Callout Handling For NCUFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for NCUFIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_NCUFIR_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For NCUFIR
    [Documentation]  Verify unrecoverable callout handling for NCUFIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_NCUFIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  NCUFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}ncufir_ue
    Inject Unrecoverable Error  BMC
    ...  ${translated_fir}  ${value[1]}  1  ${value[2]}  ${err_log_path}

# Core FIR related error injection.

Verify Pdbg Recoverable Callout Handling For CoreFIR With Threshold 5
    [Documentation]  Verify recoverable callout handling for CoreFIR
    ...              with threshold 5 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_CoreFIR_With_Threshold_5

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_RECV5
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_th5
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  5  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For CoreFIR With Threshold 1
    [Documentation]  Verify recoverable callout handling for CoreFIR
    ...              with threshold 1 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_CoreFIR_Handling_For_With_Threshold_1

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_RECV1
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_th1
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Unrecoverable Callout Handling For CoreFIR
    [Documentation]  Verify unrecoverable callout handling for CoreFIR
    ...              with pdbg tool.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_For_CoreFIR

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  COREFIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    Disable CPU States Through HOST
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}corefir_ue
    Inject Unrecoverable Error  BMC
    ...  ${value[0]}  ${value[1]}  1  ${value[2]}  ${err_log_path}

Verify Pdbg Recoverable Callout Handling For EQFIR With Threshold 32
    [Documentation]  Verify recoverable callout handling for L3FIR
    ...              with threshold 32 using pdbg tool.
    [Tags]  Verify_Pdbg_Recoverable_Callout_Handling_For_EQFIR_With_Threshold_32

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  EQFIR_RECV32
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EQ
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}eqfir_th32
    Inject Recoverable Error With Threshold Limit
    ...  BMC  ${translated_fir}  ${value[1]}  32  ${value[2]}  ${err_log_path}
