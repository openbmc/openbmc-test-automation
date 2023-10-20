*** Settings ***

Documentation       Module to test IPMI System Info Parameters functionality.
...                 Following parameters are verfied in the script,
...                 1. Set In Progress - param 0,
...                 2. System Firmware Version - param 1,
...                 3. System Name - param 2,
...                 4. Primary OS Name - param 3,
...                 5. OS Name - param 4,
...                 6. Present OS Version Number - param 5.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Library             Collections
Library             String
Library             ../lib/ipmi_utils.py
Variables           ../data/ipmi_raw_cmd_table.py
Test Tags           IPMI

Suite Setup         Suite Setup Execution
Test Teardown       Run Keywords  Restore Default Configuration  AND  FFDC On Test Case Fail


*** Variables ***

# Converting to hexadecimal provides 14 bytes so string length is 0e for param 3, 4, 5.
${valid_os_version_name}       Version2.12345
${invalid_os_version}          ${valid_os_version_name}${6789}


*** Test Cases ***

Verify System Info Set In Progress
    [Documentation]  Verify Set In Progress of System Info Parameter,
    ...  to set the set-in-progress and set complete state via IPMI,
    ...  and verify whether the state is updated and restored as expected.
    [Tags]  Verify_System_Info_Set_In_Progress

    # Set In Progress - set complete.
    Set System Info Set In Progress  0x00

    # Get System Info Parameter for param 0 - Set In Progress.
    # Check if set-in-progress set to set complete.
    ${complete}=  Get System Info Set In Progress
    # ${complete[0]} - parameter version.
    # ${complete[1]} - Configuration parameter data,
    # here,  01h (set in progress).
    Should Be Equal  ${complete[1]}  00

    # Set In Progress - set in progress.
    Set System Info Set In Progress  0x01

    # Get System Info Parameter for param 0 - Set In Progress.
    # Check if set-in-progress set to set inprogress.
    ${inprogress}=  Get System Info Set In Progress
    # ${inprogress[0]} - parameter version.
    # ${inprogress[1]} - Configuration parameter data,
    # here,  01h (set in progress).
    Should Be Equal  ${inprogress[1]}  01


Verify System Info Set In Progress After BMC Reboot
    [Documentation]  Verify Set In Progress changes to default,
    ...  after bmc reboot of System Info Parameter via IPMI,
    ...  and verify whether the default setting is reflected.
    [Tags]  Verify_System_Info_Set_In_Progress_After_BMC_Reboot

    # Set the parameter 0 - Set_In_Progress to set in progress state.
    Set System Info Set In Progress  0x01
    # Get System Info Parameter for param 0 - Set In Progress.
    # Check if set-in-progress set to set in progress.
    ${inprogress}=  Get System Info Set In Progress
    # ${inprogress[0]} - parameter version.
    # ${inprogress[1]} - Configuration parameter data,
    # here,  01h (set in progress).
    Should Be Equal  ${inprogress[1]}  01

    # Reboot BMC.
    IPMI MC Reset Cold (run)

    # Since the param 0 - Set In Progress is volatile,
    # Default value should be updated after BMC reboot.
    ${state}=  Get System Info Set In Progress
    # ${state[0]} - parameter version.
    # ${state[1]} - Configuration parameter data,
    # here, 00h (set complete), 01h (set in progress),
    #       10 (commit write), 11 (reserved).
    Should Be Equal  ${state[1]}  ${set_in_progress}


Verify Get System Info Set In Progress With Invalid Data Length
    [Documentation]  Verify Get System Info Parameter Set In Progress via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_Set_In_Progress_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 0 - set in progress throws
    # error for invalid data length.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][0]} 0x00


Verify Set System Info Set In Progress With Invalid Data Length
    [Documentation]  Verify Set System Info Parameter Set In Progress via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_Set_In_Progress_With_Invalid_Data_Length

    # Check if the Set System Info Parameter for param 0 - set in progress throws
    # error for invalid data length.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} 0x00 0x00


Verify Set System Info Set In Progress With Invalid State
    [Documentation]  Verify Set System Info Parameter Set In Progress via IPMI invalid state,
    ...  and expect to get the error message for invalid data.
    [Tags]  Verify_Set_System_Info_Set_In_Progress_With_Invalid_State

    # Check if the Set System Info Parameter for param 0 - set in progress throws error for invalid State.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][2]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} 0x04


