*** Settings ***

Documentation       Module to test IPMI System Info Parameters functionality.
Library             Collections
Library             String
Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py

Suite Setup         Suite Setup Execution
Test Teardown       Restore Default Configuration

*** Variables ***

# Converting to hexadecimal provides 14 bytes so string length is 0e for param 3, 4, 5
${os_version_name}       Version2.12345
${invalid_os_version}    Version2.123456789

*** Test Cases ***
Verify System Info Set In Progress
    [Documentation]  Verify Set In Progress of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_Set_In_Progress

    # Set In Progress - set complete.
    Set System Info Set In Progress  0x00

    # Get System Info Parameter for param 0 - Set In Progress
    # Check if set-in-progress set to set complete
    ${resp}=  Get System Info Set In Progress
    ${resp}=  Split String  ${resp}
    ${complete}=  Set Variable  ${resp[1]}
    Should Be Equal  ${complete}  00

    # Set In Progress - set in progress.
    Set System Info Set In Progress  0x01

    # Get System Info Parameter for param 0 - Set In Progress
    # Check if set-in-progress set to set complete
    ${resp}=  Get System Info Set In Progress
    ${resp}=  Split String  ${resp}
    ${inprogress}=  Set Variable  ${resp[1]}
    Should Be Equal  ${inprogress}  01


Verify System Info Set In Progress After BMC Reboot
    [Documentation]  Verify Set In Progress changes to default after bmc reboot of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_Set_In_Progress_After_BMC_Reboot

    # Set the parameter 0 - Set_In_Progress to set in progress state.
    Set System Info Set In Progress  0x01

    # Get System Info Parameter for param 0 - Set In Progress
    # Check if set-in-progress set to set complete
    ${resp}=  Get System Info Set In Progress
    ${resp}=  Split String  ${resp}
    ${inprogress}=  Set Variable  ${resp[1]}
    Should Be Equal  ${inprogress}  01

    # Reboot BMC
    BMC Reboot Via Cold Reset

    # Since the param 0 - Set In Progress is volatile,
    # Default value should be updated after BMC reboot
    ${resp}=  Get System Info Set In Progress
    ${resp}=  Split String  ${resp}
    ${state}=  Set Variable  ${resp[1]}
    Should Be Equal  ${state}  ${set_in_progress}


Verify Get System Info Set In Progress With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter Set In Progress via IPMI with extra bytes.
    [Tags]  Verify_Get_System_Info_Set_In_Progress_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 0 - set in progress throws error for invalid data length
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][0]} 0x00


Verify Set System Info Set In Progress With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter Set In Progress via IPMI with extra bytes.
    [Tags]  Verify_Set_System_Info_Set_In_Progress_With_Invalid_Data_Request

    # Check if the Set System Info Parameter for param 0 - set in progress throws error for invalid data length
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} 0x00 0x00


Verify Set System Info Set In Progress With Invalid State
    [Documentation]  Verify Set System Info Parameter Set In Progress via IPMI invalid state.
    [Tags]  Verify_Set_System_Info_Set_In_Progress_With_Invalid_State

    # Check if the Set System Info Parameter for param 0 - set in progress throws error for invalid State
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][2]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} 0x04


Verify System Info System Firmware Version
    [Documentation]  Verify System Firmware Version of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_System_Firmware_Version

    # Generate a random 14 byte data,
    # i,e 16-byte block for system firmware name string data
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    ${firmware_version}=  Generate Random String  14  [LETTERS]
    ${firmware_version}  ${fw_hex_data}=  Identify Request Data  ${firmware_version}

    # Set the System Firmware Version of System Info Parameter
    Set System Firmware Version  ${firmware_version}
    # Get the response of System Firmware Version,
    # and compare against randomly generated data bytes
    ${resp}=  Get System Firmware Version
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${fw_hex_data}


Verify Get System Info System Firmware Version With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter System Firmware Version via IPMI invalid Data Request.
    [Tags]  Verify_Get_System_Info_System_Firmware_Version_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 1 - System Firmware Version throws error for invalid data length
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][0]} 0x00


Verify Set System Info System Firmware Version With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter System Firmware Version via IPMI invalid Data Request.
    [Tags]  Verify_Set_System_Info_System_Firmware_Version_With_Invalid_Data_Request

    # Generate a random 15 byte data
    # i,e 16-byte block for system firmware name string data
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    # data 17 - extra byte
    ${firmware_version}=  Generate Random String  15  [LETTERS]
    ${firmware_version}  ${fw_hex_data}=  Identify Request Data  ${firmware_version}

    # Check if the Set System Info Parameter for param 1 - System Firmware Version throws error for invalid request data
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][0]} ${firmware_version}


