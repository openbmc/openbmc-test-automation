*** Settings ***
Documentation     Utilities for power management tests.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot


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
    ${power_limit}=  Convert To Integer  ${watt_str}
    [Return]  ${power_limit}


Set DCMI Power Limit
    [Documentation]  Set system power limit via IPMI DCMI command.
    [Arguments]  ${power_limit}
    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${power_limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_limit}
    ...  msg=Faied setting dcmi power limit to ${power_limit} watts.


Activate DCMI Power
    [Documentation]  Activate DCMI power limiting.

    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    ${good_response}  Set Variable  successfully activated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power activate.


Is DCMI Power Activated
    [Documentation]  Fail if DCMI power limiting is not activated.

    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  Power Limit Active
    Should Contain  ${resp}  ${good_response}  msg=DCMI power is not active.


Deactivate DCMI Power
    [Documentation]  Deactivate DCMI power power limiting.

    ${resp}=  Run External IPMI Standard Command  dcmi power deactivate
    ${good_response}  Set Variable  successfully deactivated
    Should Contain  ${resp}  ${good_response}
    ...  msg=Command failed: dcmi power deactivater.


Is DCMI Power Deactivated
    [Documentation]  Fail if DCMI power limiting is not deactivated.

    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${resp}=  Get Lines Containing String  ${output}  Current Limit State:
    ${good_response}=  Catenate  No Active Power Limit
    Should Contain  ${resp}  ${good_response}
    ...  msg=DCMI power is not deactivated.


OCC Tool Upload Setup
    [Documentation]  Upload occtoolp9 to /tmp on the OS.

    ${cmd}=  Catenate  cd /tmp ; wget --no-check-certificate -q
    ...  -Oocctoolp9 --content-disposition
    ...  https://github.com/open-power/occ/raw/master/src/tools/occtoolp9
    ...  ; chmod 777 occtoolp9
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}  print_out=${1}
