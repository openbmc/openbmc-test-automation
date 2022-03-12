*** Settings ***
Documentation  Test IPMI sensor IDs.

Resource               ../lib/rest_client.robot
Resource               ../lib/ipmi_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/boot_utils.robot
Resource               ../lib/bmc_redfish_resource.robot
Library                ../lib/ipmi_utils.py
Variables              ../data/ipmi_raw_cmd_table.py

Suite setup             Suite Setup Execution
Suite Teardown          Redfish.Logout
Test Teardown           Test Teardown Execution

Force Tags              SDR_Test


*** Test Cases ***

Verify SDR Info
    [Documentation]  Verify sdr info command output.
    [Tags]  Verify_SDR_Info
    # Example of SDR info command output:
    # SDR Version                         : 0x51
    # Record Count                        : 216
    # Free Space                          : unspecified
    # Most recent Addition                :
    # Most recent Erase                   :
    # SDR overflow                        : no
    # SDR Repository Update Support       : unspecified
    # Delete SDR supported                : no
    # Partial Add SDR supported           : no
    # Reserve SDR repository supported    : no
    # SDR Repository Alloc info supported : no

    ${sdr_info}=  Get SDR Info
    Should Be Equal  ${sdr_info['sdr_version']}  0x51

    # Get sensor count from "sdr elist all" command output.
    ${sensor_count}=  Get Sensor Count
    Should Be Equal As Strings
    ...  ${sdr_info['record_count']}  ${sensor_count}

    Should Be Equal  ${sdr_info['free_space']}  unspecified
    Should Be Equal  ${sdr_info['most_recent_addition']}  ${EMPTY}
    Should Be Equal  ${sdr_info['most_recent_erase']}  ${EMPTY}
    Should Be Equal  ${sdr_info['sdr_overflow']}  no
    Should Be Equal  ${sdr_info['sdr_repository_update_support']}  unspecified
    Should Be Equal  ${sdr_info['delete_sdr_supported']}  no
    Should Be Equal  ${sdr_info['partial_add_sdr_supported']}  no
    Should Be Equal  ${sdr_info['reserve_sdr_repository_supported']}  no
    Should Be Equal  ${sdr_info['sdr_repository_alloc_info_supported']}  no


Test CPU Core SDR Info At Power On
    [Documentation]  Verify CPU core SDR info via IPMI and Redfish at power on.

    [Tags]  Test_CPU_Core_SDR_Info_At_Power_On

    Redfish Power On  stack_mode=skip  quiet=1
    Test SDR Info  core


Test DIMM SDR Info At Power On
    [Documentation]  Verify DIMM SDR info via IPMI and Redfish at power on.

    [Tags]  Test_DIMM_SDR_Info_At_Power_On

    Redfish Power On  stack_mode=skip  quiet=1
    Test SDR Info  dimm


Test GPU SDR Info At Power On
    [Documentation]  Verify GPU SDR info via IPMI and Redfish at power on.

    [Tags]  Test_GPU_SDR_Info_At_Power_On

    Redfish Power On  stack_mode=skip  quiet=1
    Test SDR Info  gv100card


Test CPU Core SDR Info At Power Off
    [Documentation]  Verify CPU core SDR info via IPMI and Redfish at power off.

    [Tags]  Test_CPU_Core_SDR_Info_At_Power_Off

    Redfish Hard Power Off  stack_mode=skip  quiet=1
    Test SDR Info  core


Test DIMM SDR Info At Power Off
    [Documentation]  Verify DIMM SDR info via IPMI and Redfish at power off.

    [Tags]  Test_DIMM_SDR_Info_At_Power_Off

    Redfish Hard Power Off  stack_mode=skip  quiet=1
    Test SDR Info  dimm


Test Turbo Allowed SDR Info
    [Documentation]  Verify turbo allowed SDR info via IPMI and Redfish.
    [Tags]  Test_Turbo_Allowed_SDR_Info

    ${component_uri_list}=  Get Component URIs  turbo_allowed
    ${component_uri}=  Get From List  ${component_uri_list}  0
    ${state_rest}=  Read Attribute  ${component_uri}  TurboAllowed

    ${state_ipmi}=  Get SDR Presence Via IPMI  turbo_allowed${SPACE}

    Run Keyword If  '${state_ipmi}' == 'Disabled'
    ...    Should Be True  ${state_rest} == ${0}
    ...  ELSE IF  '${state_ipmi}' == 'State Asserted'
    ...    Should Be True  ${state_rest} == ${1}


