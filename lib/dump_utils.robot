*** Settings ***
Documentation  This module provides general keywords for dump.

Library         bmc_ssh_utils.py

*** Variables ***

*** Keywords ***



Create User Initiated Dump
    [Documentation]  Generate user initiated dump and return
    ...  the dump id number (e.g., "5").

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_URI}action/CreateDump  data=${data}  quiet=${1}

    Run Keyword If  '${resp.status_code}' == '${HTTP_OK}'
    ...  Run Keyword And Return  Get The Dump Id  ${resp}
    ...  ELSE   Run Keyword And Return  Check For Too Many Dumps  ${resp}


Get The Dump Id
    [Documentation]  Wait for the dump to be created. Return the
    ...  dump id number (e.g., "5").
    [Arguments]  ${resp}

    # Description of Argument(s):
    # resp   Response object from successful action/Create Dump attempt.
    #        Example object:
    #        {
    #           "data": 5,
    #           "message": "200 OK",
    #           "status": "ok"
    #        },
    #        The "data" field conveys the id number of the created dump.

    ${json}=  To JSON  ${resp.content}

    Run Keyword If  ${json["data"]} == ${None}
    ...  Fail  Dump id returned null.

    ${dump_id}=  Set Variable  ${json["data"]}

    Wait Until Keyword Succeeds  3 min  15 sec  Check Dump Existence
    ...  ${dump_id}

    [Return]  ${dump_id}


Check For Too Many Dumps
    [Documentation]  Return ${EMPTY} if dump creation failed due to too
    ...  many dumps. Fail if dump creation was due to some other cause.
    [Arguments]  ${resp}

    # Description of Argument(s):
    # resp   Response object from failed action/Create Dump attempt.
    #        Example object:
    #        {
    #           "data": {
    #              "description": "Internal Server Error",
    #              "exception": "'Dump not captured due to a cap.'",
    #              "traceback": [
    #              "Traceback (most recent call last):",
    #                ...
    #              "DBusException: Create.Error.QuotaExceeded"
    #                           ]
    #              },
    #           "message": "500 Internal Server Error",
    #           "status": "error"
    #        }

    ${exception}=  Set Variable  ${resp.json()['data']['exception']}
    ${at_capacity}=  Set Variable  Dump not captured due to a cap
    ${too_many_dumps}=  Evaluate  $at_capacity in $exception
    Rprintn
    Rprint Vars   exception  too_many_dumps
    ${status}=  Run Keyword If  ${too_many_dumps}  Set Variable  ${EMPTY}
    ...  ELSE  Fail  msg=${exception}.

    [Return]  ${status}


Verify No Dump In Progress
    [Documentation]  Verify no dump in progress.

    ${dump_progress}  ${stderr}  ${rc}=  BMC Execute Command  ls /tmp
    Should Not Contain  ${dump_progress}  obmcdump


Check Dump Existence
    [Documentation]  Verify if given dump exist.
    [Arguments]  ${dump_id}

    # Description of Argument(s):
    # dump_id  An integer value that identifies a particular dump
    #          object(e.g. 1, 3, 5).

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}${dump_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete BMC Dump
    [Documentation]  Deletes a given bmc dump.
    [Arguments]  ${dump_id}

    # Description of Argument(s):
    # dump_id  An integer value that identifies a particular dump (e.g. 1, 3).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_ENTRY_URI}${dump_id}/action/Delete  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Delete All Dumps
    [Documentation]  Delete all dumps.

    # Check if dump entries exist, if not return.
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list  quiet=${1}
    Return From Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}

    # Get the list of dump entries and delete them all.
    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    :FOR  ${entry}  IN  @{dump_entries}
    \  ${dump_id}=  Fetch From Right  ${entry}  /
    \  Delete BMC Dump  ${dump_id}


Delete All BMC Dump
    [Documentation]  Delete all BMC dump entries using "DeleteAll" interface.

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Post Request  ${DUMP_URI}action/DeleteAll  data=${data}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Dump Should Not Exist
    [Documentation]  Verify that BMC dumps do not exist.

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list  quiet=${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

Check Existence of BMC Dump file
    [Documentation]  Verify existence of BMC dump file.
    [Arguments]  ${dump_id}

    # Description of argument(s):
    # dump_id  BMC dump identifier

    ${dump_check_cmd}=  Set Variable
    ...  ls /var/lib/phosphor-debug-collector/dumps

    # Output of sample BMC Execute command with '2' as dump id is as follows
    # ls /var/lib/phosphor-debug-collector/dumps/2
    # obmcdump_2_XXXXXXXXXX.tar.xz
    ${file_there}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ${dump_check_cmd}/${dump_id}
    Should End With  ${file_there}  tar.xz  msg=BMC dump file not found.

Get Dump Entries
    [Documentation]  Return dump entries list.

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    [Return]  ${dump_entries}


Trigger Core Dump
    [Documentation]  Trigger core dump.

    # Find the pid of the active ipmid and kill it.
    ${cmd_buf}=  Catenate  kill -s SEGV $(ps | egrep ' ipmid$' |
    ...  egrep -v grep | \ cut -c1-6)

    ${cmd_output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd_buf}
    Should Be Empty  ${stderr}  msg=BMC execute command error.
    Should Be Equal As Integers  ${rc}  ${0}
    ...  msg=BMC execute command return code is not zero.