Verify System Info System Name
    [Documentation]  Verify System Name of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_System_Name

    # Generate a random 14 byte data,
    # i,e 16-byte block for system firmware name string data
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    ${system_name}=  Generate Random String  14  [LETTERS]
    ${system_name}  ${name_hex_data}=  Identify Request Data  ${system_name}

    # Set System Name for System Info Parameter
    Set System Name  ${system_name}

    # Get the response of System Name,
    # and compare against randomly generated data bytes
    ${resp}=  Get System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${name_hex_data}


Verify Get System Info System Name With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter System Name via IPMI invalid Data Request.
    [Tags]  Verify_Get_System_Info_System_Name_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 2 - System Name throws error for invalid request data length
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][0]} 0x00


Verify Set System Info System Name With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter System Name via IPMI invalid Data Request.
    [Tags]  Verify_Set_System_Info_System_Name_With_Invalid_Data_Request

    # Generate a random 15 byte data
    # i,e 16-byte block for system firmware name string data
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    # data 17 - extra byte
    ${system_name}=  Generate Random String  15  [LETTERS]
    ${system_name}  ${name_hex_data}=  Identify Request Data  ${system_name}

    # Check if the Set System Info Parameter for param 2 - System Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][0]} ${system_name}


Verify System Info Primary Operating System Name
    [Documentation]  Verify Primary Operating System Name of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_Primary_Operating_System_Name

    # os_version_name given in variable section which is a 14 byte data
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${os_version_name}

    # Set Primary Operating System Name of System Info Parameter
    Set Primary Operating System Name  ${os_name}

    # Get Primary Operating System Name of System Info Parameter
    # Compare with the assigned os version name data
    ${resp}=  Get Primary Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}


Verify System Info Primary Operating System Name After BMC Reboot
    [Documentation]  Verify Primary Operating System Name of System Info Parameter After BMC Reboot via IPMI.
    [Tags]  Verify_System_Info_Primary_Operating_System_Name_After_BMC_Reboot

    # os_version_name given in variable section which is a 14 byte data
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${os_version_name}

    # Set Primary Operating System Name of System Info Parameter
    Set Primary Operating System Name  ${os_name}

    # Get Primary Operating System Name of System Info Parameter
    # Compare with the assigned os version name data
    ${resp}=  Get Primary Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}

    # Cold Reset Via IPMI
    BMC Reboot Via Cold Reset

    # Since Primary Operating System Name is non-volatile,
    # compare with response data of Get Primary Operating System Name
    # with assigned OS version name
    ${resp}=  Get Primary Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}


Verify Get System Info Primary Operating System Name With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter Primary Operating System Name via IPMI invalid Data Request.
    [Tags]  Verify_Get_System_Info_Primary_Operating_System_Name_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 3 - Primary Operating System Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][0]} 0x00


Verify Set System Info Primary Operating System Name With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter Primary Operating System Name via IPMI invalid Data Request.
    [Tags]  Verify_Set_System_Info_Primary_Operating_System_Name_With_Invalid_Data_Request

    # invalid_os_version given in variable section which is a 15 byte data
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    # Here 15 bytes so, data 17 - extra byte
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 3 - Primary Operating System Name throws error for invalid data request
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][0]} ${os_name}


Verify System Info Operating System Name
    [Documentation]  Verify Operating System Name of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_Operating_System_Name

    # os_version_name given in variable section which is a 14 byte data
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${os_version_name}

    # Set Operating System Name of System Info Parameters
    Set Operating System Name  ${os_name}

    # Get the Operating System Name and compare against given os_version_name
    ${resp}=  Get Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}


Verify System Info Operating System Name After BMC Reboot
    [Documentation]  Verify Operating System Name of System Info Parameter After BMC Reboot via IPMI.
    [Tags]  Verify_System_Info_Operating_System_Name_After_BMC_Reboot

    # os_version_name given in variable section which is a 14 byte data
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${os_version_name}

    # Set Operating System Name of System Info Parameters
    Set Operating System Name  ${os_name}

    # Get the Operating System Name and compare against given os_version_name
    ${resp}=  Get Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}

    # Cold Reset via IPMI
    BMC Reboot Via Cold Reset

    # Since Operating System Name is volatile,
    # compare with response data of Get Operating System Name
    # with default Operating System Name
    ${resp}=  Get Operating System Name
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[2:]}  ${default_os_name}


Verify Get System Info Operating System Name With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter Operating System Name via IPMI invalid Data Request.
    [Tags]  Verify_Get_System_Info_Operating_System_Name_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 4 - Operating System Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][0]} 0x00


Verify Set System Info Operating System Name With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter Operating System Name via IPMI invalid Data Request.
    [Tags]  Verify_Set_System_Info_Operating_System_Name_With_Invalid_Data_Request

    # invalid_os_version given in variable section which is a 15 byte data
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    # Here 15 bytes so, data 17 - extra byte
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 4 - Operating System Name throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][0]} ${os_name}


