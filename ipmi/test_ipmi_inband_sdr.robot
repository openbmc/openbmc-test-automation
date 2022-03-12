*** Settings ***
Documentation          Test IPMI Inband SDR commands.
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/boot_utils.robot
Library                ../lib/ipmi_utils.py
Variables              ../data/ipmi_raw_cmd_table.py

Suite setup            Redfish.Login
Suite Teardown         Redfish.Logout
Test Teardown          FFDC On Test Case Fail

Force Tags             SDR_Test


*** Test Cases ***

Verify Get SDR For Maximum Record Via IPMI
    [Documentation]  Verify Get SDR for each and every record one by one via IPMI lanplus.
    [Tags]  Verify_Get_SDR_For_Maximum_Record_Via_IPMI

    # Gets the Total Record Count from SDR Info and the last Record entry number.
    ${record_count}  ${last_record}=  Get Record Count And Last Record From SDR

    # Validate each and every record till the last record.
    FOR  ${record}  IN RANGE  0  ${record_count}
        # Convert number to hexadecimal record id.
        ${recordhex}=  Convert To Hex  ${record}  length=2  lowercase=yes

        # Get SDR command
        ${resp}=  Run IPMI Standard Command
        ...  raw ${IPMI_RAW_CMD['Get SDR']['Get'][1]} 0x00 0x00 0x${recordhex} 0x00 0x00 0xff
        ${get_sdr}=  Split String  ${resp}

        # If the record id reaches the last data available, the next record will be ff ff
        # Eg, If total record available is 115, Record IDs : 0 - 114
        # Then when record id reaches last record (i.e 114 - 72h),
        # Get SDR response bytes 0:2 will be - ff ff 72 00 ....
        # If not then (say 25 - 19h ), 1a 00 19 00 ....

        IF  '${record}' != '${last_record}'
          # current Record ID in response data
          Should Be Equal  ${get_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_sdr[3]}  00

          # Next Record ID in Response data
          ${record_next}=  Evaluate  ${record} + 1
          ${record_next}=  Convert To Hex  ${record_next}  length=2  lowercase=yes
          Should Be Equal  ${get_sdr[0]}  ${record_next}
          Should Be Equal  ${get_sdr[1]}  00
        ELSE
          # Next Record ID in Response data
          Should Be Equal  ${get_sdr[0]}  ff
          Should Be Equal  ${get_sdr[1]}  ff

          # current Record ID in response data
          Should Be Equal  ${get_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_sdr[3]}  00
        END

        # Response Data Count - total records (max - FFh - 255 in decimal)
        ${response_data}=  Set Variable  ${get_sdr[2:]}
        ${length}=  Get Length  ${response_data}
        Should Be True  0<${length}<=255
    END


Verify Sensor And SDR Count In Get Device SDR Info Via Inband IPMI
    [Documentation]  Verify Sensor and SDR Count in Get Device SDR Info via KCS interface.
    [Tags]  Verify_Sensor_And_SDR_Count_In_Get_Device_SDR_Info_Via_Inband_IPMI

    # Get Sensor count and SDR elist all count from IPMI LAN interface
    ${sensor_count_lan1}  ${sdr_count_lan1}=  Get Count for Sensor And SDR Elist All

    # Get Sensor Count From Get Device SDR Info command
    ${sensor_count1}=  Get Sensor Count From SDR Info
    # Compare Get Device SDR Sensor count with Sensor count from LAN
    Should Be Equal As Integers   ${sensor_count1}  ${sensor_count_lan1}

    # Get SDR Count From Get Device SDR Info command
    ${sdr_count1}=  Get SDR Count From SDR Info
    # Compare Get Device SDR Sdr count with SDR Elist All count from LAN
    Should Be Equal As Integers  ${sdr_count1}  ${sdr_count_lan1}

    # Reboot Host using Chassis Power Cycle
    IPMI Power Cycle

    # Get Sensor count and SDR elist all count from IPMI LAN interface
    ${sensor_count_lan2}  ${sdr_count_lan2}=  Get Count for Sensor And SDR Elist All

    # Get Sensor Count From Get Device SDR Info command
    ${sensor_count2}=  Get Sensor Count From SDR Info
    # Compare Get Device SDR Sensor count with Sensor count from LAN
    Should Be Equal As Integers   ${sensor_count2}  ${sensor_count_lan2}

    # Get SDR Count From Get Device SDR Info command
    ${sdr_count2}=  Get SDR Count From SDR Info
    # Compare Get Device SDR Sdr count with SDR Elist All count from LAN
    Should Be Equal As Integers  ${sdr_count2}  ${sdr_count_lan2}


