*** Settings ***

Documentation       eSEL's Test cases.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/variables.py

Suite Setup         Open Connection And Log In
Suite Teardown      Close All Connections
Test Teardown       FFDC On Test Case Fail

Force Tags  eSEL_Logging

*** Variables ***

${RESERVE_ID}       raw 0x0a 0x42
${RAW_PREFIX}       raw 0x32 0xf0 0x

${RAW_SUFFIX}       0x00 0x00 0x00 0x00 0x00 0x01 0x00 0x00
...  0xdf 0x00 0x00 0x00 0x00 0x20 0x00 0x04 0x12 0x35 0x6f 0xaa 0x00 0x00

${RAW_SEL_COMMIT}   raw 0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x20
...  0x00 0x04 0x12 0x35 0x6f 0x02 0x00 0x01

${LOGGING_SERVICE}  xyz.openbmc_project.Logging.service

*** Test Cases ***

Verify eSEL Using REST
    [Documentation]  Generate eSEL log and Verify using REST.
    [setup]  Restart Logging Service
    [Tags]  Verify_eSEL_Using_REST

    # Prior eSEL log shouldn't exist
    ${resp}=   OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

    Open Connection And Log In
    ${Resv_id}=  Run Dbus IPMI Standard Command  ${RESERVE_ID}
    ${cmd}=  Catenate
    ...  ${RAW_PREFIX}${Resv_id.strip().rsplit(' ', 1)[0]}  ${RAW_SUFFIX}
    Run Dbus IPMI Standard Command  ${cmd}
    Run Dbus IPMI Standard Command  ${RAW_SEL_COMMIT}

    # New eSEL log should exist
    ${resp}=   OpenBMC Get Request  ${BMC_LOGGING_ENTRY}${1}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}


Test Wrong Reservation_ID
    [Documentation]   This testcase is to test BMC can handle multi-requestor's
    ...               oem partial add command with incorrect reservation id.
    ...               It simulates sending partial add command with fake content
    ...                and wrong Reservation ID. This command will be rejected.
    [Tags]  Test_Wrong_Reservation_ID

    ${rev_id_1}=    Run IPMI Command Returned   0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_1}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_1}   -2
    Run IPMI command   0x0a 0x42
    ${output}=      Check IPMI Oempartialadd Reject   0x32 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Contain   ${output}   Reservation cancelled

Test Correct Reservation_ID
    [Documentation]   This testcase is to test BMC can handle multi-requestor's
    ...               oem partial add command with correct reservation id. It
    ...                simulates sending partial add command with fake content
    ...               and correct Reservation ID. This command will be accepted.
    [Tags]  Test_Correct_Reservation_ID

    Run IPMI command   0x0a 0x42
    ${rev_id_2}=    Run IPMI Command Returned   0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_2}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_2}   -2
    ${output}=      Check IPMI Oempartialadd Accept   0x32 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Be Empty    ${output}

Clear Test File
   [Documentation]   Clear /tmp/esel
   [Tags]  Clear_Test_File

   Execute Command   rm /tmp/esel
   Execute Command   sync

*** Keywords ***

Restart Logging Service
    [Documentation]  Restart Logging to clear eSEL log.
    ${MainPID}  ${stderr}=  Execute Command
    ...  systemctl -p MainPID show ${LOGGING_SERVICE}| cut -d = -f2
    ...  return_stderr=True
    Should Be Empty  ${stderr}

    ${stdout}  ${stderr}=  Execute Command
    ...  kill -9 ${MainPID}  return_stderr=True
    Should Be Empty  ${stderr}
    Sleep  10s  reason=Wait for service to restart properly.

Run IPMI Command Returned
    [Arguments]    ${args}
    ${output_1}=    Execute Command    /tmp/ipmitool -I dbus raw ${args}
    [Return]    ${output_1}

Check IPMI Oempartialadd Reject
    [Arguments]    ${args}
    ${stdout}    ${stderr}    ${output_2}=  Execute Command    /tmp/ipmitool -I dbus raw ${args}    return_stdout=True    return_stderr= True    return_rc=True
    [Return]    ${stderr}

Check IPMI Oempartialadd Accept
    [Arguments]    ${args}
    ${stdout}    ${stderr}    ${output_3}=    Execute Command    /tmp/ipmitool -I dbus raw ${args}    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output_3}    ${0}    msg=${stderr}
    [Return]    ${stderr}

