*** Settings ***
Documentation       This suite tests error log callout handling when checkstop
...                 is injected through HOST/BMC and BMC rebooted.

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/openbmc_ffdc_utils.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Resource            ../../openpower/ras/ras_utils.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py

Suite Setup         RAS Suite Setup
Test Setup          RAS Test Setup
Test Teardown       FFDC On Test Case Fail
Suite Teardown      RAS Suite Cleanup

Force Tags          Reboot_RAS

*** Test Cases ***
Verify Host Unrecoverable Callout Handling At Reboot
    [Documentation]  Verify host unrecoverable callout handling at reboot.
    [Tags]  Verify_Unrecoverable_Callout_Handling_At_Reboot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L2FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l2fir_ue
    Inject Unrecoverable Error  HOST  ${translated_fir}
    ...  ${value[1]}  1  ${value[2]}  ${err_log_path}  ${1}

Verify Pdbg Unrecoverable Callout Handling At Reboot
    [Documentation]  Verify unrecoverable callout handling
    ...              with pdbg tool at reboot.
    [Tags]  Verify_Pdbg_Unrecoverable_Callout_Handling_At_Reboot

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  L3FIR_UE
    ${translated_fir}=  Fetch FIR Address Translation Value  ${value[0]}  EX
    ${err_log_path}=  Catenate  ${RAS_LOG_DIR_PATH}l3fir_ue
    Inject Unrecoverable Error  BMC  ${translated_fir}
    ...  ${value[1]}  1  ${value[2]}  ${err_log_path}  ${1}
