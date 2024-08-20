*** Settings ***

Documentation    Module to test IPMI SEL functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Resource         ../lib/logging_utils.robot

Library          ../lib/ipmi_utils.py
Library          ../lib/logging_utils.py

Variables        ../data/ipmi_raw_cmd_table.py

Test Setup       Test Setup Execution
Test Teardown    FFDC On Test Case Fail

Test Tags       IPMI_SEL

*** Variables ***

# Based on 13th byte of add SEL entry command as per IPMI spec
# event_dir and event_type variable value needs to be given.
${sel_no_entry_msg}  SEL has no entries
${event_type}        Lower Non-critical going low
${event_dir}         Asserted

*** Test Cases ***

Verify IPMI SEL Version
    [Documentation]  Verify IPMI SEL's version info.
    [Tags]  Verify_IPMI_SEL_Version
    ${version_info}=  Get IPMI SEL Setting  Version
    ${setting_status}=  Fetch From Left  ${version_info}  (
    ${setting_status}=  Evaluate  $setting_status.replace(' ','')

    Should Be True  ${setting_status} >= 1.5
    Should Contain  ${version_info}  v2 compliant  case_insensitive=True


Verify Empty SEL
    [Documentation]  Verify IPMI sel clear command clears the SEL entry.
    [Tags]  Verify_Empty_SEL

    Redfish Power Off  stack_mode=skip

    # Generate an error log and verify there is one at least.
    Create Test PEL Log
    ${resp}=  Run IPMI Standard Command  sel elist last 1
    Log To Console  ${resp}

    Should Contain Any  ${resp}  system hardware failure   Asserted
    ...  msg=Add SEL Entry failed.

    # Send SEL clear command and verify if it really clears up the SEL entry.
    Run IPMI Standard Command  sel clear

    # Added a delay for IPMI SEL to clear completely.
    Sleep  5s

    ${resp}=  Run IPMI Standard Command  sel list

    # After executing the IPMI SEL clear command, there will be an informational
    # SEL entry in the IPMI SEL. Therefore, checking if the IPMI SEL count is 1
    # after clearing SEL.

    ${sel_count}=  Get Line Count  ${resp}
    Should Be Equal As Strings  ${sel_count}  1


Verify Add SEL Entry
    [Documentation]  Verify add SEL entry.
    [Tags]  Verify_Add_SEL_Entry
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Run IPMI Standard Command  sel clear

    # The IPMI raw command to generate Temp sensor  error is no longer working.
    # Our aim is to check if the SEL command is listed in IPMI or not.
    # Original keyword "Create User Defined SEL" for reference
    Create Test PEL Log

    # Get last SEL entry.
    ${resp}=  Run IPMI Standard Command  sel elist last 1
    #  output:
    #  1 | 11/17/2021 | 07:49:20 | System Event #0x01 | Undetermined system hardware failure | Asserted
    Run Keywords  Should Contain  ${resp}  system hardware failure  AND
    ...  Should Contain  ${resp}  Asserted  msg=Add SEL Entry failed.


Verify Add SEL Entry For Any Random Sensor
    [Documentation]  Create SEL entry and verify for any given random sensor.
    [Tags]  Verify_Add_SEL_Entry_For_Any_Random_Sensor
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Run IPMI Standard Command  sel clear

    # Get any sensor available from sensor list.
    ${sensor_name}=  Fetch One Threshold Sensor From Sensor List

    # Get Sensor ID from SDR get "sensor".
    ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
    ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

    # Get Sensor Type from SDR get "sensor".
    ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
    ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

    # Add SEL Entry.
    # ${sel_entry_id} is the Record ID for added record (LSB First).
    ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}
    ${sel_entry_id}=  Split String  ${sel_create_resp}

    # Get last SEL entry.
    ${resp}=  Run IPMI Standard Command  sel elist
    Should Not Contain  ${resp}  ${sel_no_entry_msg}

    # Output of the Sel elist.
    # Below example is a continuous line statement.
    #    N | MM/DD/YYYY | HH:MM:SS | Sensor_Type Sensor_Name |
    #    Lower Non-critical going low  | Asserted | Reading 0.

    ${get_sel_entry}=  Get Lines Containing String  ${resp}  ${sensor_name}
    ${sel_entry}=  Get Lines Containing String  ${get_sel_entry}  ${event_type}
    Should Contain  ${sel_entry}  ${event_dir}  msg=Add SEL Entry failed.

    # Get SEL Entry IPMI Raw Command.
    ${entry}=  Get SEL Entry Via IPMI  ${sel_entry_id[0]}  ${sel_entry_id[1]}

    # Compare SEL Record ID.
    ${sel_record_id}=  Set Variable  ${entry[2:4]}
    Should Be Equal  ${sel_record_id}  ${sel_entry_id}

    # Sensor type compare.
    Should Be Equal  ${sensor_type_id}  ${entry[12]}

    # Sensor number compare.
    Should Be Equal  ${sensor_number}  ${entry[13]}


