*** Settings ***
Documentation     Utilities for power management tests.

Resource          ../lib/rest_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot_utils.robot
Resource          ../lib/ipmi_client.robot
Library           ../lib/var_funcs.py


*** Keywords ***

DCMI Power Get Limits
    [Documentation]  Run dcmi power get_limit and return values as a
    ...  dictionary.

    # This keyword packages the five lines returned by dcmi power get_limit
    # command into a dictionary.  For example, the dcmi command may return:
    #  Current Limit State: No Active Power Limit
    #  Exception actions:   Hard Power Off & Log Event to SEL
    #  Power Limit:         500   Watts
    #  Correction time:     0 milliseconds
    #  Sampling period:     0 seconds
    # The power limit setting can be obtained with the following:
    # &{limits}=  DCMI Power Get Limits
    # ${power_setting}=  Set Variable  ${limits['power_limit']}

    ${output}=  Run External IPMI Standard Command  dcmi power get_limit
    ${output}=  Remove String  ${output}  Watts
    ${output}=  Remove String  ${output}  milliseconds
    ${output}=  Remove String  ${output}  seconds
    &{limits}=  Key Value Outbuf To Dict  ${output}
    [Return]  &{limits}


Get DCMI Power Limit
    [Documentation]  Return the system's current DCMI power_limit
    ...  watts setting.

    &{limits}=  DCMI Power Get Limits
    ${power_setting}=  Get From Dictionary  ${limits}  power_limit
    [Return]  ${power_setting}


Set DCMI Power Limit And Verify
    [Documentation]  Set system power limit via IPMI DCMI command.
    [Arguments]  ${power_limit}

    # Description of argument(s):
    # limit      The power limit in watts

    ${cmd}=  Catenate  dcmi power set_limit limit ${power_limit}
    Run External IPMI Standard Command  ${cmd}
    ${power}=  Get DCMI Power Limit
    Should Be True  ${power} == ${power_limit}
    ...  msg=Failed setting dcmi power limit to ${power_limit} watts.


Activate DCMI Power And Verify
    [Documentation]  Activate DCMI power limiting.

    ${resp}=  Run External IPMI Standard Command  dcmi power activate
    Should Contain  ${resp}  successfully activated
    ...  msg=Command failed: dcmi power activate.


Fail If DCMI Power Is Not Activated
    [Documentation]  Fail if DCMI power limiting is not activated.

    ${cmd}=  Catenate  dcmi power get_limit | grep State:
    ${resp}=  Run External IPMI Standard Command  ${cmd}
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
    ${resp}=  Run External IPMI Standard Command  ${cmd}
    Should Contain  ${resp}  No Active Power Limit
    ...  msg=DCMI power is not deactivated.


Get DCMI Power Limit Via REST
    [Documentation]  Return the system's current DCMI power_limit
    ...  watts setting using REST interface.

    ${power}=  Read Attribute  ${CONTROL_HOST_URI}power_cap  PowerCap
    [Return]  ${power}


Set DCMI Power Limit Via REST
    [Documentation]  Set system power limit via REST command.
    [Arguments]  ${power_limit}

    # Description of argument(s):
    # limit      The power limit in watts

    ${data}=  Create Dictionary  data=${power_limit}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCap  data=${data}


Activate DCMI Power Via REST
    [Documentation]  Activate DCMI power limiting vir REST.

    ${data}=  Create Dictionary  data=${True}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCapEnable
    ...  data=${data}


Deactivate DCMI Power Via REST
    [Documentation]  Deactivate DCMI power limiting vir REST.

    ${data}=  Create Dictionary  data=${False}
    Write Attribute   ${CONTROL_HOST_URI}power_cap  PowerCapEnable
    ...  data=${data}


Get DCMI Power Acivation via REST
    [Documentation]  Return the system's current DCMI power activat6ion
    ...  state setting using REST interface.

    ${power}=  Read Attribute  ${CONTROL_HOST_URI}power_cap  PowerCapEnable
    [Return]  ${power}


OCC Tool Upload Setup
    [Documentation]  Upload occtoolp9 to /tmp on the OS.

    ${cmd}=  Catenate  wget --no-check-certificate
    ...  -O/tmp/occtoolp9 --content-disposition
    ...  https://github.com/open-power/occ/raw/master/src/tools/occtoolp9
    ...  && chmod 777 /tmp/occtoolp9
    ${output}  ${stderr}  ${rc}=  OS Execute Command  ${cmd}
