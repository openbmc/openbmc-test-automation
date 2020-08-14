*** Settings ***
Documentation       This suite will test the host console

Resource            ../lib/resource.robot
Resource            ../lib/utils.robot

Library             SSHLibrary

Suite Setup         Open Connection And Log In
Test Setup          Test Setup Execution
Suite Teardown      Close All Connections

*** Variables ***

${HOST_LOG_PATH}       /var/lib/obmc/hostlogs


*** Test Cases ***

Verify Host Console Connection
    [Documentation]  Connect the obmc-console from BMC and verify the logs.
    [Tags]  Verify_Host_Console_Connection

    Write       obmc-console-client
    Write       \n
    ${write}=   Read Until  login:
    Write       ${OS_USERNAME}
    ${pass}=    Read Until  Password:
    Write       ${OS_PASSWORD}
    Write       hostname
    Write       exit

    BMC Execute Command  rm -rf ${HOST_LOG_PATH}
    ${id}  ${stderr}  ${rc}=  BMC Execute Command  ps | grep hostlogger | grep -v grep | cut -c2-5

    # Flush the messages generated in buffer and store as a log file.
    BMC Execute Command  kill -s USR1 ${id}
    Sleep  5s
    ${gz_file}  ${stderr}  ${rc}=  BMC Execute Command  ls ${HOST_LOG_PATH}
    BMC Execute Command  gunzip ${HOST_LOG_PATH}/${gz_file}
    Sleep  5s
    ${log_file}  ${stderr}  ${rc}=  BMC Execute Command  ls ${HOST_LOG_PATH}
    ${string_compare} =  BMC Execute Command  grep hostname ${HOST_LOG_PATH}/${log_file}
    Should Be True  ${string_compare}  hostname


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    Should Not Be Empty  ${OS_USERNAME}
    Should Not Be Empty  ${OS_PASSWORD}