Test Auto Reboot SDR Info
    [Documentation]  Verify auto reboot SDR info via IPMI and Redfish.
    [Tags]  Test_Auto_Reboot_SDR_Info


    ${component_uri_list}=  Get Component URIs  auto_reboot
    ${component_uri}=  Get From List  ${component_uri_list}  0
    ${state_rest}=  Read Attribute  ${component_uri}  AutoReboot

    ${state_ipmi}=  Get SDR Presence Via IPMI  auto_reboot${SPACE}

    Run Keyword If  '${state_ipmi}' == 'Disabled'
    ...    Should Be True  ${state_rest} == ${0}
    ...  ELSE IF  '${state_ipmi}' == 'State Asserted'
    ...    Should Be True  ${state_rest} == ${1}


Test TPM Enable SDR Info
    [Documentation]  Verify auto reboot SDR info via IPMI and Redfish.
    [Tags]  Test_TPM_Enable_SDR_Info


    ${component_uri_list}=  Get Component URIs  TPMEnable
    ${component_uri}=  Get From List  ${component_uri_list}  0
    ${state_rest}=  Read Attribute  ${component_uri}  TPMEnable

    ${state_ipmi}=  Get SDR Presence Via IPMI  auto_reboot${SPACE}

    Run Keyword If  '${state_ipmi}' == 'Disabled'
    ...    Should Be True  ${state_rest} == ${0}
    ...  ELSE IF  '${state_ipmi}' == 'State Asserted'
    ...    Should Be True  ${state_rest} == ${1}


Verify Get SDR For Maximum Record Via IPMI
    [Documentation]  Verify Get SDR for each and every record one by one via IPMI lanplus.
    [Tags]  Verify_Get_SDR_For_Maximum_Record_Via_IPMI

    # Gets the total record count from SDR Info and the last record entry number.
    ${record_count}  ${last_record}=  Get Record Count From SDR Info

    # Validate each and every record till the last record.
    FOR  ${record}  IN RANGE  0  ${record_count}
        # Convert number to hexadecimal record id.
        ${recordhex}=  Convert To Hex  ${record}  length=2  lowercase=yes

        # Get SDR command.
        ${resp}=  Run IPMI Standard Command
        ...  raw ${IPMI_RAW_CMD['Get SDR']['Get'][0]} 0x00 0x00 0x${recordhex} 0x00 0x00 0xff
        ${get_sdr}=  Split String  ${resp}

        # If the record id reaches the last data available, the next record will be ff ff,
        # Eg, If total record available is 115, Record IDs : 0 - 114,
        # Then when record id reaches last record (i.e 114 - 72h),
        # Get SDR response bytes 0:2 will be - ff ff 72 00 ....
        # If not then (say 25 - 19h ), 1a 00 19 00 ....

        IF  '${record}' != '${last_record}'
          # current record ID in response data.
          Should Be Equal  ${get_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_sdr[3]}  00

          # next record ID in response data.
          ${record_next}=  Evaluate  ${record} + 1
          ${record_next}=  Convert To Hex  ${record_next}  length=2  lowercase=yes
          Should Be Equal  ${get_sdr[0]}  ${record_next}
          Should Be Equal  ${get_sdr[1]}  00
        ELSE
          # next record ID in response data.
          Should Be Equal  ${get_sdr[0]}  ff
          Should Be Equal  ${get_sdr[1]}  ff

          # current record ID in response data.
          Should Be Equal  ${get_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_sdr[3]}  00

        # response data count - total records (max - FFh - 255 in decimal).
        ${response_data}=  Set Variable  ${get_sdr[2:]}
        ${length}=  Get Length  ${response_data}
        Should Be True  0<${length}<=255
    END


