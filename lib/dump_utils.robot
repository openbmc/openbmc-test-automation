*** Settings ***
Documentation  This module provides general keywords for dump.


*** Variables ***

*** Keywords ***

Create User Initiated Dump
    [Documentation]  Generate user initiated dump and return
    ...  dump id (e.g 1, 2 etc).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_URI}/action/CreateDump  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${json}=  To JSON  ${resp.content}
    ${dump_id}=  Set Variable  ${json["data"]}

    Wait Until Keyword Succeeds  1 min  10 sec  Check Dump Existence
    ...  ${dump_id}

    [Return]  ${dump_id}


Check Dump Existence
    [Documentation]  Verify if given dump exist.
    [Arguments]  ${dump_id}

    # Description of Argument(s):
    # dump_id  An integer value that identifies a particular dump
    #          object(e.g. 1, 3, 5).

    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/${dump_id}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Delete BMC Dump
    [Documentation]  Deletes a given bmc dump.
    [Arguments]  ${dump_id}

    # Description of Argument(s):
    # dump_id  An interger value that identifies a particular dump (e.g. 1, 3).

    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  OpenBMC Post Request
    ...  ${DUMP_ENTRY_URI}/${dump_id}/action/Delete  data=${data}

    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Delete All Dumps
    [Documentation]  Delete all dumps.

    # Check if dump entries exist, if not return.
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}list
    #  quiet=${1}
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
