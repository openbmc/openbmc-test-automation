*** Settings ***
Documentation     This suite is used for testing eventlog association.

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot/boot_resource_master.robot

Library           Collections

Suite Setup       Suite Initialization Setup
Suite Teardown    Close All Connections

Test Teardown     FFDC On Test Case Fail

*** Variables ***

${SYSTEM_SHUTDOWN_TIME}           1min

${WAIT_FOR_SERVICES_UP}           3min

${EVENT_RECORD}        ${RECORDS_URI}events/
${DIMM_PREFIX}         ${INVENTORY_URI}system/chassis/motherboard/
${DIMM1_URI}           ${DIMM_PREFIX}dimm1
${DIMM2_URI}           ${DIMM_PREFIX}dimm2
${DIMM3_URI}           ${DIMM_PREFIX}dimm3

${BUSCTL_PREFIX}                busctl call ${OPENBMC_BASE_DBUS}.records.events
...                             ${OPENBMC_BASE_URI}records/events
...                             ${OPENBMC_BASE_DBUS}.recordlog
...                             acceptHostMessage sssay "Error"

${CREATE_ERROR_SINGLE_FRU}      ${BUSCTL_PREFIX} "Testing failure"
...                             "${DIMM1_URI}" 1 1

${CREATE_ERROR_INVALID_FRU}     ${BUSCTL_PREFIX} "Testing with invalid FRU"
...                             "abc" 1 1

${CREATE_ERROR_NO_FRU}          ${BUSCTL_PREFIX} "Testing with no fru" "" 1 1

${CREATE_ERROR_VIRTUAL_SENSOR}  ${BUSCTL_PREFIX}
...                             "Testing with a virtual sensor"
...                             "${INVENTORY_URI}system/systemevent " 1 1

&{NIL}                          data=@{EMPTY}

*** Test Cases ***

Create error log on single FRU
    [Documentation]     ***GOOD PATH***
    ...                 Create an error log on single FRU and verify
    ...                 its association.\n
    [Tags]  Create_error_log_on_single_FRU

    Run Keyword And Continue On Failure   Clear all logs

    ${elog}  ${stderr}=
    ...   Execute Command    ${CREATE_ERROR_SINGLE_FRU}
    ...   return_stderr=True
    Should Be Empty    ${stderr}

    ${log_list}=     Get EventList
    Should Contain   '${log_list}'   ${elog.strip('q ')}

    ${association_uri}=
    ...   catenate  SEPARATOR=   ${EVENT_RECORD}${elog.strip('q ')}  /fru

    ${association_content}=
    ...   Read Attribute    ${association_uri}    endpoints
    Should Contain     ${association_content}    ${DIMM1_URI}

    ${dimm1_event}=     Read Attribute     ${DIMM1_URI}/event   endpoints
    Should Contain     ${dimm1_event}    ${log_list[0]}


Create error log on two FRU
    [Documentation]     ***GOOD PATH***
    ...                 Create an error log on two FRUs and verify
    ...                 its association.\n

    ${log_uri}=      Create a test log
    ${association_uri}=    catenate    SEPARATOR=   ${log_uri}   /fru

    ${association_content}=     Read Attribute    ${association_uri}    endpoints
    Should Contain     ${association_content}    ${DIMM3_URI}
    Should Contain     ${association_content}    ${DIMM2_URI}

    ${dimm3_event}=     Read Attribute     ${DIMM3_URI}/event   endpoints
    Should Contain     ${dimm3_event}    ${log_uri}

    ${dimm2_event}=     Read Attribute     ${DIMM2_URI}/event   endpoints
    Should Contain     ${dimm2_event}    ${log_uri}


Create multiple error logs
    [Documentation]     ***GOOD PATH***
    ...                 Create multiple error logs and verify
    ...                 their association.\n

    : FOR    ${INDEX}    IN RANGE    1    4
    \    Log    ${INDEX}
    \    ${log_uri}=      Create a test log
    \    ${association_uri}=   catenate    SEPARATOR=   ${log_uri}   /fru
    \    ${association_content}=
    ...   Read Attribute   ${association_uri}    endpoints
    \    Should Contain    ${association_content}   ${DIMM3_URI}
    \    Should Contain    ${association_content}   ${DIMM2_URI}
    \    ${dimm3_event}=   Read Attribute   ${DIMM3_URI}/event   endpoints
    \    Should Contain    ${dimm3_event}   ${log_uri}
    \    ${dimm2_event}=   Read Attribute   ${DIMM2_URI}/event   endpoints
    \    Should Contain    ${dimm2_event}   ${log_uri}


