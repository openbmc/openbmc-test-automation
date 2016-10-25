*** Settings ***

Documentation   This testsuite is for testing journal logs in openbmc.

Resource           ../lib/rest_client.robot
Resource           ../lib/utils.robot
Resource           ../lib/openbmc_ffdc.robot

Suite Setup        Open Connection And Log In
Suite Teardown     Close All Connections
Test Teardown      Log FFDC

*** Variables ***
&{NIL}  data=@{EMPTY}

*** Test Cases ***

Get Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for GET request.

    Start Journal Log

    openbmc get request     /org/openbmc/

    ${output}=    Stop Journal Log
    Should Contain   ${output}    GET /org/openbmc/ HTTP/1.1

Post Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for POST request.

    Start Journal Log

    openbmc post request     /org/openbmc/records/events/action/clear    data=${NIL}

    ${output}=    Stop Journal Log
    Should Contain   ${output}    POST /org/openbmc/records/events/action/clear HTTP/1.1

Put Request Journal Log
    [Documentation]   This testcase is to verify that proper log is logged in
    ...               journal log for PUT request.

    Start Journal Log

    ${bootpolicy} =   Set Variable   ONETIME
    ${valueDict} =   create dictionary   data=${bootpolicy}
    openbmc put request  /org/openbmc/settings/host0/attr/boot_policy   data=${valueDict}

    ${output}=    Stop Journal Log
    Should Contain   ${output}    PUT /org/openbmc/settings/host0/attr/boot_policy HTTP/1.1

*** Keywords ***

Start Journal Log
    [Documentation]   Start capturing journal log to a file in /tmp using
    ...               journalctl command. By default journal log is collected
    ...               at /tmp/journal_log else user input location.
    ...               The File is appended with datetime.
    [Arguments]       ${file_path}=/tmp/journal_log

    Open Connection And Log In

    ${cur_time}=    Get Time Stamp
    Set Global Variable   ${LOG_TIME}   ${cur_time}
    Start Command
    ...  journalctl -f > ${file_path}-${LOG_TIME}
    Log to console    Journal Log Started: ${file_path}-${LOG_TIME}

Stop Journal Log
    [Documentation]   Stop journalctl process if its running.
    ...               By default return log from /tmp/journal_log else
    ...               user input location.
    [Arguments]       ${file_path}=/tmp/journal_log

    Open Connection And Log In

    ${rc}=
    ...  Execute Command
    ...  ps ax | grep journalctl | grep -v grep
    ...  return_stdout=False  return_rc=True

    Return From Keyword If   '${rc}' == '${1}'
    ...   No journal log process running

    ${output}  ${stderr}=
    ...  Execute Command   killall journalctl
    ...  return_stderr=True
    Should Be Empty     ${stderr}

    ${journal_log}  ${stderr}=
    ...  Execute Command
    ...  cat ${file_path}-${LOG_TIME}
    ...  return_stderr=True
    Should Be Empty     ${stderr}

    [Return]    ${journal_log}
