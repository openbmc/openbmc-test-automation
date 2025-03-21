*** Settings ***

Documentation    Module to test IPMI SEL Time functionality.
...              Pre-requisite Condition : Client Machine and BMC should be in
...              Same TimeZone (example : UST)
...
...              IPMI Raw command variables are defined under
...              ../data/ipmi_raw_command_table.py
...
...              Test the Set/Get SEL Time functionality and compare the result against
...              BMC Native command (date).
...
...              Set the Time Sync Mode from NTP to Manual to Set SEL Time.
...              Time Sync Mode change performed via REDFISH URI.
...              Performs the change in Time Sync Mode with Test Setup and Teardown Execution
...              with default NETWORK_TIMEOUT provided under ../lib/resource.robot.
...
...              NETWORK_RESTART_TIME added for Set SEL Time and Add SEL Entry as the corresponding
...              command takes approx 5 seconds for the operation to reflect.
...
...              Current SEL time identified via BMC Native command (date) and perform SEL Time operations.
...
...              Script Verifies SEL Time for various scenarios such as,
...              Get current time from BMC and add future year and compare against BMC native command (date),
...              Gets BMC Current Time and Adds 15 minutes and compare against BMC native command (date),
...              Gets BMC Current Time and subtracts 1 day and compare against BMC native command (date),
...              Add SEL Entry for all the above scenarios and compare against BMC native command (date).

Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Library          DateTime
Library          Collections
Library          String
Library          ../lib/ipmi_utils.py
Variables        ../data/ipmi_raw_cmd_table.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution

Test Tags       IPMI_SEL_Time

*** Variables ***

${NETWORK_RESTART_TIME}   5s
@{time_difference_list}  +8760:153:25  -87600:453:120  +175200:40:15  -43800:10:05  +20:35:12  -8760:00:00

# Based on 13th byte of add SEL entry command as per IPMI spec
# event_dir and event_type variable value needs to be given.
${sel_no_entry_msg}  SEL has no entries
${event_type}        Lower Non-critical going low
${event_dir}         Asserted
# number_of_times_sel_entry_added this variable is used in Verify Multiple Set SEL Time With Multiple Add SEL Entry
# test case. Need to give how many sel should be added with multiple date and time.
${number_of_times_sel_entry_added}    6

*** Test Cases ***

Verify Default Get SEL Time
    [Documentation]  Verify IPMI Get SEL Time.
    [Tags]  Verify_Default_Get_SEL_Time

    # Gets the current SEL time via Get SEL Time Command.
    ${resp}=  Get SEL Time Command
    Should Not Be Empty  ${resp}


Verify Set SEL Time On NTP Mode
    [Documentation]   IPMI Set SEL Time without NTP
    [Tags]  Verify_Set_SEL_Time_On_NTP_Mode

    # Get current time from BMC and add future year (here, 5years).
    ${sel_date}=  Get Specific Sel Date  5

    # Gives Hexa decimal raw command data request with the prefix of 0x.
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    ${Set_sel_time}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][2]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Should Contain  ${Set_sel_time}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][1]}


Verify SEL Set Time For Specific Time
    [Documentation]  Verify IPMI Set SEL Time.
    [Tags]  Verify_SEL_Set_Time_For_Specific_Time

    # Get current time from BMC and add future year (here, 5years).
    ${sel_date}=  Get Specific Sel Date  5

    # Gives Hexa decimal raw command data request with the prefix of 0x.
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    # Set SEL Entry command.
    Set SEL Time Entry Via Raw Command  ${sel_date_raw}

    # Get SEL Time command.
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Identify Time difference and find the difference is less than 6 seconds.
    # Command execution may happen at the end of millisecond so considered 6 seconds as difference.
    ${time_difference}=  Get Time Difference  ${get_sel_time}  ${sel_date}
    Should Be True  0<=${time_difference}<=5
    ...  msg=Set SEL Time Not Working

    # Get BMC time (native) and compare with set sel time given.
    ${bmc_time}=  Get Current Date from BMC

    ${difference}=  Get Time Difference  ${bmc_time}  ${sel_date}
    Should Be True  0<=${difference}<=6


