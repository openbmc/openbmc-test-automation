*** Settings ***
Documentation    Test RAS sanity scenarios using ecmd commands.

Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/openbmc_ffdc_utils.robot
Resource        ../../lib/openbmc_ffdc_methods.robot
Resource        ../../lib/ras/host_utils.robot
Library         ../../lib/utils.py
Variables       ../../lib/ras/variables.py

Suite Setup      Redfish Power On
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail


*** Variables ***

# mention count to read system memory.
${count}           128

*** Test Cases ***

Test Ecmd Getscom
    [Documentation]  Do getscom operation through BMC.
    [Tags]  Test_Ecmd_Getscom
    Ecmd  getscom pu.c 20028440 -all

Test Ecmd Getcfam
    [Documentation]  Do getcfam operation through BMC.
    [Tags]  Test_Ecmd_Getcfam
    Ecmd  getcfam pu ${cfam_address} -all

Test Ecmd Getmemproc
    [Documentation]  Do getmemproc operation through BMC.
    [Tags]  Test_Ecmd_Getmemproc
    Ecmd  getmemproc ${mem_address} ${count}
