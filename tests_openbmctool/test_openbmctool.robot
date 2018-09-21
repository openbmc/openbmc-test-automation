*** Settings ***
Documentation    Verify openbmctool.py functionality.

Library          ../lib/gen_print.py
Library          ../lib/gen_robot_print.py
Library          ../lib/openbmctool_utils.py
Library          String
Library          OperatingSystem


Suite Setup  Suite Setup Execution


*** Variables ***

${min_number_items}  ${30}


*** Test Cases ***

Verify Openbmctool FRU Operations
    [Documentation]  Verify fru commands work.
    [Tags]  Verify_Openbmctool_FRU_Operations

    Verify FRU Status
    Verify FRU Print
    Verify FRU List
    # Known issue - openbmctool.py fru list with single fru is not working yet.
    #Verify FRU List With Single FRU


*** Keywords ***


Verify FRU Status
    [Documentation]  Verify that the fru status command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru status | egrep -v '^$|^Component' | wc -l
    Rprintn
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  frus


Verify FRU Print
    [Documentation]  Verify that the fru print command works.

    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru print | grep xyz | wc -l
    Rprintn
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  frus


Verify FRU List
    [Documentation]  Verify that the fru list command works.

    Rprintn
    ${rc}  ${num_frus}=  Openbmctool Execute Command
    ...  fru list | grep xyz | wc -l
    Rprintn
    Rprint Vars  num_frus
    Check Greater Than Minimum  ${num_frus}  frus


Verify FRU List With Single FRU
    [Documentation]  Verify that the fru list command works.

    Rprintn
    # Get the name of one fru, in this case the first fan listed.
    ${rc}  ${fruname}=  Openbmctool Execute Command
    ...  fru status | grep fan | head -1 | cut -c1-5
    ${fruname}=  Strip String  ${fruname}
    Rpvars  fruname
    Should Not Be Empty  ${fruname}  msg=Could not find a fan in fru status.
    # Get a fru list specifiying just the fan.
    ${rc}  ${output}=  Openbmctool Execute Command
    ...  fru list ${fruname} | wc -l
    ${fru_detail}=  Convert to Integer  ${output}
    Rprint Vars  fru_detail
    Should Be True  ${fru_detail} <= ${min_number_items}
    ...  msg=Too many lines reported for fru status ${fruname}
    Should Be True  ${fru_detail} > ${4}
    ...  msg=Too few lines reported for fru status ${fruname}


Check Greater Than Minimum
    [Documentation]  Check that a value is gt the minimum allowable.
    [Arguments]  ${value_to_test}  ${label}

    # Description of argument(s):
    # value_to_test  value to compart to the minimum.
    # label          name to print if failure.

    ${value_to_test}=  Convert to Integer  ${value_to_test}
    Should Be True  ${value_to_test} > ${min_number_items}
    ...  msg=There should be at least ${min_number_items} ${label}.


Suite Setup Execution
    [Documentation]  Verify setup - can we run opbmctool commands?

    # Verify can connect to host.
    ${rc}=  Run and Return RC  ping ${OPENBMC_HOST} -w 3
    Should Be Equal As Integers  ${rc}  ${0}
    ...  msg=Could not connect to BMC ${OPENBMC_HOST}.

    # Verify can find the openbmctool.
    ${rc}  ${location}=  Run and Return RC and Output   which openbmctool.py
    Should Be Equal As Integers  ${rc}  ${0}  msg=Could not find openbmtool.py

    # Verify can run commands against openbmctool.
    ${rc}  ${openbmctool_version}=  Openbmctool Execute Command  -V  quiet=1
    Should Be Equal As Integers  ${rc}  ${0}
    ...  msg=rc from openbmctool.py -V is non-zero.

    Rprintn
    Rprint vars  location  openbmctool_version  OPENBMC_HOST