Verify Set SEL Time With Future Date And Time
    [Documentation]  Verify IPMI Get SEL Time by adding 15 minutes from current time.
    [Tags]  Verify_Set_SEL_Time_With_Future_Date_And_Time

    # Gets BMC Current Time and Adds 15 minutes and sets the SEL Time.
    ${sel_time}  ${set_sel_time}=  Identify SEL Time  +06:15:00

    # Set SEL Time via IPMI command.
    Set SEL Time Via IPMI  ${sel_time}

    # Get SEL Time Command.
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Difference of time between set sel time and get time.
    ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
    Should Be True  0<=${difference}<=2

    # Difference of time between BMC Date and Get SEL Time.
    ${bmc_time}=  Get Current Date from BMC
    ${difference}=  Get Time Difference  ${bmc_time}  ${get_sel_time}
    Should Be True  0<=${difference}<=2


Verify Set SEL Time With Past Date And Time
    [Documentation]  Verify IPMI Get SEL Time for yime delay of 1 day from current dat and time.
    [Tags]  Verify_Set_SEL_Time_With_Past_Date_And_Time

    # Gets BMC current time and subtracts 1 day and sets the SEL Time.
    ${sel_time}  ${set_sel_time}=  Identify SEL Time  -24:00:00

    ${status}=  Run Keyword And Return Status  Should Not Contain  ${sel_time}  1969
    ...  msg=Date cannot be less than 1970.

    IF  '${status}' == '${TRUE}'
        # Set SEL Time via IPMI command.
        Set SEL Time Via IPMI  ${sel_time}
        # Get SEL Time Command.
        ${get_sel_time}=  Check Current Date Time Via IPMI
        # Difference of time between set sel time and get time.
        ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
        Should Be True  0<=${difference}<=2
        # Difference of time between BMC Date and Get SEL Time.
        ${bmc_time}=  Get Current Date from BMC
        ${difference}=  Get Time Difference  ${bmc_time}  ${get_sel_time}
        Should Be True  0<=${difference}<=2
    ELSE
        FAIL  SEL Time cannot set Date less than 1970
    END


Verify SEL Set Time For Invalid Data Request
    [Documentation]  Verify IPMI Get SEL Time for invalid data request
    [Tags]  Verify_SEL_Set_Time_For_Invalid_Data_Request

    # Gets BMC current date via date command.
    ${current_date}=  Get Current Date from BMC

    # Gives hexa decimal Raw command data request with the prefix of 0x.
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${current_date}

    # Set Invalid SEL Time with one extra request byte.
    ${Set_seltime_invalid}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][4]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw} 0x00
    Should Contain  ${Set_seltime_invalid}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][3]}


Verify SEL Set Time For Incomplete Data Request
    [Documentation]  Verify IPMI Get SEL Time for invalid data with one byte less request data.
    [Tags]  Verify_SEL_Set_Time_For_Incomplete_Data_Request

    # Gets BMC current date via date command.
    ${current_date}=  Get Current Date from BMC

    # Gives hexa decimal raw command data request with the prefix of 0x.
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${current_date}

    # For data request less than expected byes, remove last byte.
    ${sel_date_raw}=  Split String  ${sel_date_raw}
    Remove From List  ${sel_date_raw}  -1
    ${sel_date_raw}=  Evaluate  " ".join(${sel_date_raw})

    # Set incomplete SEL Time with one less request byte.
    ${Set_seltime_incomplete}=
    ...  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][4]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Should Contain  ${Set_seltime_incomplete}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][3]}


Verify SEL Time In SEL Entry
    [Documentation]  Verify Configured SEL Time reflects in newly added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry

    Clear The SEL

   # change to manual, get current time and add future year (here, 5years).
    ${sel_date}=  Get Specific Sel Date  5

    # Gives hexa decimal raw command data request with the prefix of 0x.
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    # Set SEL Entry Command.
    Set SEL Time Entry Via Raw Command  ${sel_date_raw}

    # Get SEL Time Command.
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Identify Time difference and find the difference is less than 6 seconds.
    # Command execution may happen at the end of millisecond so considered 6 seconds as difference.
    ${time_difference}=  Get Time Difference  ${get_sel_time}  ${sel_date}
    Should Be True  0<=${time_difference}<=5
    ...  msg=Set SEL Time Not Working

    # Get BMC time (native) and compare with set sel time given.
    ${bmc_time}=  Get Current Date from BMC

    ${difference}=  Get Time Difference  ${bmc_time}  ${sel_date}
    Should Be True  0<=${difference}<=6

    # Get any Sensor available from Sensor list.
    ${sensor_name}=  Fetch One Threshold Sensor From Sensor List

    # Get Sensor ID from SDR Get "sensor".
    ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
    ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

    # Get Sensor Type from SDR Get "sensor".
    ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
    ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

    # Add SEL Entry.
    ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

    # Finds the last added sel entry.
    ${resp}=  Verify SEL Added  ${sensor_name}

    # Fetches the date of the last added SEL Entry.
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

    # Identify and find the time difference is less than 60 seconds.
    # Finding the sensor details and execution may take up to a minute.
    # Compare  date and time of Set SEL with sel entry.
    ${d}=  Get Time Difference  ${sel_entry_date}  ${sel_date}
    Should Be True  0<=${d}<=60


