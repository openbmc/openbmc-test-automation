*** Settings ***

Documentation       eSEL's Test cases.

Resource            ../../../lib/ipmi_client.robot
Resource            ../../../lib/openbmc_ffdc.robot
Resource            ../../../lib/utils.robot
Resource            ../../../lib/boot_utils.robot
Resource            ../../../lib/esel_utils.robot
Resource            ../../../lib/boot_utils.robot
Variables           ../../../data/variables.py

Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail

Test Tags          eSEL

*** Variables ***

${stack_mode}            skip

${LOGGING_SERVICE}       xyz.openbmc_project.Logging.service

${ESEL_DATA}             ESEL=00 00 df 00 00 00 00 20 00 04 12 35 6f aa 00 00

${IPMI_RAW_PREFIX}       0x3a 0xf0 0x

*** Test Cases ***

Verify eSEL Using Redfish
    [Documentation]  Generate eSEL log and verify using redfish.
    [Tags]  Verify_eSEL_Using_Redfish

    Create eSEL  ${IPMI_RAW_PREFIX}
    Event Log Should Exist


Verify eSEL Entries Using Redfish
    [Documentation]  Verify that eSEL entries have data.
    [Tags]  Verify_eSEL_Entries_Using_Redfish

    Create eSEL  ${IPMI_RAW_PREFIX}
    Redfish.Login
    Verify eSEL Entries


# TODO: openbmc/openbmc-test-automation#1789
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
    # "Associations": [
    #    [
    #        "callout",
    #        "fault",
    #        ""
    #    ]
    # ]

    Create eSEL  ${IPMI_RAW_PREFIX}

    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${desc}=  Read Attribute  ${elog_entry[0]}  Description
    Should Not Be Empty  ${desc}  msg=${desc} is not populated.

    ${event_id}=  Read Attribute  ${elog_entry[0]}  EventID
    Should Not Be Equal  ${event_id}  ${None}
    ...  msg=${event_id} is populated default "None".


Verify Multiple eSEL Using Redfish
    [Documentation]  Generate multiple eSEL log and verify using redfish
    [Tags]  Verify_Multiple_eSEL_Using_Redfish

    Create eSEL  ${IPMI_RAW_PREFIX}
    ${entries}=  Count eSEL Entries
    Should Be Equal As Integers  ${entries}  ${2}
    ...  msg=Expecting 2 eSELs but found ${entries}.


# TODO: openbmc/openbmc-test-automation#1789
Check eSEL AdditionalData
    [Documentation]  Generate eSEL log and verify AdditionalData is
    ...              not empty.
    [Tags]  Check_eSEL_AdditionalData

    Create eSEL  ${IPMI_RAW_PREFIX}
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    # "/xyz/openbmc_project/logging/entry/1": {
    #    "Timestamp": 1487743771812,
    #    "AdditionalData": [],
    #    "Message": "org.open_power.Error.Host.Event.Event",
    #    "Id": 1,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Emergency"
    # }
    Should Not Be Empty  ${resp.json()["data"]["AdditionalData"]}


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
    ...  ${IPMI_RAW_PREFIX}${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
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
    ...  ${IPMI_RAW_PREFIX}${rev_id_ls} 0x${rev_id_ms} 0 0 0 0 0 1 2 3 4 5 6 7 8 9 0xa 0xb 0xc 0xd 0xe 0xf
    Should Be Empty    ${output}


*** Keywords ***


Suite Teardown Execution
    [Documentation]  Cleanup test logs and connection.
    Close All Connections
    Redfish.Logout


Restart Logging Service
    [Documentation]  Restart Logging to clear eSEL log.
    ${MainPID}  ${stderr}=  Execute Command
    ...  systemctl restart ${LOGGING_SERVICE}  return_stderr=True
    Should Be Empty  ${stderr}

    Sleep  10s  reason=Wait for service to restart properly.


Run IPMI Command Returned
    [Documentation]  Run the IPMI command and return the output.
    [Arguments]    ${args}

    # Description of Argument(s):
    # args      IPMI raw data
    #           (e.g: 0x00 0x03 0x03).

    ${output_1}=    Execute Command   /tmp/ipmitool -I dbus raw ${args}
    RETURN    ${output_1}


Check IPMI OEMpartialadd Reject
    [Documentation]  Check if IPMI rejects the OEM partial add command.
    [Arguments]    ${args}

    # Description of Argument(s):
    # args      IPMI raw data
    #           (e.g: 0x00 0x03 0x03).

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_2}=  Execute Command  ipmitool raw ${args}
    ...        return_stdout=True  return_stderr=True  return_rc=True
    RETURN  ${stderr}


Test Setup Execution
   [Documentation]  Do test case setup tasks.

    Redfish.Login
    Redfish Purge Event Log


Suite Setup Execution
    [Documentation]  Validates input parameters & check if HOST OS is up.

    Should Not Be Empty
    ...   ${OS_HOST}  msg=You must provide DNS name/IP of the OS host.
    Should Not Be Empty
    ...   ${OS_USERNAME}  msg=You must provide OS host user name.
    Should Not Be Empty
    ...   ${OS_PASSWORD}  msg=You must provide OS host user password.

    # Boot to OS.
    Redfish Power On

    Redfish.Login
    Redfish Purge Event Log

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    Open Connection And Log In


Check IPMI OEMpartialadd Accept
    [Documentation]  Check if IPMI accepts the OEM partial add command.
    [Arguments]    ${args}

    # Description of Argument(s):
    # args      IPMI raw data
    #           (e.g: 0x00 0x03 0x03).

    Login To OS Host  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}
    ${stdout}  ${stderr}  ${output_3}=  Execute Command  ipmitool raw ${args}
    ...         return_stdout=True  return_stderr=True  return_rc=True
    Should Be Equal  ${output_3}  ${0}  msg=${stderr}
    RETURN  ${stderr}


Event Log Should Exist
    [Documentation]  Event log entries should exist.

    ${elogs}=  Get Event Logs
    Should Not Be Empty  ${elogs}  msg=System event log entry is not empty.