Verify Sensor And SDR Count In Get Device SDR Info Via Inband IPMI
    [Documentation]  Verify sensor and sdr count in Get Device SDR Info via Inband.
    [Tags]  Verify_Sensor_And_SDR_Count_In_Get_Device_SDR_Info_Via_Inband_IPMI

    # Get Sensor count and sdr elist all count from IPMI lanplus interface.
    ${sensor_count_lan1}  ${sdr_count_lan1}=  Get Sensor And SDR Elist All Count

    # Get sensor count from Get Device SDR Info command.
    ${sensor_count1}=  Get Device SDR Details For Sensor Count
    # Compare Get Device SDR Sensor count with Sensor count from lanplus interface.
    Should Be Equal As Integers   ${sensor_count1}  ${sensor_count_lan1}

    # Get sdr count from Get Device SDR Info command.
    ${sdr_count1}=  Get Device SDR Details For SDR Count
    # Compare Get Device SDR's sdr count with sdr elist all count from lanplus interface.
    Should Be Equal As Integers  ${sdr_count1}  ${sdr_count_lan1}

    # reboot host using ipmi chassis power cycle.
    IPMI Power Cycle

    # Get sensor count and sdr elist all count from IPMI lanplus interface.
    ${sensor_count_lan2}  ${sdr_count_lan2}=  Get Sensor And SDR Elist All Count

    # Get sensor count from Get Device SDR Info command.
    ${sensor_count2}=  Get Device SDR Details For Sensor Count
    # Compare Get Device SDR's sensor count with sensor count from lanplus interface.
    Should Be Equal As Integers   ${sensor_count2}  ${sensor_count_lan2}

    # Get sdr count from Get Device SDR Info command.
    ${sdr_count2}=  Get Device SDR Details For SDR Count
    # Compare Get Device SDR's sdr count with sdr elist all count from lanplus interface.
    Should Be Equal As Integers  ${sdr_count2}  ${sdr_count_lan2}


Verify Timestamp In Get Device SDR Info Via Inband IPMI
    [Documentation]  Verify timestamp in Get Device SDR Info Via Inband.
    [Tags]  Verify_Timestamp_In_Get_Device_SDR_Info_Via_Inband_IPMI

    # reboot host using IPMI chassis power cycle.
    IPMI Power Cycle

    # Get epoch timestamp obtained from Get Device SDR Info command.
    ${sdr_timestamp}=  Get Device SDR Timestamp

    # Get current date from BMC native Date command and convert to epoch.
    ${bmc_date}=  Get Current Date from BMC
    ${epoch_bmc}=  Convert Date  ${bmc_date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    # Compare time difference between bmc time and Get Device SDR Info timestamp.
    # The maximum time difference should be less then a minute - 60 seconds
    ${difference}=  Evaluate  int(${epoch_bmc}) - int(${sdr_timestamp})
    Should Be True  ${difference}<=60


Verify Get Device SDR Info For Invalid Data Request
    [Documentation]  Verify Get Device SDR Info via Inband with extra bytes.
    [Tags]  Verify_Get_Device_SDR_Info_For_Invalid_Data_Request

    # sensor count via Device SDR Info with extra bytes.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][3]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]} 0x00
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][2]}

    # sdr count via Device SDR Info with extra bytes.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][3]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]} 0x00
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][2]}


Verify Device SDR Info Via IPMI Lanplus
    [Documentation]  Verify whether Get Device SDR Info command is accessible Via lanplus interface.
    [Tags]  Verify_Device_SDR_Info_Via_IPMI_Lanplus

    # sensor count via Device SDR Info via lanplus.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]}
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][4]}

    # sdr count via Device SDR Info via lanplus.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get_Info'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]}
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][4]}


Verify Reserve Device SDR Repository Via Inband IPMI
    [Documentation]  Verify Reserve Device SDR Repository via inband.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Via_Inband_IPMI

    # Reserve Device SDR Repository via inband.
    ${resp}=  Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    # Identify the byte count.
    ${length}=  Get Length  ${reserve_id}
    Should Be Equal As Integers  ${length}  2


Verify Reserve Device SDR Repository For Invalid Data Request
    [Documentation]  Verify Reserve Device SDR Repository via inband with extra request bytes.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Invalid_Data_Request

    # Reserve Device SDR Repository with extra request bytes.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][2]}*
    ...  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]} 0x00
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][1]}


Verify Reserve Device SDR Repository Info Via IPMI Lanplus
    [Documentation]  Verify whether Reserve Device SDR Repository command is accessible via lanplus.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Via_IPMI_Lanplus

    # Reserve Device SDR Repository via lanplus.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][4]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]}
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][3]}


Verify Reserve Device SDR Repository For Partial Record
    [Documentation]  Verify whether reservation id of Reserve Device SDR Repository is accessible for fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Partial_Record

    # Generates Reserve ID.
    ${resp}=  Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    # Get Device SDR command with generated reserve id.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f
    ${reserve_id}=  Split String  ${resp}
    ${resp}=  Set Variable  ${resp[2:]}
    ${length}=  Get Length  ${resp}
    # since only 0f offset given, the length should be 15. 
    Should Be Equal As Integers  ${length}  15
 