Verify SEL Time In SEL Entry For Future Date and Time
    [Documentation]  Verify configured SEL Time (Future Date & Time) in added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry_For_Future_Date_and_Time

    Clear The SEL

    # Gets BMC Current Time and Adds 15 minutes and sets the SEL Time.
    ${sel_time}  ${set_sel_time}=  Identify SEL Time  +06:15:00

    # Set SEL Time via IPMI command.
    Set SEL Time Via IPMI  ${sel_time}

    # Get SEL Time Command.
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Difference of time between set sel time and get time.
    ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
    Should Be True  0<=${difference}<=2

    # Difference of time between BMC Date and Get SEL Time.
    ${bmc_time}=  Get Current Date from BMC
    ${difference}=  Get Time Difference  ${bmc_time}  ${get_sel_time}
    Should Be True  0<=${difference}<=2

    # Get any Sensor available from Sensor list.
    ${sensor_name}=  Fetch One Threshold Sensor From Sensor List

    # Get Sensor ID from SDR Get "sensor".
    ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
    ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

    # Get Sensor Type from SDR Get "sensor".
    ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
    ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

    # Add SEL Entry.
    ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

    # Finds the last added sel entry.
    ${resp}=  Verify SEL Added  ${sensor_name}

    # Fetches the date of the last added SEL Entry.
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

    # Identify and find the time difference is less than 60 seconds.
    # Finding the sensor details and execution may take up to a minute.
    # Compare  date and time of Set SEL with sel entry.
    ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
    Should Be True  0<=${d}<=60


Verify SEL Time In SEL Entry For Past Date And Time
    [Documentation]  Verify configured SEL Time (Past Date & Time) in added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry_For_Past_Date_And_Time

    Clear The SEL

    # Gets BMC Current Time and subtracts 1 day and sets the SEL Time.
    ${sel_time}  ${set_sel_time}=  Identify SEL Time  -24:00:00

    ${status}=  Run Keyword And Return Status  Should Not Contain  ${sel_time}  1969
    ...  msg=Date cannot be less than 1970

    IF  '${status}' == '${TRUE}'
        # Set SEL Time via IPMI command.
        Set SEL Time Via IPMI  ${sel_time}
        # Get SEL Time Command.
        ${get_sel_time}=  Check Current Date Time Via IPMI
        # Difference of time between set sel time and get time.
        ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
        Should Be True  0<=${difference}<=2
        # Difference of time between BMC Date and Get SEL Time.
        ${bmc_time}=  Get Current Date from BMC
        ${difference}=  Get Time Difference  ${bmc_time}  ${get_sel_time}
        Should Be True  0<=${difference}<=2

        # Get any Sensor available from Sensor list.
        ${sensor_name}=  Fetch One Threshold Sensor From Sensor List
        # Get Sensor ID from SDR Get "sensor".
        ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
        ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

        # Get Sensor Type from SDR Get "sensor".
        ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
        ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

        # Add SEL Entry.
        ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

        # Finds the last added sel entry.
        ${resp}=  Verify SEL Added  ${sensor_name}

        # Fetches the date of the last added SEL Entry.
        ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

        # Identify and find the time difference is less than 60 seconds.
        # Finding the sensor details and execution may take up to a minute.
        # Compare  date and time of Set SEL with sel entry.
        ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
        Should Be True  0<=${d}<=60
    ELSE
        FAIL  SEL Time cannot set Date less than 1970.
    END


