*** Settings ***
Documentation     Utilities for power management tests.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot


*** Keywords ***

Get DCMI Power Limit
    [Documentation]  Get the current system DCMI power limit setting.

    # This keyword returns the power limit from the dcmi get_limit command.
    # For example, if get_limit returns "Power Limit:    500   Watts",
    # the value 500 will be returned.

    # Fetch the number part only of the line that contains "Watts"
    ${cmd}=  Catenate  dcmi power get_limit | grep Watts | sed 's/[^0-9]*//g'
    ${power_limit}=  Run External IPMI Standard Command  ${cmd}
    ${resp_len}=  Get Length  ${power_limit}
    Should Be True  ${resp_len} > 0
    ...  msg=The power limit value was not returned by "dcmi power get_limit"
    [Return]  ${power_limit}


Set DCMI Power Limit And Verify
    [Documentation]  Set system power limit via IPMI DCMI command.
    [Arguments]  ${power_limit}
    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${power_limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_limit}
    ...  msg=Faied setting dcmi power limit to ${power_limit} watts.


Activate DCMI Power And Verify
    [Documentation]  Activate DCMI power limiting.

    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    Should Contain  ${resp}  successfully activated
    ...  msg=Command failed: dcmi power activate.


Fail If DCMI Power Is Not Activated
    [Documentation]  Fail if DCMI power limiting is not activated.

    ${cmd}=  Catenate  dcmi power get_limit | grep State:
    ${output}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  Power Limit Active  msg=DCMI power is not active.


Deactivate DCMI Power And Verify
    [Documentation]  Deactivate DCMI power power limiting.

    ${cmd}=  Catenate  dcmi power deactivate | grep deactivated
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  successfully deactivated
    ...  msg=Command failed: dcmi power deactivater.


Fail If DCMI Power Is Not Deactivated
    [Documentation]  Fail if DCMI power limiting is not deactivated.

    ${cmd}=  Catenate  dcmi power get_limit | grep State:
    ${output}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  No Active Power Limit
    ...  msg=DCMI power is not deactivated.


OCC Tool Upload Setup
    [Documentation]  Upload occtoolp9 to /tmp on the OS.

    ${cmd}=  Catenate  cd /tmp ; wget --no-check-certificate -q
    ...  -Oocctoolp9 --content-disposition
    ...  https://github.com/open-power/occ/raw/master/src/tools/occtoolp9
    ...  ; chmod 777 occtoolp9
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