Verify Reserve Device SDR Repository For Partial Record After BMC Reboot
    [Documentation]  Verify whether reservation id of Reserve Device SDR Repository is accessible after bmc reboot for fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_For_Partial_Record_After_BMC_Reboot

    # Generates Reserve ID.
    ${resp}=  Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    # Get Device SDR command with generated reserve id.
    ${resp1}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f

    # Reboot bmc via cold reset.
    Run IPMI Standard Command  raw ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational

    # Get Device SDR command with reserve id generated before bmc reboot.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f


Verify Reserve Device SDR Repository Invalid Reservation ID For Partial Record
    [Documentation]  Verify whether invalid reservation id of Reserve Device SDR Repository is accessible for fetch partial record from Get Device SDR.
    [Tags]  Verify_Reserve_Device_SDR_Repository_Invalid_Reservation_ID_For_Partial_Record

    # Generates Reserve ID 1.
    ${resp}=  Reserve Device SDR Repository
    ${reserve_id}=  Split String  ${resp}

    # Generates Reserve ID 2.
    ${resp2}=  Reserve Device SDR Repository

    #  Get Device SDR command with reserve id 1.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][5]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x${reserve_id[0]} 0x${reserve_id[1]} 0x00 0x00 0x00 0x0f


Verify Get Device SDR For Maximum Record Via IPMI
    [Documentation]  Verify Get Device SDR for each and every Record via IPMI Lanplus.
    [Tags]  Verify_Get_Device_SDR_For_Maximum_Record_Via_IPMI

    # Gets the Total Record Count from SDR Info and the last Record entry number.
    ${record_count}  ${last_record}=  Get Record Count From SDR Info

    # Validate each and every record till the last record.
    FOR  ${record}  IN RANGE  0  ${record_count}
        # Convert number to hexadecimal record id.
        ${recordhex}=  Convert To Hex  ${record}  length=2  lowercase=yes

        # Get SDR command.
        ${resp}=  Run IPMI Standard Command
        ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x00 0x00 0x${recordhex} 0x00 0x00 0xff
        ${get_dev_sdr}=  Split String  ${resp}

        # If the record id reaches the last data available, the next record will be ff ff
        # Eg, If total record available is 115, Record IDs : 0 - 114
        # Then when record id reaches last record (i.e 114 - 72h),
        # Get SDR response bytes 0:2 will be - ff ff 72 00 ....
        # If not then (say 25 - 19h ), 1a 00 19 00 ....

        IF  '${record}' != '${last_record}'
          # current Record ID in response data.
          Should Be Equal  ${get_dev_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_dev_sdr[3]}  00

          # Next Record ID in Response data.
          ${record_next}=  Evaluate  ${record} + 1
          ${record_next}=  Convert To Hex  ${record_next}  length=2  lowercase=yes
          Should Be Equal  ${get_dev_sdr[0]}  ${record_next}
          Should Be Equal  ${get_dev_sdr[1]}  00

        ELSE
          # Next Record ID in Response data.
          Should Be Equal  ${get_dev_sdr[0]}  ff
          Should Be Equal  ${get_dev_sdr[1]}  ff

          # current Record ID in response data.
          Should Be Equal  ${get_dev_sdr[2]}  ${recordhex}
          Should Be Equal  ${get_dev_sdr[3]}  00

        # Response Data Count - total records (max - FFh - 255 in decimal).
        ${response_data}=  Set Variable  ${get_dev_sdr[2:]}
        ${length}=  Get Length  ${response_data}
        Should Be True  0<${length}<=255
    END


Verify Get Device SDR For Invalid Data Request Via IPMI
    [Documentation]  Verify Get Device SDR via IPMI Lanplus with extra bytes.
    [Tags]  Verify_Get_Device_SDR_For_Invalid_Data_Request_Via_IPMI

    # Get SDR command with extra bytes.
    ${resp}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['Device_SDR']['Get'][3]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get'][0]} 0x00 0x00 ${IPMI_RAW_CMD['Device_SDR']['Get'][1]} 0x00
    # Proper error code should be returned.
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Device_SDR']['Get'][2]}


*** Keywords ***

Get Sensor Count
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