Verify Timestamp In Get Device SDR Info Via Inband IPMI
    [Documentation]  Verify timestamp In Get Device SDR Info via KCS interface.
    [Tags]  Verify_Timestamp_In_Get_Device_SDR_Info_Via_Inband_IPMI

    # Reboot Host using Chassis Power Cycle
    IPMI Power Cycle

    # Get epoch Timestamp obtained from Get Device SDR Info command
    ${sdr_timestamp}=  Get Device SDR Timestamp

    # Get current date from BMC Native Date command and convert to epoch
    ${bmc_date}=  Get Current Date from BMC
    ${epoch_bmc}=  Convert Date  ${bmc_date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    # Compare time difference between bmc time and Get Device SDR Info timestamp
    # The maximum time difference should be less then 6 minute - 360 seconds
    ${difference}=  Evaluate  int(${epoch_bmc}) - int(${sdr_timestamp})
    Should Be True  ${difference}<=360


Verify Get Device SDR Info For Invalid Data Request
    [Documentation]  Verify Get Device SDR Info via KCS interface with extra bytes.
    [Tags]  Verify_Get_Device_SDR_Info_For_Invalid_Data_Request

    # Sensor Count Via Device SDR Info with extra bytes
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][3]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]} 0x00
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][2]}

    # SDR Count Via Device SDR Info with extra bytes
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][3]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]} 0x00
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][2]}


Verify Device SDR Info Via IPMI Lanplus
    [Documentation]  Verify whether Get Device SDR Info command is accessible via Lanplus.
    [Tags]  Verify_Device_SDR_Info_Via_IPMI_Lanplus

    # Sensor Count Via Device SDR Info via lanplus
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]}
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][4]}

    # SDR Count Via Device SDR Info via lanplus
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]}
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][4]}


Verify Reserve Device SDR Repository Via Inband IPMI
    [Documentation]  Verify Reserve Device SDR Repository via KCS interface.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Via_Inband_IPMI

    # Reserve Device SDR Repository via KCS interface
    ${resp}=  Get Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    # Identify the byte count
    ${length}=  Get Length  ${reserve_id}
    Should Be Equal As Integers  ${length}  2


Verify Reserve Device SDR Repository For Invalid Data Request
    [Documentation]  Verify Reserve Device SDR Repository via KCS interface with extra request bytes.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Invalid_Data_Request

    # Reserve Device SDR Repository with extra request bytes
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][2]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]} 0x00
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][1]}


Verify Reserve Device SDR Repository Info Via IPMI Lanplus
    [Documentation]  Verify whether Reserve Device SDR Repository command is accessible via Lanplus.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Via_IPMI_Lanplus

    # Reserve Device SDR Repository via lanplus
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][4]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]}
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][3]}


Verify Reserve Device SDR Repository For Partial Record
    [Documentation]  Verify whether reservation id of Reserve Device SDR Repository is accessible to fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Partial_Record

    ${resp}=  Get Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f
    ${resp}=  Split String  ${resp}
    ${resp}=  Set Variable  ${resp[2:]}
    ${length}=  Get Length  ${resp}
    Should Be Equal As Integers  ${length}  15


Verify Reserve Device SDR Repository For Partial Record After BMC Reboot
    [Documentation]  Verify whether reservation id of Reserve Device SDR Repository is accessible after bmc reboot to fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Partial_Record_After_BMC_Reboot

    ${resp}=  Get Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    ${resp1}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f

    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Resets']['cold'][0]}
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    ${resp2}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} ${reserve_id[0]} ${reserve_id[1]} 0x00 0x00 0x00 0x0f


Verify Reserve Device SDR Repository Invalid Reservation ID For Partial Record
    [Documentation]  Verify whether invalid reservation id of Reserve Device SDR Repository is accessible to fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Invalid_Reservation_ID_For_Partial_Record

    ${resp}=  Get Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    ${resp2}=  Get Reserve Device SDR Repository

    ${resp1}=   Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f


