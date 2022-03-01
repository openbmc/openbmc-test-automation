*** Settings ***

Documentation    Module to test IPMI SEL functionality.
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py

Test Teardown    FFDC On Test Case Fail

*** Variables ***

${sensor_number}      0x17


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
    [Documentation]  Verify empty SEL list.
    [Tags]  Verify_Empty_SEL

    Run IPMI Standard Command  sel clear
    Sleep  5s

    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify Add SEL Entry
    [Documentation]  Verify add SEL entry.
    [Tags]  Verify_Add_SEL_Entry
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND  Run IPMI Standard Command  sel clear

    Run IPMI Standard Command  sel clear
    Sleep  5s

    # Get any Sensor Available from Sensor List
    ${sensor_name}=  Fetch Any Sensor From Sensor List

    # Get Sensor ID from SDR Get "sensor"
    ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
    ${name_sensor}  ${sensor_number}=  Get Data And Byte From SDR Sensor  ${sensor_data1}

    # Get Sensor Type from SDR Get "sensor"
    ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
    ${sensor_type}  ${sensor_type_id}=  Get Data And Byte From SDR Sensor  ${sensor_data2}

    # Add SEL Entry
    ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}
    ${sel_entry_id}=  Split String  ${sel_create_resp}

    # Get Last SEL Entry
    ${resp}=  Run IPMI Standard Command  sel elist last 1

    # Output of the Sel elist last 1
    #  N | MM/DD/YYYY | HH:MM:SS | Sensor_Type Sensor_Name | Lower Non-critical going low  | Asserted | Reading 0

    Run Keywords  Should Contain  ${resp}  ${sensor_type} ${sensor_name}  AND
    ...  Should Contain  ${resp}  Asserted  msg=Add SEL Entry failed.

    # Get SEL Entry IPMI Raw Command
    ${entry}=  Get SEL Entry Via IPMI  ${sel_entry_id[0]}  ${sel_entry_id[1]}

    # Compare SEL Record ID
    ${sel_record_id}=  Set Variable  ${entry[2:4]}
    Should Be Equal  ${sel_record_id}  ${sel_entry_id}

    # Sensor Type Compare
    Should Be Equal  ${sensor_type_id}  ${entry[12]}

    # Sensor Number Compare
    Should Be Equal  ${sensor_number}  ${entry[13]}


Verify Reserve SEL
    [Documentation]  Verify reserve SEL.
    [Tags]  Verify_Reserve_SEL

    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Execute clear SEL raw command with Reservation ID.
    # Command will not execute unless the correct Reservation ID value is provided.
    Run IPMI Standard Command
    ...  raw 0x0a 0x47 0x${reserve_id[0]} 0x${reserve_id[1]} 0x43 0x4c 0x52 0xaa

    # Check SEL List
    ${resp}=  Run IPMI Standard Command  sel list
    Should Contain  ${resp}  SEL has no entries  case_insensitive=True


Verify IPMI SEL Most Recent Addition Timestamp
    [Documentation]  Verify Most Recent Addition Timestamp In SEL Info.
    [Tags]  Verify_IPMI_SEL_Most_Recent_Addition_Timestamp

    # Get Most Recent Addition Timestamp From SEL Info
    ${addition_timestamp}=  Get Most Recent Addition Timestamp From SEL Info

    IF  '${addition_timestamp}' != 'ffffffff'
        # Convert to epoch timestamp
        ${epoch_addition}=  Convert To Integer  ${addition_timestamp}  16

        # Get SEL List last 1 entry date and time and convert to epoch timestamp
        ${sel_epoch_time}=  Get SEL Elist Last Entry Date In Epoch

        # Compare epoch of sel entry timestamp and last addition timestamp
        ${diff}=  Evaluate  int(${sel_epoch_time}) - int(${epoch_addition})
        Should Be True  ${diff}<=600

    ELSE
        # Get any Sensor Available from Sensor List
        ${sensor_name}=  Fetch Any Sensor From Sensor List

        # Get Sensor ID from SDR Get "sensor" and Identify Sensor ID
        ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
        ${name_sensor}  ${sensor_number}=  Get Data And Byte From SDR Sensor  ${sensor_data1}

        # Get Sensor Type from SDR Get "sensor" and Identify Sensor Type
        ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
        ${sensor_type}  ${sensor_type_id}=  Get Data And Byte From SDR Sensor  ${sensor_data2}

        # Add SEL Entry
        ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

        # Get SEL List last 1 entry date and time and convert to epoch timestamp
        ${sel_epoch_time}=  Get SEL Elist Last Entry Date In Epoch

        # Get Most Recent Addition Timestamp From SEL Info
        ${addition}=  Get Most Recent Addition Timestamp From SEL Info
        ${epoch_addition}=  Convert To Integer  ${addition}  16

        # Compare epoch of sel entry timestamp and last addition timestamp
        ${diff}=  Evaluate  int(${epoch_addition}) - int(${sel_epoch_time})
        Should Be True  ${diff}<=5
    END