Get Component URIs
    [Documentation]  Get URIs for given component from given URIs
    ...  and return as a list.
    [Arguments]  ${component_name}  ${uri_list}=${SYSTEM_URI}

    # A sample result returned for the "core" component:
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core0
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core1
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core10
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core11
    # /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0/core12
    # (etc.)

    # Description of argument(s):
    # component_name    Component name (e.g. "core", "dimm", etc.).
    # uri_list          URI list.

    ${component_uris}=  Get Matches  ${uri_list}
    ...  regexp=^.*[0-9a-z_].${component_name}\[_0-9a-z]*$
    ...  case_insensitive=${True}
    [Return]  ${component_uris}


Get SDR Presence Via IPMI
    [Documentation]  Return presence info from IPMI sensor data record.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu0_core0", "dimm0", etc.).

    # Example of IPMI SDR elist output.
    # BootProgress     | 03h | ok  | 34.2 |
    # OperatingSystemS | 05h | ok  | 35.1 | boot completed - device not specified
    # AttemptsLeft     | 07h | ok  | 34.1 |
    # occ0             | 08h | ok  | 210.1 | Device Disabled
    # occ1             | 09h | ok  | 210.2 | Device Disabled
    # cpu0_core0       | 12h | ok  | 208.1 | Presence detected
    # cpu0_core1       | 15h | ok  | 208.2 | Disabled
    # cpu0_core2       | 18h | ok  | 208.3 | Presence detected
    # dimm0            | A6h | ok  | 32.1 | Presence Detected
    # dimm1            | A8h | ok  | 32.2 | Presence Detected
    # dimm2            | AAh | ok  | 32.9 | Presence Detected
    # gv100card0       | C5h | ok  | 216.1 | 0 unspecified
    # gv100card1       | C8h | ok  | 216.2 | 0 unspecified
    # TPMEnable        | D7h | ok  |  3.3 | State Asserted
    # auto_reboot      | DAh | ok  | 33.2 | State Asserted
    # volatile         | DBh | ok  | 33.1 | State Deasserted

    ${sdr_elist_output}=  Run IPMI Standard Command  sdr elist
    ${sdr_component_line}=
    ...  Get Lines Containing String  ${sdr_elist_output}  ${component_name}
    ...  case-insensitive

    ${presence_ipmi}=  Fetch From Right  ${sdr_component_line}  |
    ${presence_ipmi}=  Strip String  ${presence_ipmi}
    [Return]  ${presence_ipmi}


Verify SDR
    [Documentation]  Verify IPMI sensor data record for given component
    ...  with Redfish.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "cpu0/core0", "dimm0", etc.).

    ${presence_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component_name}
    ...  Present
    ${functional_rest}=  Read Attribute
    ...  ${HOST_INVENTORY_URI}system/chassis/motherboard/${component_name}
    ...  Functional

    # Replace "/" with "_" if there is any "/" in component name.
    # e.g. cpu0/core0 to cpu0_core0
    ${component_name}=  Replace String  ${component_name}  /  _
    ${presence_ipmi}=  Get SDR Presence Via IPMI  ${component_name}${SPACE}

    Run Keyword If  '${presence_ipmi}' == 'Disabled' or '${presence_ipmi}' == ''
    ...    Should Be True  ${presence_rest} == ${0} and ${functional_rest} == ${0}
    ...  ELSE IF  '${presence_ipmi}' == 'Presence Detected' or '${presence_ipmi}' == 'Presence detected'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${1}
    ...  ELSE IF  '${presence_ipmi}' == 'State Asserted'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${1}
    ...  ELSE IF  '${presence_ipmi}' == 'State Deasserted'
    ...    Should Be True  ${presence_rest} == ${1} and ${functional_rest} == ${0}
    ...  ELSE  Fail  msg=Invalid Presence${presence_ipmi}


Test SDR Info
    [Documentation]  Test SDR info for given component.
    [Arguments]  ${component_name}

    # Description of argument(s):
    # component_name    Component name (e.g. "core", "dimm", etc.).

    ${component_uri_list}=  Get Component URIs  ${component_name}

    FOR  ${uri}  IN  @{component_uri_list}
      ${component_name}=  Fetch From Right  ${uri}  motherboard/
      Log To Console  ${component_name}
      Verify SDR  ${component_name}
    END


Get Device SDR Info For Sensor Data
    [Documentation]  Get Device SDR Info Via KCS Interface and return response data with Sensor count.

    # Get Device SDR Info for sensor data.
    ${sensor_data}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][0]}

    [Return]  ${sensor_data}


