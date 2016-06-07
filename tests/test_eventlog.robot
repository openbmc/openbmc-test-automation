*** Settings ***
Documentation          This suite is used for testing the error logging
...                    capability from the host

Resource        ../lib/rest_client.robot
Resource        ../lib/utils.robot


Library         BuiltIn
Library         Collections
Library         SSHLibrary

*** Variables ***
&{NIL}  data=@{EMPTY}
${SYSTEM_SHUTDOWN_TIME}     1min
${WAIT_FOR_SERVICES_UP}     3min

*** Test Cases ***

valid path to logs
    [Documentation]     Test list all events
    ${resp} =   openbmc get request     /org/openbmc/records/events/
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

clear any logs
    [Documentation]     Test delete all events
    ${resp} =   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp} =   openbmc get request     /org/openbmc/records/events/
    ${json} =   to json         ${resp.content}
    Should Be Empty     ${json['data']}

write a log
    [Documentation]     Test create event
    create a test log

Message attribute should match
    [Documentation]     Check message attribute for created event
    ${uri} =      create a test log
    ${content} =     Read Attribute      ${uri}   message
    Should Be Equal     ${content}      A Test event log just happened

Severity attribute should match
    [Documentation]     Check severity attribute for created event
    ${uri} =      create a test log
    ${content}=     Read Attribute      ${uri}   severity
    Should Be Equal     ${content}      Info

data_bytes attribute should match
    [Documentation]     Check data_bytes attribute for created event
    @{data_list} =   Create List     ${48}  ${0}  ${19}  ${127}  ${136}  ${255}
    ${uri} =      create a test log
    ${content} =   Read Attribute      ${uri}   debug_data
    Lists Should Be Equal     ${content}      ${data_list}

delete the log
    [Documentation]     Test the delete event
    ${uri} =     create a test log
    ${deluri} =  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp} =    openbmc get request     ${deluri}
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}

2nd delete should fail
    [Documentation]     Negative scnenario to delete already deleted event
    ${uri} =     create a test log
    ${deluri} =  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_NOT_FOUND}

Intermixed delete
    [Documentation]     This testcase is for excersicing caching impleted,
    ...                 Steps:
    ...                     write three logs
    ...                     delete middle log
    ...                     middle log should not exist
    ...                     time stamp should not match between logs(1st and 3rd)
    ${event1}=      create a test log
    ${event2}=      create a test log
    ${event3}=      create a test log
    ${deluri} =  catenate    SEPARATOR=   ${event2}   /action/delete
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${time_event1}=     Read Attribute      ${event1}   time
    ${time_event3}=     Read Attribute      ${event3}   time
    should not be equal     ${time_event1}      ${time_event3}

restarting event process retains logs
    [Documentation]     This is to test events are in place even after the
    ...                 event service is restarted.
    ${resp} =   openbmc get request     /org/openbmc/records/events/
    ${json} =   to json         ${resp.content}
    ${logs_pre_restart}=    set variable    ${json['data']}

    Open Connection And Log In
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${resp} =   openbmc get request     /org/openbmc/records/events/
    ${json} =   to json         ${resp.content}
    ${logs_post_restart}=   set variable    ${json['data']}
    List Should Contain Sub List    ${logs_post_restart}    ${logs_pre_restart}     msg=Failed to find all the eventlogs which are present before restart of event service

deleting log after obmc-phosphor-event.service restart
    [Documentation]     This is to test event can be deleted created prior to
    ...                 event service is restarted.
    ${uri}=         create a test log

    Open Connection And Log In
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${deluri} =  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

makeing new log after obmc-phosphor-event.service restart
    [Documentation]     This is for testing event creation after the
    ...                 event service is restarted.
    Open Connection And Log In
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    create a test log

deleting new log after obmc-phosphor-event.service restart
    [Documentation]     This testcase is for testing deleted newly created event
    ...                 after event service is restarted.
    Open Connection And Log In
    ${uptime}=  Execute Command    systemctl restart obmc-phosphor-event.service
    Sleep   ${10}

    ${uri}=     create a test log
    ${deluri} =  catenate    SEPARATOR=   ${uri}   /action/delete
    ${resp} =    openbmc post request     ${deluri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

Test events after openbmc reboot
    [Documentation]     This is to test event can be deleted created prior to
    ...                 openbmc reboot
    ...                 Steps:
    ...                     Create event,
    ...                     Reboot openbmc,
    ...                     Events should exist post reboot,
    ...                     Create two more events,
    ...                     Delete old and new event
    [Tags]      reboot_tests
    ${pre_reboot_event}=         create a test log

    Open Connection And Log In
    ${output}=      Execute Command    /sbin/reboot
    Sleep   ${SYSTEM_SHUTDOWN_TIME}
    Wait For Host To Ping   ${OPENBMC_HOST}
    Sleep   ${WAIT_FOR_SERVICES_UP}

    ${resp} =    openbmc get request     ${pre_reboot_event}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${post_reboot_event1}=         create a test log
    ${post_reboot_event2}=         create a test log

    ${del_prereboot_uri} =  catenate    SEPARATOR=   ${pre_reboot_event}   /action/delete
    ${resp} =    openbmc post request     ${del_prereboot_uri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${del_postreboot_uri} =  catenate    SEPARATOR=   ${post_reboot_event1}   /action/delete
    ${resp} =    openbmc post request     ${del_postreboot_uri}    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}

clearing logs results in no logs
    [Documentation]     This testcase is for clearning the events when no logs present
    ${resp} =   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${resp} =   openbmc get request     /org/openbmc/records/events/
    ${json} =   to json         ${resp.content}
    Should Be Empty     ${json['data']}
    ${resp} =   openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}


*** Keywords ***

create a test log
    [arguments]
    ${data} =   create dictionary   data=@{EMPTY}
    ${resp} =   openbmc post request     /org/openbmc/records/events/action/acceptTestMessage    data=${data}
    should be equal as strings      ${resp.status_code}     ${HTTP_OK}
    ${json} =   to json         ${resp.content}
    ${LOGID} =    convert to integer    ${json['data']}
    ${uri}=     catenate    SEPARATOR=   /org/openbmc/records/events/   ${LOGID}
    [return]  ${uri}

Open Connection And Log In
    Open connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
