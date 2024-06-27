*** Settings ***
Documentation       Test RAS sanity scenarios.

Resource            ../../lib/bmc_redfish_resource.robot
Resource            ../../lib/openbmc_ffdc.robot
Variables           ../../lib/ras/variables.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Setup Teardown
Test Setup          Printn
Test Teardown       FFDC On Test Case Fail


*** Variables ***
${proc_chip_id}     0

# mention count to read system memory.
${count}            128


*** Test Cases ***
Test BMC Getscom
    [Documentation]    Do getscom operation.
    [Tags]    test_bmc_getscom
    ${value}=    Get From Dictionary    ${ERROR_INJECT_DICT}    MCACALIFIR_RECV1
    Pdbg    -p${proc_chip_id} getscom 0x${value[0]}

Test BMC Getcfam
    [Documentation]    Do getcfam operation.
    [Tags]    test_bmc_getcfam
    Pdbg    -p${proc_chip_id} getcfam 0x${cfam_address}

Test BMC Getmem
    [Documentation]    Do getmem operation.
    [Tags]    test_bmc_getmem
    Pdbg    -p${proc_chip_id} getmem 0x${mem_address} ${count}


*** Keywords ***
Suite Setup Execution
    [Documentation]    Do the suite setup.

    Redfish.Login
    Redfish Power On

Suite Setup Teardown
    [Documentation]    Do the suite setup.

    Redfish.Logout