Verify Multiple Set SEL Time With Multiple Add SEL Entry
    [Documentation]  Verify SEL time in multiple addition Of SEL entry.
    [Tags]  Verify_Multiple_Set_SEL_Time_With_Multiple_Add_SEL_Entry

    FOR  ${i}  IN RANGE  ${number_of_times_sel_entry_added}

      ${sel_time}  ${set_sel_time}=  Identify SEL Time  ${time_difference_list[${i}]}

      # Set SEL Time via IPMI command.
      Set SEL Time Via IPMI  ${sel_time}

      # Clear the SEL.
      Clear The SEL

      # Get any Sensor available from Sensor list.
      ${sensor_name}=  Fetch One Threshold Sensor From Sensor List

      # Get Sensor ID from SDR Get "sensor" and Identify Sensor ID.
      ${sensor_data1}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor ID
      ${sensor_number}=  Get Bytes From SDR Sensor  ${sensor_data1}

      # Get Sensor Type from SDR Get "sensor" and identify Sensor Type.
      ${sensor_data2}=  Fetch Sensor Details From SDR  ${sensor_name}  Sensor Type (Threshold)
      ${sensor_type_id}=  Get Bytes From SDR Sensor  ${sensor_data2}

      # Add SEL Entry.
      ${sel_create_resp}=  Create SEL  ${sensor_type_id}  ${sensor_number}

      # Finds the last added sel entry.
      ${resp}=  Verify SEL Added  ${sensor_name}

      # Fetches the date of the last added SEL Entry.
      ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

      # Identify and find the time difference is less than 60 seconds.
      # Finding the sensor details and execution may take up to a minute.
      # Compare  date and time of Set SEL with sel entry.
      ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
      Should Be True  ${d}<=60

    END


*** Keywords ***

Time Sync Mode Change Through Redfish
    [Documentation]  Export IP, token and change the time sync to manual.
    [Arguments]   ${value}

    # Description of argument(s):
    # ${value}    Can be either ${FALSE} or ${TRUE}.

    # May be changed to WebView.

    # Changing Time Sync Mode to Manual.
    Change Time Sync Mode Via Redfish  ${value}


Change Time Sync Mode Via Redfish
    [Documentation]  To change the time sync mode via Redfish.
    [Arguments]   ${value}

    # Description of argument(s):
    # ${value}    Can be either ${FALSE} or ${TRUE}

    # Creates request body for Redfish url.
    ${mode}=  Create Dictionary  ProtocolEnabled=${value}
    ${data}=  Create Dictionary  NTP=${mode}

    # Patches the obtained body to the given url.
    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...   valid_status_codes=[${HTTP_NO_CONTENT}]

    Sleep  ${NETWORK_RESTART_TIME}


Get SEL Time Command
    [Documentation]  Get SEL Time command.

    # The response will be 8 byte timestamp in hexadecimal.
    # example: If current date and time is "Wed May  4 18:55:00 UTC 2022",
    # then, ${get_sel_time} will be "07 cc 72 62".
    ${get_sel_time}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Time'][0]}

    RETURN    ${get_sel_time}


Set SEL Time Entry Via Raw Command
    [Documentation]  Set SEL Time command.
    [Arguments]  ${sel_date_raw}

    # Description of argument(s):
    # ${sel_date_raw}     Time to set in hexadecimal bytes.
    # Example:
    #    If date is 1st January 2022 12:30:00 PM,
    #    the hexadecimal timestamp is, 61D04948.
    #    then the request bytes are,
    #    ${sel_date_raw}     0x48 0x49 0xd0 0x61

    Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Sleep  ${NETWORK_RESTART_TIME}


Clear The SEL
    [Documentation]  Clear SEL Command.

    # Clear the SEL.
    ${out}=  Run IPMI Standard Command  sel clear
    Should Contain  ${out}  Clearing SEL
    Sleep  2s


Verify SEL Added
    [Documentation]  Verify Added SEL.
    [Arguments]  ${sensor_name}

    # Description of argument(s):
    # sensor_name         Name of the sensor.

    ${resp}=  Run IPMI Standard Command  sel elist
    Should Not Contain  ${resp}  ${sel_no_entry_msg}
    ${get_sel_entry}=  Get Lines Containing String  ${resp}  ${sensor_name}
    ${sel_entry}=  Get Lines Containing String  ${get_sel_entry}  ${event_type}
    Should Contain  ${sel_entry}  ${event_dir}  msg=Add SEL Entry failed.

    RETURN  ${sel_entry}


