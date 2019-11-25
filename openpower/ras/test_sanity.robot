*** Settings ***
Documentation       Test RAS sanity scenarios.

Variables           ../../lib/ras/variables.py
Resource            ../../openpower/ras/ras_utils.robot

Suite Setup         RAS Suite Setup
Test Setup          Printn

*** Variables ***
${proc_chip_id}    0
${count}           128

*** Test Cases ***

Test BMC Sanity

    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1

    pdbg  -p${proc_chip_id} getscom 0x${value[0]}
    pdbg  -p${proc_chip_id} putscom 0x${value[0]} 0x${value[1]}
    pdbg  -p${proc_chip_id} getcfam 0x${cfam_fru}
    pdbg  -p${proc_chip_id} -S getmem 0x${mem_fru} ${count}