Verify IPMI SEL Most Recent Erase Timestamp
    [Documentation]  Verify Most Recent Erase Timestamp In SEL Info.
    [Tags]  Verify_IPMI_SEL_Most_Recent_Erase_Timestamp

    # Get BMC Current Time
    ${bmc_epoch_time}=  Get BMC Time In Epoch
    Run IPMI Standard Command  sel clear
    Sleep  5s

    # Get Most Recent Addition Timestamp From SEL Info
    ${addition_timestamp}=  Get Most Recent Addition Timestamp From SEL Info
    Should Be Equal  ${addition_timestamp}  ffffffff

    # Get Most Recent Erase Timestamp From SEL Info
    ${erase_timestamp}=  Get Most Recent Erase Timestamp From SEL Info
    ${epoch_erase}=  Convert To Integer  ${erase_timestamp}  16

    # Compare epoch of erase timestamp and current bmc timestamp
    ${diff}=  Evaluate  int(${epoch_erase}) - int(${bmc_epoch_time})
    Should Be True  ${diff}<=5


Verify Clear SEL With Invalid Reservation ID
    [Documentation]  Verify clear SEL After generating another reserve ID.
    [Tags]  Verify_Clear_SEL_With_Invalid_Reservation_ID

    # Reserve Sel command - 1
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Reserve Sel command - 2
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}

    # Clear SEL command
    ${clear_resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][4]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}
    Should Contain  ${clear_resp}  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][5]}


Verify Reservation ID Erasure Status
    [Documentation]  Verify reserve SEL.
    [Tags]  Verify_Reservation_ID_Erasure_Status

    # Generate Reserve ID 1
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Execute clear SEL raw command with Reservation ID.
    # Command will not execute unless the correct Reservation ID value is provided.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}

    # Generate Reserver ID 2
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Check the Erasure status of Clear SEL
    ${data}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][6]}

    # 00 - Erasure in Progress , 01 - Erasure Complete
    Should Contain Any  ${data}  00  01


Verify Clear SEL After Cold Reset
    [Documentation]  Verify Clear SEL for a reserve sel id after Cold Reset.
    [Tags]  Verify_Clear_SEL_After_Cold_Reset

    # Reserve Sel command
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Reserve'][0]}
    ${reserve_id}=  Split String  ${resp}

    # Run Cold Reset
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Resets']['cold'][0]}
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Clear SEL command
    ${clear_resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][1]}
    Should Contain  ${clear_resp}  ${IPMI_RAW_CMD['SEL_entry']['Clear_SEL'][4]}


*** Keywords ***

Get SEL Entry Via IPMI
    [Documentation]  Get SEL Entry Via IPMI raw command.
    [Arguments]  ${record1}  ${record2}

    # Get SEL Entry Raw command
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Entry'][0]} 0x${record1} 0x${record2} ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Entry'][1]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Get Most Recent Addition Timestamp From SEL Info
    [Documentation]  Get Most recent addition timestamp From SEL Info

    # Get SEL Info Raw command
    ${sel_info}=  Get SEL Info Via IPMI

    # Get Most Recent Addition timestamp in hex
    ${addition_timestamp}=  Set Variable  ${sel_info[5:9]}
    Reverse List  ${addition_timestamp}
    ${addition_timestamp}=  Evaluate  "".join(${addition_timestamp})

    [Return]  ${addition_timestamp}


Get Most Recent Erase Timestamp From SEL Info
    [Documentation]  Get Most recent erase timestamp From SEL Info

    # Get SEL Info Raw command
    ${sel_info}=  Get SEL Info Via IPMI

    # Get Most Recent Erase timestamp in hex
    ${erase_timestamp}=  Set Variable  ${sel_info[9:13]}
    Reverse List  ${erase_timestamp}
    ${erase_timestamp}=  Evaluate  "".join(${erase_timestamp})

    [Return]  ${erase_timestamp}


Get SEL Elist Last Entry Date In Epoch
    [Documentation]  Get the time from SEL elist last entry and returns epoch time.

    # Get SEL list last entry
    ${resp}=  Run IPMI Standard Command  sel elist last 1

    # Get date from the sel entry and convert to epoch timestamp
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}
    ${epoch_date}=  Convert Date  ${sel_entry_date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    [Return]  ${epoch_date}


Get BMC Time In Epoch
    [Documentation]  Get the current time from BMC and returns epoch time.

    # Get the bmc native bmc date command response
    ${date}=  ${current_date}=  Get Current Date from BMC

    # Convert the date format to %m/%d/%Y %H:%M:%S
    ${date}=  Convert Date  ${date}  date_format=%b %d %H:%M:%S %Y  result_format=%m/%d/%Y %H:%M:%S  exclude_millis=True
    ${epoch_date}=  Convert Date  ${date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    [Return]   ${epoch_date}