Get Device SDR Info For SDR Data
    [Documentation]  Get Device SDR Info via inband and return response data with SDR count.

    # Get Device SDR Info for sdr data.
    ${sdr_data}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Get_Info'][1]}

    [Return]  ${sdr_data}


Get Device SDR Details For Sensor Count
   [Documentation]  Get sensor count from Get Device SDR Info data.

    # Get Device SDR Info via Inband for sensor count.
    ${sensor_data}=  Get Device SDR Info For Sensor Data

    # Get sensor count from Get Device SDR Info count - byte 0.
    ${sensor_data}=  Split String  ${sensor_data}
    ${sensor_count}=  Set Variable  ${sensor_data[0]}
    ${sensor_count}=  Convert To Integer  ${sensor_count}  16

    [Return]  ${sensor_count}


Get Device SDR Details For SDR Count
   [Documentation]  Get SDR count from Get Device SDR Info data.

    # Get Device SDR Info via inband for SDR count.
    ${sdr_data}=  Get Device SDR Info For SDR Data

    # Get SDR count from Get Device SDR Info count - byte 0.
    ${sdr_data}=  Split String  ${sdr_data}
    ${sdr_count}=  Set Variable  ${sdr_data[0]}
    ${sdr_count}=  Convert To Integer  ${sdr_count}  16

    [Return]  ${sdr_count}


Get Device SDR Timestamp
    [Documentation]  Get timestamp from Get Device SDR Info.

    # Get Device SDR Info via inband for sensor count.
    ${sensor_data}=  Get Device SDR Info For Sensor Data
    # Get Device SDR Info via inband for SDR count.
    ${sdr_data}=  Get Device SDR Info For SDR Data

    # Split into list.
    ${sensor_data}=  Split String  ${sensor_data}
    ${sdr_data}=  Split String  ${sdr_data}

    # Timestamp for the Get SDR count will be from response byte 2 to N.
    # Compare the timestamps for Sensor data and SDR data.
    Should Be Equal  ${sensor_data[2:]}  ${sdr_data[2:]}

    # Convert bytestamp to epoch timestamp.
    ${timestamp}=  Set Variable  ${sdr_data[2:]}
    Reverse List  ${timestamp}
    ${timestamp}=  Evaluate  "".join(${timestamp})
    # Prefixes 0s for expected bytes.
    ${timestamp}=  Zfill Data  ${timestamp}  8
    ${timestamp}=  Convert To Integer  ${timestamp}  16

    [Return]  ${timestamp}


Get Sensor And SDR Elist All Count
    [Documentation]  Get Sensor and SDR elist all count via IPMI lanplus.

    # Get sensor list via IPMI lanplus.
    ${sensor_count}=  Run IPMI Standard Command  sensor | wc -l
    # Get sdr elist all Via IPMI lanplus.
    ${sdr_count}=  Get Sensor Count

    [Return]  ${sensor_count}  ${sdr_count}


Reserve Device SDR Repository
    [Documentation]  Get Reserve Device SDR Repository Via Inband.

    # Reserve Device SDR Repository command via inband.
    ${resp}=  Run Inband IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Device_SDR']['Reserve_Repository'][0]}

    [Return]  ${resp}


Get IPMI SDR Info
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

    # Get SDR Info IPMI command.
    ${resp}=  Run IPMI Standard Command  sdr info

    # Return lines for given IPMI SDR Info.
    ${setting_line}=  Get Lines Containing String  ${resp}  ${setting}
    ...  case-insensitive
    ${setting_status}=  Fetch From Right  ${setting_line}  :${SPACE}

    [Return]  ${setting_status}


Get Record Count From SDR Info
    [Documentation]  Returns total record count from IPMI SDR Info and last SDR record.

    # Returns record count from IPMI SDR Info.
    ${record_count}=  Get IPMI SDR Info  Record Count

    # Identifies last record ID.
    # If Record Count = 58 (3Ah), Record IDs range from 0 to 57,
    # Then last record ID will be 57 - 39h.
    ${last_record}=  Evaluate  ${record_count} - 1

    [Return]  ${record_count}  ${last_record}


Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1

    # If REST is supported, then the uri_list will be returned.
    ${resp}=  OpenBMC Get Request  ${OPENBMC_BASE_URI}
    IF  '${resp.status_code}' == '${HTTP_OK}'
      ${uri_list}=  Read Properties  ${OPENBMC_BASE_URI}list
      Set Suite Variable  ${SYSTEM_URI}  ${uri_list}
      Log  ${uri_list}
    END


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
