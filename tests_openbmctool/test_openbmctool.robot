*** Settings ***
Documentation     Verify openbmctool.py functionality.

Library           ../lib/gen_print.py
Library           ../lib/gen_robot_print.py
Library           ../lib/openbmctool_utils.py
Resource          ../lib/resource.txt

*** Variables ***

${min_num_sensors}  ${30}

*** Test Cases ***

Verify FRU Status
    [Documentation]  Verify that the fru status command works.
    [Tags]  Verify_FRU_Status

    Rprintn
    ${rc}  ${output}=  Openbmctool Execute Command  fru status | egrep -v '^$|^Component' | wc -l
    ${num_sensors}=  Convert to Integer  ${output}
    Rprint Vars  num_sensors
    Should Be True  ${num_sensors} >= ${min_num_sensors}
    ...  msg=There should be at least ${min_num_sensors} sensors.
