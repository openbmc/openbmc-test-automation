*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../lib/ipmi_client.robot

*** Variables ***

${FRU_NAME}       dimm01 dimm02 cpu0 cpu1  motherboard

*** Test Cases ***

Test FRU Device Name
    [Documentation]  Search FRU for device name
    [Tags]  Test_FRU_Device_Name

    ${output}=  Run External IPMI Standard Command  fru
    Should Contain  ${output}  ${FRU_NAME}  msg=Fail: Given FRU device ${FRU_NAME} not found