Verify System Info System Firmware Version
    [Documentation]  Verify System Firmware Version of System Info Parameter via IPMI,
    ...  and verify whether the version is updated.
    [Tags]  Verify_System_Info_System_Firmware_Version

    # Generate a random 14 byte data,
    # i,e 16-byte block for system firmware name string data.
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes.
    ${firmware_version}=  Generate Random String  14  [LETTERS]
    ${firmware_version}  ${fw_hex_data}=  Identify Request Data  ${firmware_version}
    # Consider random string generated is 'zwclMXwfczMvcY'.
    # Set the System Firmware Version of System Info Parameter.
    Set System Firmware Version  ${firmware_version}
    # Get the response of System Firmware Version,
    # and compare against randomly generated data bytes.
    ${fw_version}=  Get System Firmware Version
    # The response data will something be like,
    # ${fw_version}= ["11","00","00","0e","7a","77","63","6c","4d","58","77","66","63","7a","4d","76"].
    Should Be Equal  ${fw_version[4:]}  ${fw_hex_data}


Verify Get System Info System Firmware Version With Invalid Data Length
    [Documentation]  Verify Get System Info Parameter System Firmware Version via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_System_Firmware_Version_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 1 - System Firmware Version throws
    # error for invalid data length.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][0]} 0x00


Verify Set System Info System Firmware Version With Invalid Data Length
    [Documentation]  Verify Set System Info Parameter System Firmware Version via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_System_Firmware_Version_With_Invalid_Data_Length

    # Generate a random 15 byte data,
    # i,e 16-byte block for system firmware name string data,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes,
    # data 17 - extra byte.
    ${firmware_version}=  Generate Random String  15  [LETTERS]
    ${firmware_version}  ${fw_hex_data}=  Identify Request Data  ${firmware_version}
    # Consider random string generated is 'zwclMXwfczMvcYz'.
    # The request data bytes will be 15 bytes, in which 14 bytes are only expected.
    # Check if the Set System Info Parameter for param 1 - System Firmware Version throws
    # error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][0]} ${firmware_version}


Verify System Info System Name
    [Documentation]  Verify System Name of System Info Parameter via IPMI by setting,
    ...  a random system name and verify whether it is updated as expected.
    [Tags]  Verify_System_Info_System_Name

    # Generate a random 14 byte data,
    # i,e 16-byte block for system firmware name string data,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes.
    ${system_name}=  Generate Random String  14  [LETTERS]
    ${system_name}  ${name_hex_data}=  Identify Request Data  ${system_name}
    # Consider random string generated is 'zwclMXwfczMvcY'.

    # Set System Name for System Info Parameter.
    Set System Name  ${system_name}

    # Get the response of System Name,
    # and compare against randomly generated data bytes.
    ${sys_name}=  Get System Name
    # The response data will something be like,
    # ${sys_name}= ["11","00","00","0e","7a","77","63","6c","4d","58","77","66","63","7a","4d","76"].
    Should Be Equal  ${sys_name[4:]}  ${name_hex_data}


Verify Get System Info System Name With Invalid Data Length
    [Documentation]  Verify Get System Info Parameter System Name via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_System_Name_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 2 - System Name throws error
    # for invalid request data length.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][0]} 0x00


Verify Set System Info System Name With Invalid Data Length
    [Documentation]  Verify Set System Info Parameter System Name via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_System_Name_With_Invalid_Data_Length

    # Generate a random 15 byte data,
    # i,e 16-byte block for system firmware name string data,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes,
    # data 17 - extra byte.
    ${system_name}=  Generate Random String  15  [LETTERS]
    ${system_name}  ${name_hex_data}=  Identify Request Data  ${system_name}
    # Consider random string generated is 'zwclMXwfczMvcYz'.
    # The request data bytes will be 15 bytes, in which 14 bytes are only expected.

    # Check if the Set System Info Parameter for param 2 - System Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][0]} ${system_name}


Verify System Info Primary OS Name
    [Documentation]  Verify Primary OS Name of System Info Parameter via IPMI,
    ...  by setting a valid os version and verify whether it is updated as expected.
    [Tags]  Verify_System_Info_Primary_OS_Name

    # os_version_name given in variable section which is a 14 byte data.
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${valid_os_version_name}

    # Set Primary OS Name of System Info Parameter.
    Set Primary OS Name  ${os_name}

    # Get Primary OS Name of System Info Parameter.
    # Compare with the assigned os version name data.
    ${pr_os}=  Get Primary OS Name
    # The response data will something be like,
    # ${pr_os}= ["11","00","00","0e","56","65","72","73","69","6f","6e","32","2e","31","32","33"].
    Should Be Equal  ${pr_os[4:]}  ${os_hex_data}