Verify Get Device SDR For Maximum Record Via IPMI
    [Documentation]  Verify Get Device SDR for each and every Record Via IPMI lanplus.
    [Tags]  Verify_Get_Device_SDR_For_Maximum_Record_Via_IPMI

    # Gets the Total Record Count from SDR Info and the last Record entry number.
    ${record_count}  ${last_record}=  Get Record Count And Last Record From SDR

    # Validate each and every record till the last record.
    FOR  ${record}  IN RANGE  0  ${record_count}
        # Convert number to hexadecimal record id.
        ${recordhex}=  Convert To Hex  ${record}  length=2  lowercase=yes

        # Get SDR command
        ${resp}=  Run IPMI Standard Command
        ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x00 0x00 0x${recordhex} 0x00 0x00 0xff
        ${get_dev_sdr}=  Split String  ${resp}

        # If the record id reaches the last data available, the next record will be ff ff
        # Eg, If total record available is 115, Record IDs : 0 - 114
        # Then when record id reaches last record (i.e 114 - 72h),
        # Get SDR response bytes 0:2 will be - ff ff 72 00 ....
        # If not then (say 25 - 19h ), 1a 00 19 00 ....

        IF  '${record}' != '${last_record}'
          # current Record ID in response data
          Should Be Equal  ${get_dev_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_dev_sdr[3]}  00

          # Next Record ID in Response data
          ${record_next}=  Evaluate  ${record} + 1
          ${record_next}=  Convert To Hex  ${record_next}  length=2  lowercase=yes
          Should Be Equal  ${get_dev_sdr[0]}  ${record_next}
          Should Be Equal  ${get_dev_sdr[1]}  00

        ELSE
          # Next Record ID in Response data
          Should Be Equal  ${get_dev_sdr[0]}  ff
          Should Be Equal  ${get_dev_sdr[1]}  ff

          # current Record ID in response data
          Should Be Equal  ${get_dev_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_dev_sdr[3]}  00

        END
        # Response Data Count - total records (max - FFh - 255 in decimal)
        ${response_data}=  Set Variable  ${get_dev_sdr[2:]}
        ${length}=  Get Length  ${response_data}
        Should Be True  0<${length}<=255
    END


Verify Get Device SDR For Invalid Data Request Via IPMI
    [Documentation]  Verify Get Device SDR via IPMI lanplus with extra bytes.
    [Tags]  Verify_Get_Device_SDR_For_Invalid_Data_Request_Via_IPMI

    # Get SDR command with extra bytes
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get'][3]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x00 0x00 ${IPMI_RAW_CMD['Device_SDR']['Get'][1]} 0x00
    # Proper error code should be returned
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get'][2]}


*** Keywords ***

Get IPMI Sensor Count
    [Documentation]  Get sensors count using "sdr elist all" command.
    # Example of "sdr elist all" command output:
    # BootProgress     | 03h | ok  | 34.2 |
    # OperatingSystemS | 05h | ok  | 35.1 |
    # AttemptsLeft     | 07h | ok  | 34.1 |
    # occ0             | 08h | ok  | 210.1 | Device Disabled
    # occ1             | 09h | ok  | 210.2 | Device Disabled
    # p0_core0_temp    | 11h | ns  |  3.1 | Disabled
    # cpu0_core0       | 12h | ok  | 208.1 | Presence detected
    # p0_core1_temp    | 14h | ns  |  3.2 | Disabled
    # cpu0_core1       | 15h | ok  | 208.2 | Presence detected
    # p0_core2_temp    | 17h | ns  |  3.3 | Disabled
    # ..
    # ..
    # ..
    # ..
    # ..
    # ..
    # fan3             | 00h | ns  | 29.4 | Logical FRU @35h
    # bmc              | 00h | ns  |  6.1 | Logical FRU @3Ch
    # ethernet         | 00h | ns  |  1.1 | Logical FRU @46h

    ${output}=  Run IPMI Standard Command  sdr elist all
    ${sensor_list}=  Split String  ${output}  \n
    ${sensor_count}=  Get Length  ${sensor_list}
    [Return]  ${sensor_count}


Get Device SDR Info For Sensor Data
    [Documentation]  Get Device SDR Info via KCS interface and return response data with Sensor count.

    # Get Device SDR Info for Sensor data
    ${sensor_data}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]}

    [Return]  ${sensor_data}


Get Device SDR Info For SDR Data
    [Documentation]  Get Device SDR Info via KCS interface and return response data with SDR count.

    # Get Device SDR Info for SDR data
    ${sdr_data}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]}

    [Return]  ${sdr_data}


