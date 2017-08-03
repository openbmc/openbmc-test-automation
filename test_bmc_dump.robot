*** Settings ***

Documentation       Test dump functionality of OpenBMC.

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/rest_client.robot

Test Setup          Open Connection And Log In
Test Teardown       Post Testcase Execution

*** Variables ***


*** Test Cases ***

Verify BMC Core Dump
    [Documentation]  Verify BMC Core Dump.
    [Tags]  Verify_BMC_Core_Dump

    Delete All Dumps
    Trigger Core Dump
    Sleep  10 secs

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    Should Not Be Empty  ${dump_entries}

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    Should Not Be Empty  ${dump_entries}


Verify Core Dump Size
    [Documentation]  Verify core dump size.
    [Tags]  Verify_Core_Dump_Size

    Delete All Dumps
    Trigger Core Dump
    Sleep  10 secs

    ${dump_entries}=  Get URL List  ${DUMP_ENTRY_URI}
    ${dump_size}=  Read Attribute  ${dump_entries[0]}  Size
    # Max size for dump is 500k
    Should Be True  ${dump_size} < 500000

Delete All Dumps And Verify
    [Documentation]  Delete all dumps and verify.
    [Tags]  Delete_All_Dumps_And_Verify

    Delete All Dumps
    ${resp}=  OpenBMC Get Request  ${DUMP_ENTRY_URI}/list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Delete Non Existing Dump
    [Documentation]  Delete non existing dump entry.
    [Tags]  Delete_Non_Existing_Dump

    Delete All Dumps
    ${resp}=  Delete Dump Entry  abc
    Should Be Equal As Strings  ${resp}  error


Create Multiple Dumps And Verify
    [Documentation]  Create multiple dumps and verify.
    [Tags]  Create_Multiple_Dumps_And_Verify

    ${dump_1}=  Create User Initiated Dump
    ${dump_2}=  Create User Initiated Dump
    ${dump_3}=  Create User Initiated Dump

    Wait Until Keyword Succeeds  1 min  10 sec  Check Dump Entry  ${dump_1}
    Wait Until Keyword Succeeds  1 min  10 sec  Check Dump Entry  ${dump_2}
    Wait Until Keyword Succeeds  1 min  10 sec  Check Dump Entry  ${dump_3}


Create And Delete Dump Multiple Times
    [Documentation]  Create and delete multiple times.
    [Tags]  Create_And_Delete_Dump_Multiple_Times

    :FOR  ${INDEX}  IN RANGE  1  5
    \  ${dump_id}=  Create User Initiated Dump
    \  Wait Until Keyword Succeeds  1 min  10 sec  Check Dump Entry  ${dump_id}
    \  Delete Dump Entry  ${dump_id}



*** Keywords ***

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
    \  Delete Dump Entry  ${dump_id}


Trigger Core Dump
    Open Connection And Log In
    # Find the pid of the active ipmid.
    ${cmd_prefix}=  Catenate  SEPARATOR=  ps -ef | egrep 'ipmid' |
    ${cmd_suffix}=  Catenate  SEPARATOR=  egrep -v grep | cut -c2-6
    ${pid}  ${stderr}=  Execute Command  ${cmd_prefix} ${cmd_suffix}
    ...  return_stdout=True  return_stderr=True
    Log to Console  ${pid}

    # Kill ipmid process
    ${cmd}=  Catenate  kill -11
    ${stdout}  ${stderr}=  Execute Command  ${cmd} ${pid}
    ...  return_stdout=True  return_stderr=True

    SSHLibrary.Close Connection


Post Testcase Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Close All Connections