Verify Get System Info Primary OS Name With Invalid Data Length
    [Documentation]  Verify Get System Info Parameter Primary OS Name via IPMI with extra bytes,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_Primary_OS_Name_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 3 - Primary OS Name throws
    # error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][0]} 0x00


Verify Set System Info Primary OS Name With Invalid Data Length
    [Documentation]  Verify setting invalid os version name to Primary OS Name,
    ...  of Set System Info Parameter via IPMI,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_Primary_OS_Name_With_Invalid_Data_Length

    # invalid_os_version given in variable section which is a 15 byte data,
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes,
    # Here 15 bytes so, data 17 - extra byte.
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 3 - Primary OS Name throws error
    # for invalid data request.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][0]} ${os_name}


Verify System Info OS Name
    [Documentation]  Verify setting valid os version to OS Name,
    ...  of System Info Parameter via IPMI and verify whether it updates as expected.
    [Tags]  Verify_System_Info_OS_Name

    # os_version_name given in variable section which is a 14 byte data.
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${valid_os_version_name}

    # Set OS Name of System Info Parameters.
    Set OS Name  ${os_name}

    # Get the OS Name and compare against given os_version_name.
    ${sysos}=  Get OS Name
    # The response data will something be like,
    # ${sysos}= ["11","00","00","0e","56","65","72","73","69","6f","6e","32","2e","31","32","33"].
    Should Be Equal  ${sysos[4:]}  ${os_hex_data}


Verify System Info OS Name After BMC Reboot
    [Documentation]  Verify setting valid os version name for OS Name,
    ...  of System Info Parameter and verify it changes to default after BMC Reboot via IPMI.
    [Tags]  Verify_System_Info_OS_Name_After_BMC_Reboot

    # os_version_name given in variable section which is a 14 byte data.
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${valid_os_version_name}

    # Set OS Name of System Info Parameters.
    Set OS Name  ${os_name}

    # Get the OS Name and compare against given os_version_name.
    ${sysos}=  Get OS Name
    # The response data will something be like,
    # ${sysos}= ["11","00","00","0e","56","65","72","73","69","6f","6e","32","2e","31","32","33"].
    Should Be Equal  ${sysos[4:]}  ${os_hex_data}

    # Cold Reset via IPMI
    IPMI MC Reset Cold (run)

    # Since OS Name is volatile,
    # compare with response data of Get OS Name,
    # with default OS Name.
    ${sysos}=  Get OS Name
    # Should return default response data.
    Should Be Equal  ${sysos[2:]}  ${default_os_name}


Verify Get System Info OS Name With Invalid Data Length
    [Documentation]  Verify OS Name of Get System Info Parameter via IPMI,
    ...  with extra bytes, and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_OS_Name_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 4 - OS Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][0]} 0x00


Verify Set System Info OS Name With Invalid Data Length
    [Documentation]  Verify setting invalid os version name to OS Name,
    ...  of Get System Info Parameter via IPMI,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_OS_Name_With_Invalid_Data_Length

    # invalid_os_version given in variable section which is a 15 byte data,
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes,
    # Here 15 bytes so, data 17 - extra byte.
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 4 - OS Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][0]} ${os_name}


Verify System Info Present OS Version Number
    [Documentation]  Verify setting valid os version for Present OS Version Number,
    ...  of System Info Parameter via IPMI and verify whether it is updated as expected.
    [Tags]  Verify_System_Info_Present_OS_Version_Number

    # os_version_name given in variable section which is a 14 byte data.
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${valid_os_version_name}

    # Set Present OS Version Number for System Info Parameters.
    Set Present OS Version Number  ${os_name}

    # Get Present OS Version Number for System Info Parameters,
    # compare with response data of Get OS Name,
    # with assigned os version name.
    ${os_version}=  Get Present OS Version Number
    # The response data will something be like,
    # ${os_version}= ["11","00","00","0e","56","65","72","73","69","6f","6e","32","2e","31","32","33"].
    Should Be Equal  ${os_version[4:]}  ${os_hex_data}


Verify Get System Info Present OS Version Number With Invalid Data Length
    [Documentation]  Verify Get System Info Parameter Present OS Version Number via IPMI,
    ...  with extra bytes, and expect to get the error message for invalid length.
    [Tags]  Verify_Get_System_Info_Present_OS_Version_Number_With_Invalid_Data_Length

    # Check if the Get System Info Parameter for param 5 - Present OS Version Number throws
    # error for invalid request data.
    Run Keyword and Expect Error
    ...  *${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][0]} 0x00