Verify Reserve SEL
    [Documentation]  Verify reserve SEL.
    [Tags]  Verify_Reserve_SEL

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Execute clear SEL raw command with Reservation ID.
    # Command will not execute unless the correct Reservation ID value is provided.
    Run IPMI Command
    ...  0x0a 0x47 0x${reserve_id[0]} 0x${reserve_id[1]} 0x43 0x4c 0x52 0xaa

    # Check SEL list.
    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify IPMI SEL Most Recent Addition Timestamp
    [Documentation]  Verify most recent addition timestamp in SEL info.
    [Tags]  Verify_IPMI_SEL_Most_Recent_Addition_Timestamp

    # Get Most Recent Addition Timestamp from SEL Info.
    ${addition_timestamp}=  Get Most Recent Addition Timestamp From SEL Info

    IF  '${addition_timestamp}' != 'ffffffff'
        # Convert to epoch timestamp.
        ${epoch_addition}=  Convert To Integer  ${addition_timestamp}  16

        # Get SEL List last 1 entry date and time and convert to epoch timestamp.
        ${sel_epoch_time}=  Get SEL Elist Last Entry Date In Epoch

        # Compare epoch of sel entry timestamp and last addition timestamp.
        ${diff}=  Evaluate  int(${sel_epoch_time}) - int(${epoch_addition})
        Should Be True  ${diff}<=600

    ELSE
        # Get any Sensor available from Sensor list
        ${sensor_name}=  Fetch One Threshold Sensor From Sensor List

        # Get Sensor ID from SDR Get "sensor" and Identify Sensor ID.
        ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
        ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

        # Get Sensor Type from SDR Get "sensor" and Identify Sensor Type.
        ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
        ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

        # Add SEL Entry.
        ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

        # Get SEL List last 1 entry date and time and convert to epoch timestamp.
        ${sel_epoch_time}=  Get SEL Elist Last Entry Date In Epoch

        # Get Most Recent Addition Timestamp from SEL Info.
        ${addition}=  Get Most Recent Addition Timestamp From SEL Info
        ${epoch_addition}=  Convert To Integer  ${addition}  16

        # Compare epoch of sel entry timestamp and last addition timestamp.
        ${diff}=  Evaluate  int(${epoch_addition}) - int(${sel_epoch_time})
        Should Be True  ${diff}<=5
    END


Verify IPMI SEL Most Recent Erase Timestamp
    [Documentation]  Verify Most Recent Erase Timestamp In SEL Info with current
    ...              BMC epoch timestamp.
    [Tags]  Verify_IPMI_SEL_Most_Recent_Erase_Timestamp

    # Get BMC Current Time.
    ${bmc_epoch_time}=  Get BMC Time In Epoch

    # Get Most Recent Addition Timestamp from SEL Info.
    ${addition_timestamp}=  Get Most Recent Addition Timestamp From SEL Info
    Should Be Equal  ${addition_timestamp}  ffffffff

    # Get Most Recent Erase Timestamp from SEL Info.
    ${erase_timestamp}=  Get Most Recent Erase Timestamp From SEL Info
    ${epoch_erase}=  Convert To Integer  ${erase_timestamp}  16

    # Compare epoch of erase timestamp and current bmc timestamp.
    ${diff}=  Evaluate  int(${epoch_erase}) - int(${bmc_epoch_time})
    Should Be True  ${diff}<=5


