*** Settings ***
Documentation    Test RAS sanity scenarios.

Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/openbmc_ffdc_utils.robot
Resource        ../../lib/openbmc_ffdc_methods.robot
Variables       ../../lib/ras/variables.py
Variables       ../../data/variables.py
Resource        ../../lib/ras/host_utils.robot
Resource        ../../openpower/ras/ras_utils.robot

Test Setup       Printn
Suite Setup      Sanity RAS Setup
Test Teardown    FFDC On Test Case Fail


*** Variables ***
${proc_chip_id}    0
${count}           128

*** Test Cases ***

Test BMC Getscom 
    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1
    BMC Getscom  ${proc_chip_id}  ${value[0]}

Test BMC Getcfam
    BMC Getcfam  ${proc_chip_id}  ${cfam_address}

Test BMC Getmem
    BMC Getmem  ${proc_chip_id}  ${mem_address}  ${count}

*** Keywords ***

Sanity RAS Setup

    REST Power On