Verify System Info Present OS Version Number
    [Documentation]  Verify Present OS Version Number of System Info Parameter via IPMI.
    [Tags]  Verify_System_Info_Present_OS_Version_Number

    # os_version_name given in variable section which is a 14 byte data
    ${os_name}  ${os_hex_data}=  Identify Request Data  ${os_version_name}

    # Set Present OS Version Number for System Info Parameters
    Set Present OS Version Number  ${os_name}

    # Get Present OS Version Number for System Info Parameters
    # compare with response data of Get Operating System Name
    # with assigned os version name
    ${resp}=  Get Present OS Version Number
    ${resp}=  Split String  ${resp}
    Should Be Equal  ${resp[4:]}  ${os_hex_data}


Verify Get System Info Present OS Version Number With Invalid Data Request
    [Documentation]  Verify Get System Info Parameter Present OS Version Number via IPMI invalid Data Request.
    [Tags]  Verify_Get_System_Info_Present_OS_Version_Number_With_Invalid_Data_Request

    # Check if the Get System Info Parameter for param 5 - Present OS Version Number throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][0]} 0x00


Verify Set System Info Present OS Version Number With Invalid Data Request
    [Documentation]  Verify Set System Info Parameter Present OS Version Number Name via IPMI invalid Data Request.
    [Tags]  Verify_Set_System_Info_Present_OS_Version_Number_With_Invalid_Data_Request

    # invalid_os_version given in variable section which is a 15 byte data
    # The actual request byte should be 16 byte data where,
    # data 1 - Encoding string type
    # data 2 - string length (in bytes, 1-based)
    # data 3 to 16 - system firmware name string data - 14 bytes
    # Here 15 bytes so, data 17 - extra byte
    ${os_name}  ${name_hex_data}=  Identify Request Data  ${invalid_os_version}

    # Check if the Set System Info Parameter for param 5 - Present OS Version Number throws error for invalid request data.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][1]}*
    ...  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][0]} ${os_name}


*** Keywords ***

Identify Request Data
    [Documentation]  Convert text from variable declared to request data.
    [Arguments]  ${ver}

    # Given a string, convert to hexadecimal and prefix with 0x
    ${fw_ver_hex}=  Create List
    ${hex_data}=  Create List
    ${resp_data}=  Split List With Index  ${ver}  1
    FOR  ${data}  IN  @{resp_data}
        # prefixes 0x by default
        ${hex_value}=  Evaluate  hex(ord("${data}"))
        # provides only hexadecimal bytes
        ${hex}=  Evaluate  hex(ord("${data}"))[2:]
        Append To List  ${fw_ver_hex}  ${hex_value}
        Append To List  ${hex_data}  ${hex}
    END
    ${fw_ver_hex}=  Evaluate  " ".join(${fw_ver_hex})

    [Return]  ${fw_ver_hex}  ${hex_data}


Get System Info Set In Progress
    [Documentation]  Get System Info Set In Progress.

    # Get System Info Parameter for param 0 - Set In Progress
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Get'][0]}

    [Return]  ${resp}


Set System Info Set In Progress
    [Documentation]  Set System Info Set In Progress via IPMI.
    [Arguments]  ${state}

    # Set System Info Parameter for param 0 - Set In Progress
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param0_Set_In_Progress']['Set'][0]} ${state}


BMC Reboot Via Cold Reset
    [Documentation]  Execute BMC Reboot Via Cold Reset.

    # Cold Reset via IPMI
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    # Get the BMC Status
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational


Get System Firmware Version
    [Documentation]  Get System Firmware Version for System Info.

    # Get System Info Parameter for param 1 - System Firmware Version
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Get'][0]}

    [Return]  ${resp}


Set System Firmware Version
    [Documentation]  Set System Firmware Version for System Info.
    [Arguments]  ${version}

    # Set System Info Parameter for param 1 - System Firmware Version
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param1_System_Firmware_Version']['Set'][0]} ${version}


Get System Name
    [Documentation]  Get System Name for System Info.

    # Get System Info Parameter for param 2 - System Name
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Get'][0]}

    [Return]  ${resp}


Set System Name
    [Documentation]  Set System Name for System Info.
    [Arguments]  ${sys_name}

    # Set System Info Parameter for param 2 - System Name
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param2_System_Name']['Set'][0]} ${sys_name}


Get Primary Operating System Name
    [Documentation]  Get Primary Operating System Name for System Info.

    # Get System Info Parameter for param 3 - Primary Operating System Name
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Get'][0]}

    [Return]  ${resp}