Verify Set System Info Present OS Version Number With Invalid Data Length
    [Documentation]  Verify setting invalid os version to Present OS Version Number
    ...  of Set System Info Parameter via IPMI,
    ...  and expect to get the error message for invalid length.
    [Tags]  Verify_Set_System_Info_Present_OS_Version_Number_With_Invalid_Data_Length

    # invalid_os_version given in variable section which is a 15 byte data.
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type,
    # data 2 - string length (in bytes, 1-based),
    # data 3 to 16 - system firmware name string data - 14 bytes,
    # Here 15 bytes so, data 17 - extra byte.
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 5 - Present OS Version Number throws
    # error for invalid request data.
    Run Keyword and Expect Error
    ...  *${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][0]} ${os_name}


*** Keywords ***

Identify Request Data
    [Documentation]  Convert string to hexadecimal request data with and without prefix 0x.
    [Arguments]  ${string}

    # Given a string, convert to hexadecimal and prefix with 0x.
    # Consider random string generated ${string} is 'zwc'.
    ${fw_ver_hex_list}=  Create List
    ${hex_data_list}=  Create List
    ${resp_data_list}=  Split String With Index  ${string}  1
    # ${resp_data_list} will be ['z', 'w', 'c'].
    FOR  ${data}  IN  @{resp_data_list}
        # prefixes 0x by default.
        # Example : 0x00.
        ${hex_value}=  Evaluate  hex(ord("${data}"))
        # provides only hexadecimal bytes.
        # Example : 00.
        ${hex}=  Evaluate  hex(ord("${data}"))[2:]
        # With prefix 0x.
        Append To List  ${fw_ver_hex_list}  ${hex_value}
        # Without prefix.
        Append To List  ${hex_data_list}  ${hex}
    END
    ${fw_ver_hex}=  Evaluate  " ".join(${fw_ver_hex_list})

    [Return]  ${fw_ver_hex}  ${hex_data_list}


Get System Info Set In Progress
    [Documentation]  Run Get system info parameter command for set-in-progress and return response data.

    # Get System Info Parameter for param 0 - Set In Progress.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set System Info Set In Progress
    [Documentation]  Set System Info Set In Progress with valid state via IPMI.
    [Arguments]  ${state}

    # Set System Info Parameter for param 0 - Set In Progress.
    # ${state} can be can be any - 00 | 01 | 10 | 11.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} ${state}


Get System Firmware Version
    [Documentation]  Run Get system info parameter command for system firmware version
    ...              and return response data.

    # Get System Info Parameter for param 1 - System Firmware Version.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set System Firmware Version
    [Documentation]  Set System Firmware Version for System Info with valid version.
    [Arguments]  ${version}

    # Set System Info Parameter for param 1 - System Firmware Version.
    # ${version} can be any 14 data.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][0]} ${version}


Get System Name
    [Documentation]  Run system info parameter command for system name and return response data.

    # Get System Info Parameter for param 2 - System Name.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set System Name
    [Documentation]  Set System Name for System Info with valid name.
    [Arguments]  ${sys_name}

    # Set System Info Parameter for param 2 - System Name.
    # ${sys_name} can be any 14 byte data.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][0]} ${sys_name}


Get Primary OS Name
    [Documentation]  Run Get System Info command for primary OS name and return response data.

    # Get System Info Parameter for param 3 - Primary OS Name.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set Primary OS Name
    [Documentation]  Set Primary OS Name for System Info with valid os name.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 3 - Primary OS Name.
    # ${os_name} can be any 14 byte data.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][0]} ${os_name}


Get OS Name
    [Documentation]  Run get System Info command for OS name and return response data.

    # Get System Info Parameter for param 4 - OS Name.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set OS Name
    [Documentation]  Set OS Name for System Info with valid os name.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 4 - OS Name.
    # ${os_name} can be any 14 byte data.
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][0]} ${os_name}


Get Present OS Version Number
    [Documentation]  Run Get System Info command for present os version name and return response.

    # Get System Info Parameter for param 5 - Present OS Version Number.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][0]}
    ${resp}=  Split String  ${resp}

    [Return]  ${resp}


Set Present OS Version Number
    [Documentation]  Set Present OS Version Number for System Info with valid os version.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 5 - Present OS Version Number.
    # ${os_name} can be any 14 byte data
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][0]} ${os_name}


Add Prefix To List Objects And Join String
    [Documentation]  Adding prefix '0x' to each list object and join the string.
    [Arguments]  ${list}

    # ${list} contains list of hexadecimal data.

    # Prefix Bytes with 0x for each data bytes and makes a string of request bytes.
    # Prefix Bytes function under lib/ipmi_utils.py.
    # Prefixes every list item with 0x and returns list of prefixed hexadecimal data.
    ${prefix_list}=  Prefix Bytes  ${list}
    ${prefix_list}=  Evaluate  " ".join(${prefix_list})

    [Return]  ${prefix_list}