Delete error log
    [Documentation]     ***BAD PATH***
    ...                 Delete an error log and verify that its
    ...                 association is also removed.\n
    [Tags]  Delete_error_log

    ${log_uri1}=      Create a test log
    ${association_uri1}=    catenate    SEPARATOR=   ${log_uri1}   /fru

    ${log_uri2}=      Create a test log

    ${del_uri}=  catenate    SEPARATOR=   ${log_uri1}   /action/delete
    ${resp}=    openbmc post request     ${del_uri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

    ${resp}=     openbmc get request     ${association_uri1}
    ${jsondata}=    to json    ${resp.content}
    Should Contain     ${jsondata['message']}    404 Not Found

    ${dimm3_event}=     Read Attribute      ${DIMM3_URI}/event   endpoints
    Should Not Contain     ${dimm3_event}    ${log_uri1}

    ${dimm2_event}=     Read Attribute      ${DIMM2_URI}/event   endpoints
    Should Not Contain     ${dimm2_event}    ${log_uri1}


Association with invalid FRU
    [Documentation]     ***BAD PATH***
    ...                 Create an error log on invalid FRU and verify
    ...                 that its does not have any association.\n

    Run Keyword And Continue On Failure   Clear all logs

    ${elog}  ${stderr}=
    ...   Execute Command    ${CREATE_ERROR_INVALID_FRU}
    ...   return_stderr=True
    Should Be Empty    ${stderr}

    ${log_list}=     Get EventList
    Should Contain   '${log_list}'   ${elog.strip('q ')}

    ${association_uri}=
    ...   catenate  SEPARATOR=  ${EVENT_RECORD}${elog.strip('q ')}  /fru

    ${resp}=     openbmc get request     ${association_uri}
    ${jsondata}=    to json    ${resp.content}
    Should Contain     ${jsondata['message']}    404 Not Found


Assocition with no FRU error event
    [Documentation]     ***BAD PATH***
    ...                 Create an error log on no FRU and verify
    ...                 that its does not have any association.\n

    Run Keyword And Continue On Failure   Clear all logs

    ${elog}  ${stderr}=
    ...   Execute Command    ${CREATE_ERROR_NO_FRU}
    ...   return_stderr=True
    Should Be Empty    ${stderr}

    ${log_list}=     Get EventList
    Should Contain   '${log_list}'   ${elog.strip('q ')}

    ${association_uri}=
    ...   catenate    SEPARATOR=   ${EVENT_RECORD}${elog.strip('q ')}  /fru

    ${resp}=     openbmc get request     ${association_uri}
    ${jsondata}=    to json    ${resp.content}
    Should Contain     ${jsondata['message']}    404 Not Found


Association with virtual sensor
    [Documentation]     ***GOOD PATH***
    ...                 Create an error log on virtual sensor and
    ...                 verify its association.\n
    [Tags]              Association_with_virtual_sensor

    Run Keyword And Continue On Failure   Clear all logs

    ${elog}  ${stderr}=
    ...   Execute Command    ${CREATE_ERROR_VIRTUAL_SENSOR}
    ...   return_stderr=True
    Should Be Empty    ${stderr}

    ${log_list}=     Get EventList
    Should Contain   '${log_list}'   ${elog.strip('q ')}

    ${association_uri}=
    ...   catenate    SEPARATOR=   ${EVENT_RECORD}${elog.strip('q ')}  /fru

    ${association_content}=
    ...   Read Attribute    ${association_uri}    endpoints
    Should Contain
    ...  ${association_content}
    ...  ${OPENBMC_BASE_URI}inventory/system/systemevent

Association unchanged after reboot
    [Documentation]     ***GOOD PATH***
    ...                 This test case is to verify that error log association
    ...                 does not change after open bmc reboot.\n
    [Tags]  bmcreboot  Association_Unchanged_After_Reboot

    ${pre_reboot_log_uri}=      Create a test log
    ${association_uri}=
    ...    catenate    SEPARATOR=   ${pre_reboot_log_uri}   /fru
    ${pre_reboot_association_content} =
    ...   Read Attribute   ${association_uri}    endpoints

    Initiate Power Off
    Check Power Off States

    ${output}=      Execute Command    /sbin/reboot
    Check If BMC is Up   5 min    10 sec

    @{states}=   Create List   BMC_READY   HOST_POWERED_OFF
    Wait Until Keyword Succeeds
    ...    10 min   10 sec   Verify BMC State   ${states}

    ${post_reboot_association_content} =
    ...   Read Attribute    ${association_uri}    endpoints
    Should Be Equal
    ...   ${post_reboot_association_content}
    ...   ${pre_reboot_association_content}

    ${post_reboot_dimm3_event} =
    ...   Read Attribute   ${DIMM3_URI}/event   endpoints
    Should Contain
    ...   ${post_reboot_dimm3_event}   ${pre_reboot_log_uri}
    ${post_reboot_dimm2_event} =
    ...   Read Attribute   ${DIMM2_URI}/event   endpoints
    Should Contain
    ...   ${post_reboot_dimm2_event}   ${pre_reboot_log_uri}

*** Keywords ***

Get EventList
    ${resp}=   openbmc get request   ${EVENT_RECORD}
    should be equal as strings    ${resp.status_code}    ${HTTP_OK}
    ${jsondata}=    to json    ${resp.content}
    [return]    ${jsondata['data']}

Create a test log
    [Arguments]
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   openbmc post request
    ...     ${EVENT_RECORD}action/acceptTestMessage    data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    ${LOGID}=    convert to integer    ${json['data']}
    ${uri}=     catenate    SEPARATOR=   ${EVENT_RECORD}   ${LOGID}
    [return]  ${uri}

Clear all logs
    ${resp}=   openbmc post request
    ...   ${EVENT_RECORD}action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=   openbmc get request   ${EVENT_RECORD}
    ${json}=   to json         ${resp.content}
    Should Be Empty     ${json['data']}

Suite Initialization Setup
    Open Connection And Log In
    Run Keyword And Continue On Failure   Clear all logs