Check Current Date Time Via IPMI
    [Documentation]  Verify Current Date and Time Via IPMI user command.

    ${resp}=  Run IPMI Standard Command  sel time get
    RETURN  ${resp}


Get Specific Sel Date
    [Documentation]  Gets initial time and adds year to the current date and returns future date.
    [Arguments]  ${year}

    # Description of argument(s):
    # ${year}             Can be any number of years (say 5 year).

    ${current_date}=  Get Current Date from BMC

    # Converting given years to days by multiplying with 365days and adding the days to current date.
    ${days}=  Evaluate  365*${year}+1
    ${date}=  Add Time To Date
    ...  ${current_date}  ${days}d  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S

    RETURN   ${date}


Converting Date to HexaDecimal
    [Documentation]  Converting the date into hexa decimal values.
    [Arguments]  ${date}

    # Description of argument(s):
    # ${date}             Can be any date in format %m/%d/%Y %H:%M:%S.

    ${epoch_date}=  Convert Date  ${date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S
    ${date}=  Convert To Hex  ${epoch_date}  lowercase=yes

    # function calls from utils.py.
    # Length of the date byte should be 8 so that each bytes are separated.
    ${date}=  Zfill Data  ${date}  8
    # To split every two characters to form one byte each.
    ${date}=  Split String With Index  ${date}  2
    # Prefix every list index value with 0x.
    ${date}=  Prefix Bytes  ${date}

    # Reverse the bytes and join the list to form request Time stamp data.
    Reverse List  ${date}
    ${date}=  Evaluate  " ".join(${date})

    RETURN  ${date}


Get Time Difference
    [Documentation]  Converting the date into hexa decimal values.
    [Arguments]  ${date1}  ${date2}

    # Description of argument(s):
    # ${date1}             Can be any date in format %m/%d/%Y %H:%M:%S.
    # ${date2}             Can be any date in format %m/%d/%Y %H:%M:%S.

    ${epoch_date1}=  Convert Date  ${date1}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S
    ${epoch_date2}=  Convert Date  ${date2}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    ${diff}=  Evaluate  int(${epoch_date1}) - int(${epoch_date2})

    RETURN  ${diff}


Identify SEL Time
    [Documentation]  Modify SEL Time From BMC For Set Sel Time Command.
    [Arguments]  ${time}

    # Description of argument(s):
    # time             Can be any number of hours or minutes in format %H:%M:%S.

    # Gets BMC current date via date command.
    ${current_date}=  Get Current Date from BMC

    ${modifying_date_status}=  Run Keyword And Return Status  Should Contain  ${time}  +

    ${date_time}=  Set Variable IF
    ...  ${modifying_date_status} == True  ${time.split("+")[-1]}
    ...  ${modifying_date_status} == False  ${time.split("-")[-1]}

    ${datetime} =  Run Keyword IF  ${modifying_date_status} == True
    ...    Add Time To Date
    ...    ${current_date}  ${date_time}  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S
    ...  ELSE IF  ${modifying_date_status} == False
    ...    Subtract Time From Date
    ...    ${current_date}  ${date_time}  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S

    #Set SEL Time.
    ${quoted_date}=  Fetch Date  ${datetime}

    RETURN  ${quoted_date}  ${datetime}


Set SEL Time Via IPMI
    [Documentation]  Set SEL Time for given date using IPMI.
    [Arguments]  ${date_time}

    # Description of argument(s):
    # ${date_time}       Can be any date in format %m/%d/%Y %H:%M:%S.

    ${resp}=  Run IPMI Standard Command  sel time set "${date_time}"
    Should Not Contain  ${resp}  Unspecified error


Test Setup Execution
    [Documentation]  Test Setup Execution.

    Redfish.Login
    # Change timesync mode to manual with timeout as per resource.robot.
    Time Sync Mode Change Through Redfish   ${FALSE}
    Sleep  ${NETWORK_TIMEOUT}
    Printn


Test Teardown Execution
    [Documentation]  For execution of Test teardown.

    Clear The SEL

    # Change TimeSync mode to NTP with Timeout as per default resource.robot.
    Time Sync Mode Change Through Redfish  ${TRUE}
    Sleep  ${NETWORK_TIMEOUT}
    Redfish.Logout
    FFDC On Test Case Fail
