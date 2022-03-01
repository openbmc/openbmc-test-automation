*** Settings ***

Documentation    Module to test IPMI SEL Time functionality.
...              Pre-requisite Condition : Client Machine and BMC should be in Same TimeZone (example : UST)
...
...              IPMI Raw command variables are defined under ../data/ipmi_raw_command_table.py
...              Python basic functionalities are defined under ../lib/functions.py imported under ../lib/resource.robot
...
...              Test the Set/Get SEL Time functionality and compare the result against BMC Native command (date).
...
...              Set the Time Sync Mode from NTP to Manual to Set SEL Time.
...              Time Sync Mode change performed via REDFISH URI.
...              Performs the change in Time Sync Mode with Test Setup and Teardown Execution with default NETWORK_TIMEOUT provided under ../lib/resource.robot
...
...              NETWORK_RESTART_TIME added for Set SEL Time and Add SEL Entry as the corresponding command takes approx 5 seconds for the operation to reflect.
...
...              Current SEL time identified via BMC Native command (date) and perform SEL Time operations.
...
...              Script Verifies SEL Time for various scenarios such as,
...              Get current time from BMC and add future year and compare against BMC native command (date),
...              Gets BMC Current Time and Adds 15 minutes and compare against BMC native command (date),
...              Gets BMC Current Time and subtracts 1 day and compare against BMC native command (date),
...              Add SEL Entry for all the above scenarios and compare against BMC native command (date).

Library          DateTime
Library          Collections
Library          String
Resource         ../lib/ipmi_client.robot
Resource         ../lib/openbmc_ffdc.robot
Variables        ../data/ipmi_raw_cmd_table.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${NETWORK_RESTART_TIME}   5s
${bmc}                    ${OPENBMC_HOST}
${export}                 export ${bmc}
${export_curl}            export token=`curl -k -H "Content-Type: application/json" -X POST https://${bmc}/login -d '{"username" : "${OPENBMC_USERNAME}", "password" : "${OPENBMC_PASSWORD}"}' | grep token | awk '{print $2;}' | tr -d '"'`


*** Test Cases ***

Verify Default Get SEL Time
    [Documentation]  Verify IPMI Get SEL Time.
    [Tags]  Verify_Default_Get_SEL_Time
    [Setup]  Printn
    [Teardown]  FFDC On Test Case Fail

    # Gets the current SEL time via Get SEL Time Command
    ${resp}=  Get SEL Time Command
    Should Not Be Empty  ${resp}


Set SEL Time On NTP Mode
    [Documentation]   IPMI Get SEL Time without NTP
    [Tags]  Verify_SEL_Set_Time_On_NTP_Mode
    [Setup]  Printn
    [Teardown]  printn

    # Get current time from BMC and add future year (here, 5years)
    ${sel_date}=  Get Specific Sel Date  5
    
    # Gives Hexa decimal Raw command data request with the prefix of 0x
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    ${Set_sel_time}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][2]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Should Contain  ${Set_sel_time}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][1]}


Verify SEL Set Time For Specific Time
    [Documentation]  Verify IPMI Get SEL Time.
    [Tags]  Verify_SEL_Set_Time_For_Specific_Time

    # Get current time from BMC and add future year (here, 5years)
    ${sel_date}=  Get Specific Sel Date  5
    
    # Gives Hexa decimal Raw command data request with the prefix of 0x
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    # Set SEL Entry Command
    Set SEL Time Entry Via Raw Command  ${sel_date_raw}

    # Get SEL Time Command
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Identify Time difference and find the difference is less than 6 seconds
    # Command execution may happen at the end of millisecond so considered 6 seconds as difference
    ${time_difference}=  Get Time Difference  ${get_sel_time}  ${sel_date}
    Should Be True  0<=${time_difference}<=5
    ...  msg=Set SEL Time Not Working

    # Get BMC time (native) and compare with set sel time given
    ${bmc_time}=  Get Current Date from BMC

    ${difference}=  Get Time Difference  ${bmc_time}  ${sel_date}
    Should Be True  0<=${difference}<=6
    

