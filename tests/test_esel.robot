*** Settings ***

Documentation   This suite is for testing esel's mechanism of checking Reservation_ID.

Resource          ../lib/ipmi_client.robot
Resource          ../lib/openbmc_ffdc.robot

Suite Setup            Open Connection And Log In
Suite Teardown         Close All Connections
Test Teardown          FFDC On Test Case Fail

*** Test Cases ***

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

   Execute Command   rm /tmp/esel
   Execute Command   sync

*** Keywords ***

Run IPMI Command Returned
    [Arguments]    ${args}
    ${output_1}=    Execute Command    /tmp/ipmitool -I dbus raw ${args}
    [return]    ${output_1}

Check IPMI Oempartialadd Reject
    [Arguments]    ${args}
    ${stdout}    ${stderr}    ${output_2}=  Execute Command    /tmp/ipmitool -I dbus raw ${args}    return_stdout=True    return_stderr= True    return_rc=True
    [return]    ${stderr}

Check IPMI Oempartialadd Accept
    [Arguments]    ${args}
    ${stdout}    ${stderr}    ${output_3}=    Execute Command    /tmp/ipmitool -I dbus raw ${args}    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output_3}    ${0}    msg=${stderr}
    [return]    ${stderr}