Suite Setup Execution
    [Documentation]  Suite setup execution to fetch all the default response bytes,
    ...  prefix each byte with 0x and make them a suite variable.

    # Get Default Values of each parameters.
    # Set In Progress - param 0.
    ${resp}=  Get System Info Set In Progress
    # Configuration parameter data - 11 xx (xx can be any - 00 | 01 | 10 | 11).
    ${set_in_progress}=  Set Variable  ${resp[1]}

    Set Suite Variable  ${set_in_progress}

    # System Firmware Version - param 1.
    ${resp}=  Get System Firmware Version
    # Configuration parameter data - 11 x1 x2 xx xx xx xx .. xx (xx - 14 bytes).
    # x1 - encoding, x2 - string length in bytes.
    ${sys_fw_version}=  Set Variable  ${resp[2:]}
    # Prefix all bytes with 0x.
    ${sys_fw_version_string}=  Add Prefix To List Objects And Join String  ${sys_fw_version}

    Set Suite Variable  ${sys_fw_version}
    Set Suite Variable  ${sys_fw_version_string}

    # System Name - param 2.
    ${resp}=  Get System Name
    # Configuration parameter data - 11 x1 x2 xx xx xx xx .. xx (xx - 14 bytes).
    # x1 - encoding, x2 - string length in bytes.
    ${sys_name_default}=  Set Variable  ${resp[2:]}
    # Prefix all bytes with 0x.
    ${sys_name_hex_default}=  Add Prefix To List Objects And Join String  ${sys_name_default}

    Set Suite Variable  ${sys_name_default}
    Set Suite Variable  ${sys_name_hex_default}

    # Primary OS Name - param 3.
    ${resp}=  Get Primary OS Name
    # Configuration parameter data - 11 x1 x2 xx xx xx xx .. xx (xx - 14 bytes).
    # x1 - encoding, x2 - string length in bytes.
    ${primary_os_name}=  Set Variable  ${resp[2:]}
    # Prefix all bytes with 0x.
    ${primary_os_name_hex}=  Add Prefix To List Objects And Join String  ${primary_os_name}

    Set Suite Variable  ${primary_os_name}
    Set Suite Variable  ${primary_os_name_hex}

    # OS Name - param 4.
    ${resp}=  Get OS Name
    # Configuration parameter data - 11 x1 x2 xx xx xx xx .. xx (xx - 14 bytes).
    # x1 - encoding, x2 - string length in bytes.
    ${default_os_name}=  Set Variable  ${resp[2:]}
    # Prefix all bytes with 0x.
    ${default_os_name_hex}=  Add Prefix To List Objects And Join String  ${default_os_name}

    Set Suite Variable  ${default_os_name}
    Set Suite Variable  ${default_os_name_hex}

    # Present OS Version Number - param 5.
    ${resp}=  Get Present OS Version Number
    # Configuration parameter data - 11 x1 x2 xx xx xx xx .. xx (xx - 14 bytes).
    # x1 - encoding, x2 - string length in bytes.
    ${present_os_num}=  Set Variable  ${resp[2:]}
    # Prefix all bytes with 0x.
    ${present_os_num_hex}=  Add Prefix To List Objects And Join String  ${present_os_num}

    Set Suite Variable  ${present_os_num}
    Set Suite Variable  ${present_os_num_hex}


Restore Default Configuration
    [Documentation]  Restore all system info parameter response data to,
    ...  default data obtained from suite setup.

    # All variable to set are suite variables declared in suite setup.

    # Set In Progress - param 0.
    Set System Info Set In Progress  0x${set_in_progress}

    # System Firmware Version - param 1.
    Run IPMI Standard Command  raw 0x06 0x58 0x01 0x00 ${sys_fw_version_string}

    # System Name - param 2.
    Run IPMI Standard Command  raw 0x06 0x58 0x02 0x00 ${sys_name_hex_default}

    # Primary OS Name - param 3.
    Run IPMI Standard Command  raw 0x06 0x58 0x03 0x00 ${primary_os_name_hex}

    # OS Name - param 4.
    Run IPMI Standard Command  raw 0x06 0x58 0x04 0x00 ${default_os_name_hex}

    # Present OS Version Number - param 5.
    Run IPMI Standard Command  raw 0x06 0x58 0x05 0x00 ${present_os_num_hex}