Verify Set SEL Time With Future Date And Time
    [Documentation]  Verify IPMI Get SEL Time by adding 15 minutes from current time.
    [Tags]  Verify_Set_SEL_Time_With_Future_Date_And_Time

    # Gets BMC Current Time and Adds 15 minutes and sets the SEL Time
    ${sel_time}  ${set_sel_time}=  Identify SEL Time Future DateTime   06:15:00

    # Set SEL Time via IPMI command
    Set SEL Time Via IPMI  ${sel_time}

    # Get SEL Time Command
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Difference of time between set sel time nd get time
    ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
    Should Be True  0<=${difference}<=2

    # Difference of time between BMC Date and Get SEL Time
    ${bmc_time}=  Get Current Date from BMC
    ${difference}=  Get Time Difference  ${get_sel_time}  ${bmc_time}
    Should Be True  0<=${difference}<=2


Verify Set SEL Time With Past Date And Time
    [Documentation]  Verify IPMI Get SEL Time for Time Delay of 1 day from current dat and time.
    [Tags]  Verify_Set_SEL_Time_With_Past_Date_And_Time

    # Gets BMC Current Time and subtracts 1 day and sets the SEL Time
    ${sel_time}  ${set_sel_time}=  Identify SEL Time DateTime Delay  1d

    ${status}=  Run Keyword And Return Status  Should Not Contain  ${sel_time}  1969
    ...  msg=Date cannot be less than 1970

    IF  '${status}' == '${TRUE}'
        # Set SEL Time via IPMI command
        Set SEL Time Via IPMI  ${sel_time}
        # Get SEL Time Command
        ${get_sel_time}=  Check Current Date Time Via IPMI
        # Difference of time between set sel time nd get time
        ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
        Should Be True  0<=${difference}<=2
        # Difference of time between BMC Date and Get SEL Time
        ${bmc_time}=  Get Current Date from BMC
        ${difference}=  Get Time Difference  ${get_sel_time}  ${bmc_time}
        Should Be True  0<=${difference}<=2
    ELSE
        FAIL  SEL Time cannot set Date less than 1970
    END


Verify SEL Set Time For Invalid Data Request
    [Documentation]  Verify IPMI Get SEL Time for invalid data request
    [Tags]  Verify_SEL_Set_Time_For_Invalid_Data_Request
    [Setup]  Printn
    [Teardown]  FFDC On Test Case Fail

    # Gets BMC current date via date command
    ${current_date}=  Get Current Date from BMC

    # Gives Hexa decimal Raw command data request with the prefix of 0x
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${current_date}

    # Set Invalid SEL Time with one extra request byte
    ${Set_seltime_invalid}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][4]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw} 0x00
    Should Contain  ${Set_seltime_invalid}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][3]}


Verify SEL Set Time For Incomplete Data Request
    [Documentation]  Verify IPMI Get SEL Time for invalid data with one byte less request data
    [Tags]  Verify_SEL_Set_Time_For_Incomplete_Data_Request
    [Setup]  Printn
    [Teardown]  FFDC On Test Case Fail

    # Gets BMC current date via date command
    ${current_date}=  Get Current Date from BMC

    # Gives Hexa decimal Raw command data request with the prefix of 0x
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${current_date}

    # For data request less than expected byes, remove last byte
    ${sel_date_raw}=  Split String  ${sel_date_raw}
    Remove From List  ${sel_date_raw}  -1
    ${sel_date_raw}=  Evaluate  " ".join(${sel_date_raw})

    # Set Incomplete SEL Time with one less request byte
    ${Set_seltime_incomplete}=  Run Keyword and Expect Error  *${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][4]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Should Contain  ${Set_seltime_incomplete}  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][3]}


