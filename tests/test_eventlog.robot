*** Settings ***
Documentation     This suite is used for testing the error logging
...               capability from the host

Resource          ../lib/rest_client.robot
Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/boot/boot_resource_master.robot

Library           Collections

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections
Test Teardown     FFDC On Test Case Fail

*** Variables ***
&{NIL}  data=@{EMPTY}
${SYSTEM_SHUTDOWN_TIME}     1min
${WAIT_FOR_SERVICES_UP}     3min

*** Test Cases ***

valid path to logs
    [Documentation]     Test list all events
    [Tags]  CI
    ${resp}=   openbmc get request     /org/openbmc/records/events/
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

clear any logs
    [Documentation]     Test delete all events
    [Tags]  CI  clear_any_logs
    ${resp}=   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=   openbmc get request     /org/openbmc/records/events/
    ${json}=   to json         ${resp.content}
    Should Be Empty     ${json['data']}

write a log
    [Documentation]     Test create event
    [Tags]  CI  write_a_log
    create a test log

Message attribute should match
    [Documentation]     Check message attribute for created event
    [Tags]  CI
    ${uri}=      create a test log
    ${content}=     Read Attribute      ${uri}   message
    Should Be Equal     ${content}      A Test event log just happened

Severity attribute should match
    [Documentation]     Check severity attribute for created event
    [Tags]  CI
    ${uri}=      create a test log
    ${content}=     Read Attribute      ${uri}   severity
    Should Be Equal     ${content}      Info

data_bytes attribute should match
    [Documentation]     Check data_bytes attribute for created event
    [Tags]  CI
    @{data_list}=   Create List     ${48}  ${0}  ${19}  ${127}  ${136}  ${255}
    ${uri}=      create a test log
    ${content}=   Read Attribute      ${uri}   debug_data
    Lists Should Be Equal     ${content}      ${data_list}

delete the log
    [Documentation]     Test the delete event
    [Tags]  CI
    ${uri}=     create a test log
    ${deluri}=  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=    openbmc get request     ${deluri}
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}

2nd delete should fail
    [Documentation]     Negative scnenario to delete already deleted event
    [Tags]  CI
    ${uri}=     create a test log
    ${deluri}=  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}

Intermixed delete
    [Documentation]     This testcase does the following sequence
    ...                 Steps:
    ...                     write three logs
    ...                     delete middle log
    ...                     middle log should not exist
    [Tags]  CI
    ${event1}=      create a test log
    ${event2}=      create a test log
    ${event3}=      create a test log
    ${deluri}=  catenate    SEPARATOR=   ${event2}   /action/delete
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=   openbmc get request   ${event2}
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}

restarting event process retains logs
    [Documentation]     This is to test events are in place even after the
    ...                 event service is restarted.
    [Tags]  CI
    ${resp}=   openbmc get request     /org/openbmc/records/events/
    ${json}=   to json         ${resp.content}
    ${logs_pre_restart}=    set variable    ${json['data']}

    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${resp}=   openbmc get request     /org/openbmc/records/events/
    ${json}=   to json         ${resp.content}
    ${logs_post_restart}=   set variable    ${json['data']}
    List Should Contain Sub List    ${logs_post_restart}    ${logs_pre_restart}     msg=Failed to find all the eventlogs which are present before restart of event service

deleting log after obmc-phosphor-event.service restart
    [Documentation]     This is to test event can be deleted created prior to
    ...                 event service is restarted.
    [Tags]  CI
    ${uri}=         create a test log

    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${deluri}=  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

making new log after obmc-phosphor-event.service restart
    [Documentation]     This is for testing event creation after the
    ...                 event service is restarted.
    [Tags]  CI
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    create a test log

deleting new log after obmc-phosphor-event.service restart
    [Documentation]     This testcase is for testing deleted newly created event
    ...                 after event service is restarted.
    [Tags]  CI
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${uri}=     create a test log
    ${deluri}=  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp}=    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

Test events after openbmc reboot
    [Documentation]     This is to test event can be deleted created prior to
    ...                 openbmc reboot
    ...                 Steps:
    ...                     Create event,
    ...                     Power off if ON else no-op
    ...                     Reboot openbmc,
    ...                     Wait for BMC to READY or Powered OFF state
    ...                     Events should exist post reboot,
    ...                     Create two more events,
    ...                     Delete old and new event
    [Tags]      bmcreboot
    ${pre_reboot_event}=         create a test log

    Initiate Power Off
    Check Power Off States

    ${output}=      Execute Command    /sbin/reboot
    Check If BMC is Up   5 min    10 sec

    @{states}=   Create List   BMC_READY   HOST_POWERED_OFF
    Wait Until Keyword Succeeds
    ...    10 min   10 sec   Verify BMC State   ${states}

    ${resp}=    openbmc get request     ${pre_reboot_event}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${post_reboot_event1}=         create a test log

    ${del_prereboot_uri}=  catenate    SEPARATOR=   ${pre_reboot_event}   /action/delete
    ${resp}=    openbmc post request     ${del_prereboot_uri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${del_postreboot_uri}=  catenate    SEPARATOR=   ${post_reboot_event1}   /action/delete
    ${resp}=    openbmc post request     ${del_postreboot_uri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

clearing logs results in no logs
    [Documentation]     This testcase is for clearning the events when no logs present
    [Tags]  CI
    ${resp}=   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp}=   openbmc get request     /org/openbmc/records/events/
    ${json}=   to json         ${resp.content}
    Should Be Empty     ${json['data']}
    ${resp}=   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}


*** Keywords ***

create a test log
    [Arguments]
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=   openbmc post request     /org/openbmc/records/events/action/acceptTestMessage    data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json}=   to json         ${resp.content}
    ${LOGID}=    convert to integer    ${json['data']}
    ${uri}=     catenate    SEPARATOR=   /org/openbmc/records/events/   ${LOGID}
    [return]  ${uri}
