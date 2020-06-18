*** Settings ***
Documentation    Test RAS sanity scenarios.

Resource        ../../lib/openbmc_ffdc.robot
Resource        ../../lib/openbmc_ffdc_utils.robot
Resource        ../../lib/openbmc_ffdc_methods.robot
Resource        ../../lib/ras/host_utils.robot
Resource        ../../openpower/ras/ras_utils.robot
Library         ../../lib/utils.py
Variables       ../../lib/ras/variables.py
Variables       ../../data/variables.py

Suite Setup      Suite Setup Execution
Test Setup       Printn
Test Teardown    FFDC On Test Case Fail
Suite Teardown   Suite Setup Teardown

*** Variables ***
${proc_chip_id}    0

# mention count to read system memory.
${count}           128

*** Test Cases ***

Test BMC Getscom
    [Documentation]  Do getscom operation.
    [Tags]  Test_BMC_Getscom
    ${value}=  Get From Dictionary  ${ERROR_INJECT_DICT}  MCACALIFIR_RECV1
    Pdbg  -p${proc_chip_id} getscom 0x${value[0]}

Test BMC Getcfam
    [Documentation]  Do getcfam operation.
    [Tags]  Test_BMC_Getcfam
    Pdbg  -p${proc_chip_id} getcfam 0x${cfam_address}

Test BMC Getmem
    [Documentation]  Do getmem operation.
    [Tags]  Test_BMC_Getmem
    Pdbg  -p${proc_chip_id} getmem 0x${mem_address} ${count}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

     Redfish.Login
     Redfish Power On


Suite Setup Teardown
    [Documentation]  Do the suite setup.

     Redfish.Logout