Verify SEL Time In SEL Entry
    [Documentation]  Verify Configured SEL Time reflects in newly added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry

    Clear The SEL

   # change to manual, get current time and add future year (here, 5years)
    ${sel_date}=  Get Specific Sel Date  5
    
    # Gives Hexa decimal Raw command data request with the prefix of 0x
    ${sel_date_raw}=  Converting Date to HexaDecimal  ${sel_date}

    # Set SEL Entry Command
    Set SEL Time Entry Via Raw Command  ${sel_date_raw}

    # Get SEL Time Command
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Identify Time difference and find the difference is less than 6 seconds
    # Command execution may happen at the end of millisecond so considered 6 seconds as difference
    ${time_difference}=  Get Time Difference  ${get_sel_time}  ${sel_date}
    Should Be True  0<=${time_difference}<=5
    ...  msg=Set SEL Time Not Working

    # Get BMC time (native) and compare with set sel time given
    ${bmc_time}=  Get Current Date from BMC

    ${difference}=  Get Time Difference  ${bmc_time}  ${sel_date}
    Should Be True  0<=${difference}<=6
    
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

    # Finds the last added sel entry
    ${resp}=  Verify Last SEL Added  ${sensor_type}  ${sensor_name}

    # Fetches the date of the last added SEL Entry
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

    # Identify and find the time difference is less than 60 seconds
    # Finding the sensor details and execution may take upto a minute.
    # Compare  date and time of Set SEL with sel entry
    ${d}=  Get Time Difference  ${sel_entry_date}  ${sel_date}
    Should Be True  0<=${d}<=60


Verify SEL Time In SEL Entry For Future Date and Time
    [Documentation]  Verify configured SEL Time (Future Date & Time) in added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry_For_Future_Date_and_Time

    Clear The SEL

    # Gets BMC Current Time and Adds 15 minutes and sets the SEL Time
    ${sel_time}  ${set_sel_time}=  Identify SEL Time Future DateTime   06:15:00

    # Set SEL Time via IPMI command
    Set SEL Time Via IPMI  ${sel_time}

    # Get SEL Time Command
    ${get_sel_time}=  Check Current Date Time Via IPMI

    # Difference of time between set sel time nd get time
    ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
    Should Be True  0<=${difference}<=2

    # Difference of time between BMC Date and Get SEL Time
    ${bmc_time}=  Get Current Date from BMC
    ${difference}=  Get Time Difference  ${get_sel_time}  ${bmc_time}
    Should Be True  0<=${difference}<=2

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

    # Finds the last added sel entry
    ${resp}=  Verify Last SEL Added  ${sensor_type}  ${sensor_name}

    # Fetches the date of the last added SEL Entry
    ${sel_entry_date}=  Fetch Added SEL Date  ${resp}

    # Identify and find the time difference is less than 60 seconds
    # Finding the sensor details and execution may take upto a minute.
    # Compare  date and time of Set SEL with sel entry
    ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
    Should Be True  0<=${d}<=60


Verify SEL Time In SEL Entry For Past Date And Time
    [Documentation]  Verify configured SEL Time (Past Date & Time) in added SEL Entry.
    [Tags]  Verify_SEL_Time_In_SEL_Entry_For_Past_Date_And_Tine

    Clear The SEL

    # Gets BMC Current Time and subtracts 1 day and sets the SEL Time
    ${sel_time}  ${set_sel_time}=  Identify SEL Time DateTime Delay  1d

    ${status}=  Run Keyword And Return Status  Should Not Contain  ${sel_time}  1969
    ...  msg=Date cannot be less than 1970

    IF  '${status}' == '${TRUE}'
        # Set SEL Time via IPMI command
        Set SEL Time Via IPMI  ${sel_time}
        # Get SEL Time Command
        ${get_sel_time}=  Check Current Date Time Via IPMI
        # Difference of time between set sel time nd get time
        ${difference}=  Get Time Difference  ${get_sel_time}  ${set_sel_time}
        Should Be True  0<=${difference}<=2
        # Difference of time between BMC Date and Get SEL Time
        ${bmc_time}=  Get Current Date from BMC
        ${difference}=  Get Time Difference  ${get_sel_time}  ${bmc_time}
        Should Be True  0<=${difference}<=2
        
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

        # Finds the last added sel entry
        ${resp}=  Verify Last SEL Added  ${sensor_type}  ${sensor_name}
        # Fetches the date of the last added SEL Entry

        ${sel_entry_date}=  Fetch Added SEL Date  ${resp}
        # Identify and find the time difference is less than 60 seconds
        # Finding the sensor details and execution may take upto a minute.
        # Compare  date and time of Set SEL with sel entry
        ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
        Should Be True  0<=${d}<=60
    ELSE
        FAIL  SEL Time cannot set Date less than 1970
    END


