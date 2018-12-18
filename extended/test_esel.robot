*** Settings ***

Documentation       eSEL's Test cases.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Variables           ../data/variables.py
Resource            ../lib/boot_utils.robot
Resource            ../lib/esel_utils.robot

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Teardown       FFDC On Test Case Fail
Test Setup          Delete All Error Logs

Force Tags  eSEL_Logging

*** Variables ***

${stack_mode}       skip

${LOGGING_SERVICE}  xyz.openbmc_project.Logging.service

${ESEL_DATA}        ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00

*** Test Cases ***

Verify eSEL Using REST
    [Documentation]  Generate eSEL log and verify using REST.
    [Tags]  Verify_eSEL_Using_REST

    Create eSEL
    # New eSEL log should exist
    ${resp}=  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}list
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Verify eSEL Entries Using REST
    [Documentation]  Verify that eSEL entries have data.
    [Tags]  Verify_eSEL_Entries_Using_REST

    Create eSEL
    Verify eSEL Entries

Verify eSEL Description And EntryID Using REST
    [Documentation]  Create eSEL log and verify "Description" and "EntryID"
    ...  are not empty via REST.
    [Tags]  Verify_eSEL_Description_And_EntryID_Using_REST

    # {
    # "AdditionalData": [
    #     "CALLOUT_INVENTORY_PATH=",
    #     "ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00",
    #     "_PID=1175"
    # ],
    # "Description": "An error was detected with the base platform,
    #  but was not able to be deciphered. Contact your next level of support.",
    # "EventID": "FQPSPAA0011M",
    # "Id": 1,
    # "Message": "org.open_power.Host.Error.Event",
    # "Resolved": 0,
    # "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    # "Timestamp": 1524233022072,
    # "associations": [
    #    [
    #        "callout",
    #        "fault",
    #        ""
    #    ]
    # ]

    Create eSEL

    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${desc}=  Read Attribute  ${elog_entry[0]}  Description
    Should Not Be Empty  ${desc}  msg=${desc} is not populated.

    ${event_id}=  Read Attribute  ${elog_entry[0]}  EventID
    Should Not Be Equal  ${event_id}  ${None}
    ...  msg=${event_id} is populated default "None".


Verify Multiple eSEL Using REST
    [Documentation]  Generate multiple eSEL log and verify using REST.
    [Tags]  Verify_Multiple_eSEL_Using_REST

    Create eSEL
    Create eSEL
    ${entries}=  Count eSEL Entries
    # 1 eSEL creates 1 error log and 1 association.
    Should Be Equal As Integers  ${entries}  ${4}

Check eSEL AdditionalData
    [Documentation]  Generate eSEL log and verify AdditionalData is
    ...              not empty.
    [Tags]  Check_eSEL_AdditionalData

    Create eSEL
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${jsondata}=  To JSON  ${resp.content}
    # "/xyz/openbmc_project/logging/entry/1": {
    #    "Timestamp": 1487743771812,
    #    "AdditionalData": [],
    #    "Message": "org.open_power.Error.Host.Event.Event",
    #    "Id": 1,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency"
    # }
    Should Not Be Empty  ${jsondata["data"]["AdditionalData"]}

Test Wrong Reservation_ID
    [Documentation]  This testcase is to test BMC can handle multi-requestor's
    ...              oem partial add command with incorrect reservation id.
    ...              It simulates sending partial add command with fake content
    ...              and wrong Reservation ID. This command will be rejected.
    [Tags]  Test_Wrong_Reservation_ID

    ${rev_id_1}=   Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_1}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_1}   -2
    Run Inband IPMI Raw Command   0x0a 0x42
    ${output}=  Check IPMI OEMpartialadd Reject
    ...  0x3a 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Contain   ${output}   Reservation cancelled

Test Correct Reservation_ID
    [Documentation]  This testcase is to test BMC can handle multi-requestor's
    ...              oem partial add command with correct reservation id. It
    ...              simulates sending partial add command with fake content
    ...              and correct Reservation ID. This command will be accepted.
    [Tags]  Test_Correct_Reservation_ID

    Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_2}=    Run Inband IPMI Raw Command  0x0a 0x42
    ${rev_id_ls}=   Get Substring   ${rev_id_2}   1   3
    ${rev_id_ms}=   Get Substring   ${rev_id_2}   -2
    ${output}=  Check IPMI OEMpartialadd Accept
    ...  0x3a 0xf0 0x${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Be Empty    ${output}


*** Keywords ***


Suite Teardown Execution
    [Documentation]  Cleanup test logs and connection.
    Close All Connections


Restart Logging Service
    [Documentation]  Restart Logging to clear eSEL log.
    ${MainPID}  ${stderr}=  Execute Command
    ...  systemctl restart ${LOGGING_SERVICE}  return_stderr=True
    Should Be Empty  ${stderr}

    Sleep  10s  reason=Wait for service to restart properly.


Run IPMI Command Returned
    [Documentation]  Run the IPMI command and return the output.
    [Arguments]    ${args}
    ${output_1}=    Execute Command   /tmp/ipmitool -I dbus raw ${args}
    [Return]    ${output_1}


Check IPMI OEMpartialadd Reject
    [Documentation]  Check if IPMI rejects the OEM partial add command.
    [Arguments]    ${args}
    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_2}=  Execute Command  ipmitool raw ${args}
    ...        return_stdout=True  return_stderr=True  return_rc=True
    [Return]  ${stderr}


Suite Setup Execution
    [Documentation]  Validates input parameters & check if HOST OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    REST Power On

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Open Connection And Log In


Check IPMI OEMpartialadd Accept
    [Documentation]  Check if IPMI accepts the OEM partial add command.
    [Arguments]    ${args}
    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_3}=  Execute Command  ipmitool raw ${args}
    ...         return_stdout=True  return_stderr=True  return_rc=True
    Should Be Equal  ${output_3}  ${0}  msg=${stderr}
    [Return]  ${stderr}