Get Sensor Count From SDR Info
   [Documentation]  Get Sensor Count from Get Device SDR Info data.

    # Get Device SDR Info Via KCS Interface for Sensor count
    ${sensor_data}=  Get Device SDR Info For Sensor Data

    # Get Sensor count from Get Device SDR Info count - byte 0
    ${sensor_data}=  Split String  ${sensor_data}
    ${sensor_count}=  Set Variable  ${sensor_data[0]}
    ${sensor_count}=  Convert To Integer  ${sensor_count}  16

    [Return]  ${sensor_count}


Get SDR Count From SDR Info
   [Documentation]  Get SDR Count from Get Device SDR Info data.

    # Get Device SDR Info Via KCS Interface for SDR count
    ${sdr_data}=  Get Device SDR Info For SDR Data

    # Get SDR count from Get Device SDR Info count - byte 0
    ${sdr_data}=  Split String  ${sdr_data}
    ${sdr_count}=  Set Variable  ${sdr_data[0]}
    ${sdr_count}=  Convert To Integer  ${sdr_count}  16

    [Return]  ${sdr_count}


Get Device SDR Timestamp
    [Documentation]  Get Timestamp from Get Device SDR Info.

    # Get Device SDR Info Via KCS Interface for Sendor count
    ${sensor_data}=  Get Device SDR Info For Sensor Data
    # Get Device SDR Info Via KCS Interface for SDR count
    ${sdr_data}=  Get Device SDR Info For SDR Data

    # Split into list
    ${sensor_data}=  Split String  ${sensor_data}
    ${sdr_data}=  Split String  ${sdr_data}

    # Timestamp for the Get SDR count will be from Response byte 2 to N
    # Compare the timestamps for Sensor data and SDR data
    Should Be Equal  ${sensor_data[2:]}  ${sdr_data[2:]}

    # Convert Bytestamp to Epoch timestamp
    ${timestamp}=  Set Variable  ${sdr_data[2:]}
    Reverse List  ${timestamp}
    ${timestamp}=  Evaluate  "".join(${timestamp})
    # Prefixes 0s for expected bytes
    ${timestamp}=  Zfill Data  ${timestamp}  8
    ${timestamp}=  Convert To Integer  ${timestamp}  16

    [Return]  ${timestamp}


Get Count for Sensor And SDR Elist All
    [Documentation]  Get Sensor and SDR elist all count via IPMI lanplus.

    # Get Sensor list via IPMI lanplus
    ${sensor_count}=  Run IPMI Standard Command  sensor | wc -l
    # Get SDR elist all via IPMI lanplus
    ${sdr_count}=  Get IPMI Sensor Count

    [Return]  ${sensor_count}  ${sdr_count}


Get Reserve Device SDR Repository
    [Documentation]  Get Reserve Device SDR Repository via Inband IPMI.

    # Reserve Device SDR Repository command Via Inband
    ${resp}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]}

    [Return]  ${resp}


Get IPMI SDR Status Info
    [Documentation]  Returns status for given IPMI SDR Info.
    [Arguments]  ${setting}
    # Description of argument(s):
    # setting  SDR Info which needs to be read(e.g. "SDR Version").
    # SDR Version                         : 0x51
    # Record Count                        : 58
    # Free Space                          : 9312 bytes
    # Most recent Addition                : 03/10/2022 05:56:02
    # Most recent Erase                   : 02/07/2106 06:28:15
    # SDR overflow                        : yes
    # SDR Repository Update Support       : unspecified
    # Delete SDR supported                : no
    # Partial Add SDR supported           : no
    # Reserve SDR repository supported    : yes
    # SDR Repository Alloc info supported : yes

    # Get SDR Info IPMI command
    ${resp}=  Run IPMI Standard Command  sdr info

    # Return lines for given IPMI SDR Info
    ${setting_line}=  Get Lines Containing String  ${resp}  ${setting}
    ...  case-insensitive
    ${setting_status}=  Fetch From Right  ${setting_line}  :${SPACE}

    [Return]  ${setting_status}


Get Record Count And Last Record From SDR
    [Documentation]  Returns total record count from IPMI SDR Info and last SDR record.

    # Returns Record count from IPMI SDR Info
    ${record_count}=  Get IPMI SDR Status Info  Record Count

    # Identifies Last record ID
    # If Record Count = 58 (3Ah), Record IDs range from 0 to 57
    # Then Last Record ID will be 57 - 39h
    ${last_record}=  Evaluate  ${record_count} - 1

    [Return]  ${record_count}  ${last_record}