Verify Multiple Set SEL Time With Multiple Add SEL Entry
    [Documentation]  Verify Multiple Addition Of SEL entry
    [Tags]  Verify_Multiple_Set_SEL_Time_With_Multiple_Add_SEL_Entry

    # Gets BMC Current Time and Adds 15 minutes and sets the SEL Time
    ${sel_time}  ${set_sel_time}=  Identify SEL Time Future DateTime   06:15:00

    FOR  ${i}  IN RANGE  1  6
    
      # Set SEL Time via IPMI command
      Set SEL Time Via IPMI  ${sel_time}

      # Clear the SEL
      Clear The SEL

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

      # Finds the last added sel entry
      ${resp}=  Verify Last SEL Added  ${sensor_type}  ${sensor_name}
      
      # Fetches the date of the last added SEL Entry
      ${sel_entry_date}=  Fetch Added SEL Date  ${resp}
      
      # Identify and find the time difference is less than 60 seconds
      # Finding the sensor details and execution may take upto a minute.
      # Compare  date and time of Set SEL with sel entry
      ${d}=  Get Time Difference  ${sel_entry_date}  ${set_sel_time}
      Should Be True  ${d}<=60

    END


*** Keywords ***

Time Sync Mode Change Through Redfish
    [Documentation]  Export IP, Token and Change the Time sync to Manual
    [Arguments]   ${boolean_obj}

    # May be changed to WebView

    Run  ${export}
    ${res}=  Run And Return Rc  ${export_curl}

    # Changing Time Sync Mode to Manual
    Change Time Sync Mode Via Redfish  ${boolean_obj}


Change Time Sync Mode Via Redfish
    [Documentation]  To Change the Time Sync Mode Via Redfish
    [Arguments]   ${boolean_obj}

    ${mode}=  Create Dictionary  ProtocolEnabled=${boolean_obj}
    ${data}=  Create Dictionary  NTP=${mode}
    Redfish.patch  ${REDFISH_NW_PROTOCOL_URI}  body=&{data}
    ...   valid_status_codes=[${HTTP_NO_CONTENT}]

    Sleep  ${NETWORK_RESTART_TIME}


Get SEL Time Command
    [Documentation]  Get SEL Time Command

    ${get_sel_time}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['SEL_entry']['Get_SEL_Time'][0]}

    [Return]    ${get_sel_time}


Set SEL Time Entry Via Raw Command
    [Documentation]  Set SEL Time Command
    [Arguments]  ${sel_date_raw}

    Run IPMI Command  ${IPMI_RAW_CMD['SEL_entry']['Set_SEL_Time'][0]} ${sel_date_raw}
    Sleep  ${NETWORK_RESTART_TIME}


Clear The SEL
    [Documentation]  Clear SEL Command

    # Clear the SEL
    ${out}=  Run IPMI Standard Command  sel clear
    Should Contain  ${out}  Clearing SEL
    Sleep  2s


Verify Last SEL Added
    [Documentation]  Verify last SEL added
    [Arguments]  ${sensor_type}  ${sensor_name}

    ${resp}=  Run IPMI Standard Command  sel elist last 1
    Run Keywords  Should Contain  ${resp}  ${sensor_type} ${sensor_name}  AND
    ...  Should Contain  ${resp}  Asserted  msg=Add SEL Entry failed.
    Should Not Contain  ${resp}  reset/cleared

    [Return]  ${resp}


