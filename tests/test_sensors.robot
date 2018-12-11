*** Settings ***
Documentation          This example demonstrates executing commands on a remote machine
...                    and getting their output and the return code.
...
...                    Notice how connections are handled as part of the suite setup and
...                    teardown. This saves some time when executing several test cases.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/state_manager.robot
Library                ../data/model.py
Resource               ../lib/boot_utils.robot
Resource               ../lib/utils.robot

Suite Setup            Suite Setup Execution
Test Teardown          Test Teardown Execution

*** Variables ***

${stack_mode}     skip
${model}=         ${OPENBMC_MODEL}

*** Test Cases ***

io_board Present
    [Documentation]  Verify that the IO board is present.
    [Tags]  io_board_Present
    ${uri}=  Get System component  io_board
    Verify The Attribute  ${uri}  Present  ${True}

io_board Fault
    [Documentation]  Verify that the IO board signals "fault".
    [Tags]  io_board_Fault
    ${uri}=  Get System component  io_board
    Verify The Attribute  ${uri}  fault  ${False}

*** Keywords ***

Suite Setup Execution
    [Documentation]  Initial suite setup.

    # Boot Host.
    REST Power On

    ${resp}=   Read Properties   ${OPENBMC_BASE_URI}enumerate   timeout=30
    Set Suite Variable      ${SYSTEM_INFO}          ${resp}
    log Dictionary          ${resp}

Get System component
    [Documentation]  Get the system component.
    [Arguments]    ${type}
    ${list}=    Get Dictionary Keys    ${SYSTEM_INFO}
    ${resp}=    Get Matches    ${list}    regexp=^.*[0-9a-z_].${type}\[0-9]*$
    ${url}=    Get From List    ${resp}    0
    [Return]    ${url}


Test Teardown Execution
    [Documentation]  Do the post test teardown.
    ...  1. Capture FFDC on test failure.
    ...  2. Close all open SSH connections.

    FFDC On Test Case Fail
    Close All Connections