Verify Clear SEL With Invalid Reservation ID
    [Documentation]  Verify clear SEL After generating another reserve ID.
    [Tags]  Verify_Clear_SEL_With_Invalid_Reservation_ID

    # Reserve Sel command - 1.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Reserve Sel command - 2.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}

    ${cmd}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]}
    ...  0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}

    # Clear SEL command.
    ${clear_resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][4]}*
    ...  Run IPMI Command  ${cmd}
    Should Contain  ${clear_resp}  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][5]}


Verify Reservation ID Erasure Status
    [Documentation]  Verify Erasure status by clearing SEL with Reserve ID and verify the response byte,
    ...  whether erasure status is updated in clear sel command response data using new Reserve ID.
    [Tags]  Verify_Reservation_ID_Erasure_Status

    # Generate Reserve ID 1.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    ${cmd1}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]}
    ...  0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}

    # Execute clear SEL raw command with Reservation ID.
    # Command will not execute unless the correct Reservation ID value is provided.
    Run IPMI Command  ${cmd1}

    # Generate Reserver ID 2.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    ${cmd2}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]}
    ...  0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][6]}

    # Check the Erasure status of Clear SEL.
    ${data}=  Run IPMI Command  ${cmd2}

    # 00 - Erasure in Progress , 01 - Erasure Complete.
    Should Contain Any  ${data}  00  01


Verify Clear SEL After Cold Reset
    [Documentation]  Verify Clear SEL for a reserve SEL ID after Cold Reset.
    [Tags]  Verify_Clear_SEL_After_Cold_Reset

    # Reserve Sel command.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Run Cold Reset.
    IPMI MC Reset Cold (off)

    ${cmd}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]}
    ...  0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}

    # Clear SEL command.
    ${clear_resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][5]}*
    ...  Run IPMI Command  ${cmd}

    Should Contain  ${clear_resp}  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][4]}


Delete Non Existing SEL Event Entry
    [Documentation]  Delete non existing SEL event entry.
    [Tags]  Delete_Non_Existing_SEL_Event_Entry

    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete 100
    Should Contain  ${sel_delete}  Unable to delete entry
    ...  case_insensitive=True


Delete Invalid SEL Event Entry
    [Documentation]  Delete invalid SEL event entry.
    [Tags]  Delete_Invalid_SEL_Event_Entry

    ${sel_delete}=  Run Keyword And Expect Error  *
    ...  Run IPMI Standard Command  sel delete abc
    Should Contain  ${sel_delete}  Given SEL ID 'abc' is invalid
    ...  case_insensitive=True


