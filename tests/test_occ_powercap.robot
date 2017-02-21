*** Settings ***
Documentation  This suite is for testing OCC: Power capping setting

Resource       ../lib/rest_client.robot
Resource       ../lib/resource.txt
Resource       ../lib/utils.robot
Resource       ../lib/openbmc_ffdc.robot
Resource       ../lib/state_manager.robot

Suite Setup    Check OCC Readiness
Test Teardown  FFDC On Test Case Fail

Force Tags  powercapping

*** Variables ***

*** Test Cases ***

Get OCC status
    [Documentation]  This testcase is to test the OCCstatus for the system
    ...              is Enabled or not
    [Tags]  Get_OCC_status
    ${status}=  Get OCC status
    Should Be Equal  ${status}  Enabled

Set And Get Powercap
    [Documentation]  This testcase is to test get/set powercap feature.
    ...              In the testcase we are reading min, max value and then
    ...              try set the random in that range.
    ...              Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  Set_And_Get_Powercap  known_issue

    ${min}=  Get Minimum Powercap
    Log  ${min}
    ${max}=  Get Maximum Powercap
    Log  ${max}
    ${rand_power_cap}=  Evaluate  random.randint(${min}, ${max})  modules=random
    Log  ${rand_power_cap}
    ${resp}=  Set Powercap  ${rand_power_cap}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  ${DBUS_POLL_INTERVAL}
    ${power_cap}=  Get Powercap
    Should Be Equal  ${power_cap}  ${rand_power_cap}
    ${user_power_cap}=  Get User Powercap
    Should Be Equal  ${user_power_cap}  ${rand_power_cap}

Set Less Than Minimum Powercap
    [Documentation]  Test set powercap with less than min powercap value
    ...              Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  Set_Less_Than_Minimum_Powercap  known_issue

    ${org_power_cap}=  Get Powercap
    ${min}=  Get Minimum Powercap
    ${sample_invalid_pcap}=  Evaluate  ${min}-${100}
    ${resp}=  Set Powercap  ${sample_invalid_pcap}
    Sleep  ${DBUS_POLL_INTERVAL}
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${power_cap}=  Get Powercap
    Should Be Equal  ${org_power_cap}  ${power_cap}

Set More Than Maximum Powercap
    [Documentation]  Test set powercap with more than max powercap value
    ...              Existing Issue: https://github.com/openbmc/openbmc/issues/552
    [Tags]  Set_More_Than_Maximum_Powercap  known_issue

    ${org_power_cap}=  Get Powercap
    ${min}=  Get Maximum Powercap
    ${sample_invalid_pcap}=  Evaluate  ${min}+${100}
    ${resp}=  Set Powercap  ${sample_invalid_pcap}
    Sleep  ${DBUS_POLL_INTERVAL}
    Should Not Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${power_cap}=  Get Powercap
    Should Be Equal  ${org_power_cap}  ${power_cap}

Disable Powercap
    [Documentation]  Test set powercap with 0 and make sure powercap is
    ...              disabled by checking whether the value is set to 0
    [Tags]  Disable_Powercap

    ${resp}=  Set Powercap  ${0}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Sleep  ${DBUS_POLL_INTERVAL}
    ${power_cap}=  Get Powercap
    Should Be Equal  ${power_cap}  ${0}
    ${user_power_cap}=  Get User Powercap
    Should Be Equal  ${user_power_cap}  ${0}

Get System Power Consumption
    [Documentation]  Get the current system power consumption and check if the
    ...              value is greater than zero
    [Tags]  Get_System_Power_Consumption

    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}powercap/system_power
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    Should Be True  ${jsondata["data"]["value"]} > 0

*** Keywords ***

Get Minimum Powercap
    ${resp}=  OpenBMC Get Request
    ...  ${SENSORS_URI}powercap/min_cap
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]["value"]}

Get Maximum Powercap
    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}powercap/max_cap
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]["value"]}

Get User Powercap
    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}powercap/user_cap
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]["value"]}

Set Powercap
    [Arguments]  ${powercap_value}
    @{pcap_list}=  Create List  ${powercap_value}
    ${data}=  Create Dictionary  data=@{pcap_list}
    ${resp}=  OpenBMC Post Request
    ...  ${SENSORS_URI}host/powercap/action/setValue  data=${data}
    [Return]  ${resp}

Get Powercap
    ${resp}=  OpenBMC Get Request
    ...  ${SENSORS_URI}host/powercap
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]["value"]}

Get OCC status link
    ${resp}=  OpenBMC Get Request
    ...  ${SENSORS_URI}host/list
    ${jsondata}=  To JSON  ${resp.content}
    Log  ${jsondata}
    : FOR  ${ELEMENT}  IN  @{jsondata["data"]}
    \  Log  ${ELEMENT}
    \  ${found}=  Get Lines Matching Pattern  ${ELEMENT}  *host/cpu*/OccStatus
    \  Return From Keyword If  '${found}' != ''  ${found}

Get OCC status
    ${occstatus_link}=  Get OCC status link
    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${occstatus_link}/action/getValue  data=${data}
    ${jsondata}=  To JSON  ${resp.content}
    [Return]  ${jsondata["data"]}

Get Chassis URI
    ${resp}=  OpenBMC Get Request  ${OPENBMC_BASE_URI}control/
    ${jsondata}=  To JSON  ${resp.content}
    Log  ${jsondata}
    : FOR  ${ELEMENT}  IN  @{jsondata["data"]}
    \  Log  ${ELEMENT}
    \  ${found}=  Get Lines Matching Pattern  ${ELEMENT}  *control/chassis*
    \  Return From Keyword If  '${found}' != ''  ${found}


Check OCC Readiness
    [Documentation]  Poweron If BMC power state is off. Check the OCC powercap
    ...              if the interface attributes are activated.

    ${status}=  Run Keyword and Return Status  Is Host Off
    Run Keyword If  '${status}' == '${True}'  Initiate Host Boot
    Wait Until Keyword Succeeds  5min  10sec  Powercap Attributes Activated


Powercap Attributes Activated
    [Documentation]  Verify if the response contains the pre-define list

    @{precheck}=  Create List  ${SENSORS_URI}powercap/user_cap
    ...                        ${SENSORS_URI}powercap/system_power
    ...                        ${SENSORS_URI}powercap/curr_cap
    ...                        ${SENSORS_URI}powercap/max_cap
    ...                        ${SENSORS_URI}powercap/min_cap

    ${resp}=  OpenBMC Get Request  ${SENSORS_URI}powercap/
    ${jsondata}=  To JSON  ${resp.content}
    List Should Contain Sub List  ${jsondata["data"]}  ${precheck}
    ...  msg=Failed to activate powercap interface attributes
