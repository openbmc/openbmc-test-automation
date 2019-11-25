*** Settings ***
Documentation    This is a sanity RAS scenarios

Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/openbmc_ffdc_utils.robot
Resource            ../../lib/openbmc_ffdc_methods.robot
Variables           ../../lib/ras/variables.py
Variables           ../../data/variables.py
Resource            ../../lib/ras/host_utils.robot
Resource            ../../openpower/ras/ras_utils.robot

Suite Setup         RAS Suite Setup

*** Variables ***
${proc_chip_id}    0
${count}           128

*** Test Cases ***

Test BMC Sanity

     ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1

     BMC Getscom  ${proc_chip_id}  ${value[0]} 
     BMC Putscom  ${proc_chip_id}  ${value[0]}  ${value[1]}
     BMC Getcfam  ${proc_chip_id}  ${cfam_fru}
     BMC Getmem  ${proc_chip_id}  ${mem_fru}  ${count}