Verify IPMI SEL Event Last Add Time
    [Documentation]  Verify IPMI SEL's last added timestamp.
    [Tags]  Verify_IPMI_SEL_Event_Last_Add_Time
    [Setup]  Install Tarball For Error Creation

    Create Test Error Log
    ${sel_time}=  Run IPMI Standard Command  sel time get
    ${sel_time}=  Convert Date  ${sel_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${sel_last_add_time}=  Get IPMI SEL Setting  Last Add Time
    ${sel_last_add_time}=  Convert Date  ${sel_last_add_time}
    ...  date_format=%m/%d/%Y %H:%M:%S  exclude_millis=True

    ${time_diff}=
    ...  Subtract Date From Date  ${sel_last_add_time}  ${sel_time}

    # Verify if the delay in current time check and last add SEL time
    # is less or equals to 2 seconds.
    Should Be True  ${time_diff} <= 2


Verify IPMI SEL Event Entries
    [Documentation]  Verify IPMI SEL's entries info.
    [Tags]  Verify_IPMI_SEL_Event_Entries
    [Setup]  Install Tarball For Error Creation

    # Clear all SEL entries using IPMI command.
    Run IPMI Standard Command  sel clear

    # Added a delay for IPMI SEL to clear completely.
    Sleep  5s

    # Generate error logs of random count.
    ${count}=  Evaluate  random.randint(1, 5)  modules=random
    Repeat Keyword  ${count}  Create Test Error Log

    ${sel_entries_count}=  Get IPMI SEL Setting  Entries

    # After issuing the IPMI SEL clear command.
    # There will be one informational SEL entry in the IPMI SEL.
    # So comparing the IPMI SEL count with this additional single entry.
    Should Be Equal As Strings  ${sel_entries_count}  ${count + 1}


*** Keywords ***

Create User Defined SEL
    [Documentation]  Create a user defined tempearature sensor SEL.

    # Create a SEL.
    # Example:
    # a | 02/14/2020 | 01:16:58 | Temperature #0x17 |  | Asserted
    Run IPMI Command
    ...  0x0a 0x44 0x00 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x04 0x01 ${sensor_number} 0x00 0xa0 0x04 0x07


Get SEL Entry Via IPMI
    [Documentation]  Get SEL Entry Via IPMI raw command.
    [Arguments]  ${record1}  ${record2}

    # Description of Argument(s):
    # ${record1}    Record ID for added record, LS Byte
    # ${record2}    Record ID for added record, MS Byte

    # For example, when a first sel entry is added with IPMI raw command, the response will be "01 00".
    # Here, ${record1} is 01, and ${record2} is 00.

    ${cmd}=  Catenate  ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Entry'][0]} 0x${record1}
    ...  0x${record2} ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Entry'][1]}

    # Get SEL Entry Raw command.
    ${resp}=  Run IPMI Command  ${cmd}
    ${resp}=  Split String  ${resp}

    RETURN  ${resp}


Get Most Recent Addition Timestamp From SEL Info
    [Documentation]  Get Most recent addition timestamp From SEL Info.

    # Get SEL Info raw command.
    ${sel_info}=  Get SEL Info Via IPMI

    # Get Most Recent Addition timestamp in hex.
    ${addition_timestamp}=  Set Variable  ${sel_info[5:9]}
    Reverse List  ${addition_timestamp}
    ${addition_timestamp}=  Evaluate  "".join(${addition_timestamp})

    RETURN  ${addition_timestamp}


Get Most Recent Erase Timestamp From SEL Info
    [Documentation]  Get Most recent erase timestamp From SEL Info.

    # Get SEL Info Raw command.
    ${sel_info}=  Get SEL Info Via IPMI

    # Get Most Recent Erase timestamp in hex.
    ${erase_timestamp}=  Set Variable  ${sel_info[9:13]}
    Reverse List  ${erase_timestamp}
    ${erase_timestamp}=  Evaluate  "".join(${erase_timestamp})

    RETURN  ${erase_timestamp}


Get SEL Elist Last Entry Date In Epoch
    [Documentation]  Get the time from SEL elist last entry and returns epoch time.

    # Get SEL list last entry.
    ${resp}=  Run IPMI Standard Command  sel elist last 1

    # Get date from the sel entry and convert to epoch timestamp.
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}
    ${epoch_date}=  Convert Date  ${sel_entry_date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    RETURN  ${epoch_date}


Get BMC Time In Epoch
    [Documentation]  Get the current time from BMC and returns epoch time.

    # Get the bmc native bmc date command response.
    ${date}=  Get Current Date from BMC

    ${epoch_date}=  Convert Date  ${date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    RETURN   ${epoch_date}


Install Tarball For Error Creation
    [Documentation]  Install tarball for error log creation.

    ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball


Test Setup Execution
    [Documentation]  Do test setup tasks.

    Run IPMI Standard Command  sel clear
    Sleep  5s
