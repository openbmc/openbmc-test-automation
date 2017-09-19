*** Settings ***
Documentation     Utilities for power management tests.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot

*** Variables ***


*** Keywords ***

Get DCMI Power Limit
    [Documentation]  Get the current system DCMI power limit setting.
    # This keyword fetches the Power Limit out of the get_limit response.
    # For example, the value 500 is returned from the following:
    #  Current Limit State: No Active Power Limit
    #  Exception actions:   Hard Power Off & Log Event to SEL
    #  Power Limit:         500   Watts
    #  Correction time:     0 milliseconds
    #  Sampling period:     0 seconds
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Power Limit:
    ${resp_len}=  Get Length  ${resp}
    Should Be True  ${resp_len} > 0
    ...  msg=The power limit value was not returned by "dcmi power get_limit"
    ${watt_str}=  Remove String  ${resp}  Power Limit:  Watts
    ${pwr_limit}=  Convert To Integer  ${watt_str}
    [Return]  ${pwr_limit}


Set DCMI Power Limit
    [Documentation]  Set system power limit via DCMI.
    [Arguments]  ${limit}
    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${limit}
    ...  msg=Command failed: dcmi power set_limit limit ${limit}


Activate DCMI Power
    [Documentation]  Activate DCMI power power limiting.
    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    ${good_response}  Set Variable  successfully activated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power activate


Is DCMI Power Activated
    [Documentation]  Determins if DCMI power limiting is activated.
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  Power Limit Active
    Should Contain  ${resp}  ${good_response}  msg=DCMI power is not active


Is DCMI Power Deactivated
    [Documentation]  Determins if DCMI power limiting is deactivated.
    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  No Active Power Limit
    Should Contain  ${resp}  ${good_response}
    ...  msg=DCMI power is not deactivated


Deactivate DCMI Power
    [Documentation]  Deactivate DCMI power power limiting.
    ${resp}=  Run External IPMI Standard Command  dcmi power deactivate
    ${good_response}  Set Variable  successfully deactivated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power deactivate


Power On And Upload Occtool
    [Documentation]  Power on the OS and upload occtoolp9 to /tmp.
    ${cmd}=  Catenate  cd /tmp ; wget --no-check-certificate -q
    ...  -Oocctoolp9 --content-disposition
    ...  https://github.com/open-power/occ/raw/master/src/tools/occtoolp9
    ...  ; chmod 777 occtoolp9
    REST Power On  stack_mode=skip
    Start SOL Console Logging
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  print_out=${1}
