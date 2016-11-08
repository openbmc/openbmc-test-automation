*** Settings ***
Documentation           This suite is for testing OCC: Power capping setting

Resource                ../lib/rest_client.robot
Resource                ../lib/resource.txt
Resource                ../lib/utils.robot
Resource                ../lib/openbmc_ffdc.robot
Resource                ../lib/boot/boot_resource_master.robot

Suite Setup             Check OCC Readiness
Test Teardown           Log FFDC

Force Tags   powercapping

*** Test Cases ***

Get OCC status
    [Documentation]     This testcase is to test the OCCstatus for the system
    ...                 is Enabled or not
    [Tags]  Get_OCC_status
    ${status}=  Get OCC status
    Should Be Equal     ${status}   Enabled

Set and Get PowerCap
    [Documentation]     This testcase is to test get/set powercap feature.
    ...                 In the testcase we are reading min, max value and then
    ...                 try set the random in that range.
    ...                 Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${min}=     Get Minimum PowerCap
    log     ${min}
    ${max}=     Get Maximum PowerCap
    log     ${max}
    ${rand_power_cap}=      Evaluate    random.randint(${min}, ${max})   modules=random
    log     ${rand_power_cap}
    ${resp}=    Set PowerCap    ${rand_power_cap}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Sleep   ${DBUS_POLL_INTERVAL}
    ${power_cap}=       Get PowerCap
    Should Be Equal     ${power_cap}    ${rand_power_cap}
    ${user_power_cap}=  Get User PowerCap
    Should Be Equal     ${user_power_cap}    ${rand_power_cap}

Set Less Than Minimum PowerCAP
    [Documentation]     Test set powercap with less than min powercap value
    ...                 Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${org_power_cap}=       Get PowerCap
    ${min}=     Get Minimum PowerCap
    ${sample_invalid_pcap}=     Evaluate    ${min}-${100}
    ${resp}=  Set PowerCap    ${sample_invalid_pcap}
    Sleep   ${DBUS_POLL_INTERVAL}
    Should Not Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    ${power_cap}=       Get PowerCap
    Should Be Equal     ${org_power_cap}    ${power_cap}

Set More Than Maximum PowerCAP
    [Documentation]     Test set powercap with more than max powercap value
    ...                 Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  known_issue

    ${org_power_cap}=       Get PowerCap
    ${min}=     Get Maximum PowerCap
    ${sample_invalid_pcap}=     Evaluate    ${min}+${100}
    ${resp}=  Set PowerCap    ${sample_invalid_pcap}
    Sleep   ${DBUS_POLL_INTERVAL}
    Should Not Be Equal As Strings      ${resp.status_code}     ${HTTP_OK}
    ${power_cap}=       Get PowerCap
    Should Be Equal     ${org_power_cap}    ${power_cap}

Disable PowerCap
    [Documentation]     Test set powercap with 0 and make sure powercap is
    ...                 disabled by checking whether the value is set to 0
    [Tags]  Disable_PowerCap

    ${resp}=  Set PowerCap    ${0}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    Sleep   ${DBUS_POLL_INTERVAL}
    ${power_cap}=       Get PowerCap
    Should Be Equal     ${power_cap}    ${0}
    ${user_power_cap}=  Get User PowerCap
    Should Be Equal     ${user_power_cap}    ${0}

Get System Power Consumption
    [Documentation]   Get the current system power consumption and check if the
    ...               value is greater than zero
    [Tags]  Get_System_Power_Consumption

    ${resp} =   OpenBMC Get Request   /org/openbmc/sensors/powercap/system_power
    should be equal as strings   ${resp.status_code}   ${HTTP_OK}
    ${jsondata}=   To Json    ${resp.content}
    Should Be True   ${jsondata["data"]["value"]} > 0

*** Keywords ***

Get Minimum PowerCap
    ${resp} =   OpenBMC Get Request    /org/openbmc/sensors/powercap/min_cap
    ${jsondata}=   To Json    ${resp.content}
    [return]    ${jsondata["data"]["value"]}

Get Maximum PowerCap
    ${resp} =   OpenBMC Get Request    /org/openbmc/sensors/powercap/max_cap
    ${jsondata}=   To Json    ${resp.content}
    [return]    ${jsondata["data"]["value"]}

Get User PowerCap
    ${resp} =   OpenBMC Get Request    /org/openbmc/sensors/powercap/user_cap
    ${jsondata}=   To Json    ${resp.content}
    [return]    ${jsondata["data"]["value"]}

Set PowerCap
    [Arguments]    ${powercap_value}
    @{pcap_list} =   Create List     ${powercap_value}
    ${data} =   create dictionary   data=@{pcap_list}
    ${resp} =   openbmc post request    /org/openbmc/sensors/host/powercap/action/setValue      data=${data}
    [return]    ${resp}

Get PowerCap
    ${resp} =   OpenBMC Get Request    /org/openbmc/sensors/host/powercap
    ${jsondata}=   To Json    ${resp.content}
    [return]    ${jsondata["data"]["value"]}

Get OCC status link
    ${resp}=    OpenBMC Get Request     /org/openbmc/sensors/host/list
    ${jsondata}=   To Json    ${resp.content}
    log     ${jsondata}
    : FOR    ${ELEMENT}    IN    @{jsondata["data"]}
    \   log     ${ELEMENT}
    \   ${found}=   Get Lines Matching Pattern      ${ELEMENT}      *host/cpu*/OccStatus
    \   Return From Keyword If     '${found}' != ''     ${found}

Get OCC status
    ${occstatus_link}=  Get OCC status link
    ${data} =   create dictionary   data=@{EMPTY}
    ${resp} =   openbmc post request    ${occstatus_link}/action/getValue      data=${data}
    ${jsondata}=   To Json    ${resp.content}
    [return]    ${jsondata["data"]}

Get Chassis URI
    ${resp}=    OpenBMC Get Request     /org/openbmc/control/
    ${jsondata}=   To Json    ${resp.content}
    log     ${jsondata}
    : FOR    ${ELEMENT}    IN    @{jsondata["data"]}
    \   log     ${ELEMENT}
    \   ${found}=   Get Lines Matching Pattern      ${ELEMENT}      *control/chassis*
    \   Return From Keyword If     '${found}' != ''     ${found}


Check OCC Readiness
    [Documentation]   Poweron If BMC power state is off. Check the OCC powercap
    ...               if the interface attributes are activated.

    ${status}=
    ...   Run Keyword and Return Status    Check Power Off States
    Run Keyword If   '${status}' == '${True}'
    ...   BMC Power On
    Wait Until Keyword Succeeds   5min  10sec
    ...   Powercap Attributes Activated


Powercap Attributes Activated
    [Documentation]   Verify if the response contains the pre-define list

    @{precheck}=   Create List   /org/openbmc/sensors/powercap/user_cap
    ...                          /org/openbmc/sensors/powercap/system_power
    ...                          /org/openbmc/sensors/powercap/curr_cap
    ...                          /org/openbmc/sensors/powercap/max_cap
    ...                          /org/openbmc/sensors/powercap/min_cap

    ${resp}=    OpenBMC Get Request   /org/openbmc/sensors/powercap/
    ${jsondata}=   To Json    ${resp.content}
    List Should Contain Sub List   ${jsondata["data"]}    ${precheck}
    ...     msg=Failed to activate powercap interface attributes