Check Current Date Time Via IPMI
    [Documentation]  Verify Current Date and Time Via IPMI user command

    ${resp}=  Run IPMI Standard Command  sel time get
    [Return]  ${resp}


Get Specific Sel Date
    [Documentation]  Gets Initial Time and adds year to the current date and returns future date.
    [Arguments]  ${year}

    ${current_date}=  Get Current Date from BMC

    # Converting given years to days by multiplying with 365days and adding the days to current date.
    ${days}=  Evaluate  365*${year}+1
    ${date} =  Add Time To Date  ${current_date}  ${days}d  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S

    [Return]   ${date}


Converting Date to HexaDecimal
    [Documentation]  Converting the date into hexa decimal values
    [Arguments]  ${date}

    ${epoch_date}=  Convert Date  ${date}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S
    ${date}=  Convert To Hex  ${epoch_date}  lowercase=yes

    # function calls from function.py
    # Length of the date byte should be 8 so that each bytes are seperated
    ${date}=  Zfill Data  ${date}  8
    # To split every two characters to form one byte each
    ${date}=  Split List With Index  ${date}  2
    # Prefix every list index value with 0x
    ${date}=  Prefix Bytes  ${date}

    # Reverse the bytes and join the list to form request Time stamp data
    Reverse List  ${date}
    ${date}=  Evaluate  " ".join(${date})

    [Return]  ${date}


Get Time Difference
    [Documentation]  Converting the date into hexa decimal values
    [Arguments]  ${date1}  ${date2}

    ${epoch_date1}=  Convert Date  ${date1}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S
    ${epoch_date2}=  Convert Date  ${date2}  epoch  exclude_millis=yes  date_format=%m/%d/%Y %H:%M:%S

    ${diff}=  Evaluate  int(${epoch_date1}) - int(${epoch_date2})
    
    [Return]  ${diff}


Identify SEL Time Future DateTime 
    [Documentation]  Identify SEL Time Future DateTime 
    [Arguments]  ${time}

    # Gets BMC current date via date command
    ${current_date}=  Get Current Date from BMC

    ${datetime} =  Add Time To Date  ${current_date}  ${time}  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S

    #Set SEL Time
    ${quoted_date}=  Fetch Date  ${datetime}

    [Return]  ${quoted_date}  ${datetime}


Identify SEL Time DateTime Delay
    [Documentation]  Identify SEL Time DateTime Delay by subtracting given date.
    [Arguments]  ${days}

    # Gets BMC current date via date command
    ${current_date}=  Get Current Date from BMC

    ${datetime} =  Subtract Time From Date  ${current_date}  ${days}  result_format=%m/%d/%Y %H:%M:%S  date_format=%m/%d/%Y %H:%M:%S

    #Set SEL Time
    ${quoted_date}=  Fetch Date  ${datetime}

    [Return]  ${quoted_date}  ${datetime}


Set SEL Time Via IPMI
    [Documentation]  Set SEL Time for given date using IPMI.
    [Arguments]  ${quoted_date}

    ${resp}=  Run IPMI Standard Command  sel time set "${quoted_date}"
    Should Not Contain  ${resp}  Unspecified error


Test Setup Execution
    [Documentation]  Test Setup Execution

    # Change TimeSync mode to Manual with Timeout as per resource.robot.
    Time Sync Mode Change Through Redfish   ${FALSE}
    Sleep  ${NETWORK_TIMEOUT}


Test Teardown Execution
    [Documentation]  For execution of Test teardown

    Clear The SEL

    # Change TimeSync mode to NTP with Timeout as per default resource.robot.
    Time Sync Mode Change Through Redfish  ${TRUE}
    Sleep  ${NETWORK_TIMEOUT}

    FFDC On Test Case Fail
