*** Settings ***
Documentation    Module to test IPMI Get BIOS POST Code Command.

Resource         ../lib/ipmi_client.robot
Resource         ../lib/boot_utils.robot
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

Suite Setup      IPMI Power On
Suite Teardown   IPMI Power On  stack_mode=skip  quiet=1

Test Tags        Get_BIOS_Post_Code

*** Test Cases ***

Test Get BIOS POST Code via IPMI Raw Command
    [Documentation]  Get BIOS POST Code via IPMI raw command.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command

    Wait Until Keyword Succeeds  10 min  1 sec  Check Host Is Pinging  ${OS_HOST}
    Wait Until Keyword Succeeds  1 min  1 sec  Check Chassis Power Status  on
    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}
    Verify POST Code Response Length  ${resp}

Test Get BIOS POST Code via IPMI Raw Command After Power Cycle
    [Documentation]  Get BIOS POST Code via IPMI raw command after power cycle.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command_After_Power_Cycle

    ${resp}=  Run IPMI Standard Command  chassis power cycle
    Wait Until Keyword Succeeds  1 min  1 sec  Check Host Is Not Pinging  ${OS_HOST}
    Wait Until Keyword Succeeds  10 min  1 sec  Check Host Is Pinging  ${OS_HOST}

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}
    Verify POST Code Response Length  ${resp}

Test Get BIOS POST Code via IPMI Raw Command With Host Powered Off
    [Documentation]  Get BIOS POST Code via IPMI raw command after power off.
    [Tags]  Test_Get_BIOS_POST_Code_via_IPMI_Raw_Command_With_Host_Powered_Off

    ${resp}=  Run IPMI Standard Command  chassis power off
    Wait Until Keyword Succeeds  1 min  1 sec  Check Host Is Not Pinging  ${OS_HOST}
    Wait Until Keyword Succeeds  1 min  1 sec  Check Chassis Power Status  off

    ${resp}=  Run IPMI Standard Command  raw ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][0]}  fail_on_err=0
    Should Contain  ${resp}  ${IPMI_RAW_CMD['BIOS_POST_Code']['Get'][3]}


*** Keywords ***
Verify POST Code Response Length
    [Documentation]  Verify the BIOS POST Code response byte length.
    [Tags]  Verify_POST_Code_Response_Length
    [Arguments]  ${resp}

    # Description of argument(s):
    # resp                          The complete response bytes from
    #                               Get BIOS POST Code command returned
    #                               in one string.

    @{resp_bytes}=  Split String  ${resp}
    ${string_length}=  Get Length  ${resp_bytes}

    # Convert response byte length to integer.
    ${value}=  Get Slice From List  ${resp_bytes}   2   4
    Reverse List   ${value}
    ${byte_length_string}=  Evaluate   "".join(${value})
    ${byte_length_integer}=  Convert To Integer  ${byte_length_string}  16
    ${true_length}=  Evaluate  (${string_length} - 4)

    Should Be Equal  ${true_length}  ${byte_length_integer}

Check Chassis Power Status
    [Documentation]  Validate chassis power status.
    [Arguments]  ${expected_state}

    # Description of argument(s):
    # expected_state    on, off

    ${resp}=  Run IPMI Standard Command  chassis power status
    Should Contain  ${resp}  ${expected_state}

Check Host Is Pinging
    [Documentation]  Check given ip/hostname is pinging.
    [Arguments]  ${host_ip}

    # Description of argument(s):
    # host_ip      The host name or IP of the host to ping.

    ${ping_rsp}=  Host Ping  ${host_ip}
    # Should Not Contain  ${ping_rsp}  Destination Host Unreachable
    # ...  msg=${host_ip} is not pinging.
    Should Not Contain  ${ping_rsp}  100% packet loss
    ...  msg=${host_ip} is not pinging.

Check Host Is Not Pinging
    [Documentation]  Check given ip/hostname is not pinging.
    [Arguments]  ${host_ip}

    # Description of argument(s):
    # host_ip      The host name or IP of the host to ping.

    ${ping_rsp}=  Host Ping  ${host_ip}
    Should Contain  ${ping_rsp}  100% packet loss
    ...  msg=${host_ip} is pinging.

Host Ping
    [Documentation]  Ping the given host.
    [Arguments]  ${host_ip}

    # Description of argument(s):
    # host_ip      The host name or IP of the host to ping.

    ${cmd}=  Catenate  ping -c 4 ${host_ip}
    ${output}=  Run  ${cmd}

    RETURN  ${output}
