*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../lib/ipmi_client.robot


*** Test Cases ***

Test FRU for my device name
    [Documentation]  Search FRU for my device name
    [Tags]  Test_FRU_for_my_string

    ${output}=  Run External IPMI Standard Command  fru
    Should Contain  ${output}  ${FRU_NAME}  msg=Fail: it is not my FRU device ${FRU_NAME}