Set Primary Operating System Name
    [Documentation]  Set Primary Operating System Name for System Info.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 3 - Primary Operating System Name
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param3_Primary_Operating_System_Name']['Set'][0]} ${os_name}


Get Operating System Name
    [Documentation]  Get Operating System Name for System Info.

    # Get System Info Parameter for param 4 - Operating System Name
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Get'][0]}

    [Return]  ${resp}


Set Operating System Name
    [Documentation]  Set Operating System Name for System Info.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 4 - Operating System Name
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param4_Operating_System_Name']['Set'][0]} ${os_name}


Get Present OS Version Number
    [Documentation]  Get Present OS Version Number for System Info.

    # Get System Info Parameter for param 5 - Present OS Version Number
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Get'][0]}

    [Return]  ${resp}


Set Present OS Version Number
    [Documentation]  Set Present OS Version Number for System Info.
    [Arguments]  ${os_name}

    # Set System Info Parameter for param 5 - Present OS Version Number
    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['System_Info']['param5_Present_OS_Version_number']['Set'][0]} ${os_name}


Add Prefix To List Objects And Join String
    [Documentation]  Adding prefix '0x' to each list object and joins the string.
    [Arguments]  ${sys_fw_version}

    # Prefix Bytes with 0x for each data bytes and makes a string of request bytes
    ${sys_fw_version}=  Prefix Bytes  ${sys_fw_version}
    ${sys_fw_version}=  Evaluate  " ".join(${sys_fw_version})

    [Return]  ${sys_fw_version}


Suite Setup Execution
    [Documentation]  Suite Setup Execution.

    # Get Default Values of each parameters
    # Set In Progress - param 0
    ${resp}=  Get System Info Set In Progress
    ${resp}=  Split String  ${resp}
    ${set_in_progress}=  Set Variable  ${resp[1]}

    Set Suite Variable  ${set_in_progress}

    # System Firmware Version - param 1
    ${resp}=  Get System Firmware Version
    ${resp}=  Split String  ${resp}
    ${sys_fw_version}=  Set Variable  ${resp[2:]}
    ${sys_fw_version_string}=  Add Prefix To List Objects And Join String  ${sys_fw_version}

    Set Suite Variable  ${sys_fw_version}
    Set Suite Variable  ${sys_fw_version_string}

    # System Name - param 2
    ${resp}=  Get System Name
    ${resp}=  Split String  ${resp}
    ${sys_name_default}=  Set Variable  ${resp[2:]}
    ${sys_name_hex_default}=  Add Prefix To List Objects And Join String  ${sys_name_default}

    Set Suite Variable  ${sys_name_default}
    Set Suite Variable  ${sys_name_hex_default}

    # Primary Operating System Name - param 3
    ${resp}=  Get Primary Operating System Name
    ${resp}=  Split String  ${resp}
    ${primary_os_name}=  Set Variable  ${resp[2:]}
    ${primary_os_name_hex}=  Add Prefix To List Objects And Join String  ${primary_os_name}

    Set Suite Variable  ${primary_os_name}
    Set Suite Variable  ${primary_os_name_hex}

    # Operating System Name - param 4
    ${resp}=  Get Operating System Name
    ${resp}=  Split String  ${resp}
    ${default_os_name}=  Set Variable  ${resp[2:]}
    ${default_os_name_hex}=  Add Prefix To List Objects And Join String  ${default_os_name}

    Set Suite Variable  ${default_os_name}
    Set Suite Variable  ${default_os_name_hex}

    # Present OS Version Number - param 5
    ${resp}=  Get Present OS Version Number
    ${resp}=  Split String  ${resp}
    ${present_os_num}=  Set Variable  ${resp[2:]}
    ${present_os_num_hex}=  Add Prefix To List Objects And Join String  ${present_os_num}

    Set Suite Variable  ${present_os_num}
    Set Suite Variable  ${present_os_num_hex}


Restore Default Configuration
    [Documentation]  Restore Default configurations.

    # Set In Progress - param 0
    Set System Info Set In Progress  0x${set_in_progress}

    # System Firmware Version - param 1
    Run IPMI Standard Command  raw 0x06 0x58 0x01 0x00 ${sys_fw_version_string}

    # System Name - param 2
    Run IPMI Standard Command  raw 0x06 0x58 0x02 0x00 ${sys_name_hex_default}

    # Primary Operating System Name - param 3
    Run IPMI Standard Command  raw 0x06 0x58 0x03 0x00 ${primary_os_name_hex}

    # Operating System Name - param 4
    Run IPMI Standard Command  raw 0x06 0x58 0x04 0x00 ${default_os_name_hex}

    # Present OS Version Number - param 5
    Run IPMI Standard Command  raw 0x06 0x58 0x05 0x00 ${present_os_num_hex}
