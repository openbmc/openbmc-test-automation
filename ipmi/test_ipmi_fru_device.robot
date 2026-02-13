*** Settings ***
Documentation  Test IPMI FRU data.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/bmc_dbus.robot
Variables              ../data/ipmi_raw_cmd_table.py
Library                ../lib/ipmi_utils.py

Test Tags              IPMI_FRU_Device

*** Variables ***

${FRU_NAME}                  dimm01 dimm02 cpu0 cpu1  motherboard
${BUSCTL_FRU}                xyz.openbmc_project.FruDevice
${FRU_DBUS_URL}              /xyz/openbmc_project/FruDevice
${fru_device_id}             0x00
${fru_device_id_invalid}     0xff
${read_write_offset}         0x00 0x00
&{dbus_dict}
&{ipmi_dbus_name_mapping}    Chassis Part Number=.CHASSIS_PART_NUMBER
...  Board Mfg Date=.BOARD_MANUFACTURE_DATE  Board Mfg=.BOARD_MANUFACTURER
...  Board Product=.BOARD_PRODUCT_NAME  Board Serial=.BOARD_SERIAL_NUMBER
...  Board Part Number=.BOARD_PART_NUMBER  Product Manufacturer=.PRODUCT_MANUFACTURER
...  Product Name=.PRODUCT_PRODUCT_NAME  Product Part Number=.PRODUCT_PART_NUMBER
...  Product Version=.PRODUCT_VERSION  Product Serial=.PRODUCT_SERIAL_NUMBER

*** Test Cases ***
Test FRU Device Name
    [Documentation]  Search FRU for device name
    [Tags]  Test_FRU_Device_Name

    ${output}=  Run IPMI Standard Command  fru
    Should Contain  ${output}  ${FRU_NAME}  msg=Fail: Given FRU device ${FRU_NAME} not found


Verify Fru Device Configuration
    [Documentation]  Read the FRU device configuration of each device
    ...  and compare with DBUS data.
    [Tags]  Verify_Fru_Device_Configuration

    # IPMI FRU print.
    ${ipmi_output}=  Run IPMI Standard Command  fru

    # Create dictionary with FRU device serial number as key and details as value from IPMI.
    ${ipmi_fru}=  Get IPMI FRU Devices Data  ${ipmi_output}

    # Returns all the available FRU dbus uri.
    ${dbus_fru_uri}=  Get DBUS URI List From BMC  ${BUSCTL_FRU}  ${FRU_DBUS_URL}

    # Returns all the FRU device uri with special characters removed.
    ${dbus_fru_uri_list}=  Fetch DBUS URI List Without Unicode  ${dbus_fru_uri}

    # Creates dictionary with serial number as key, and corresponding FRU device uri as value from dbus.
    Get DBUS Dictionary For FRU Devices  ${dbus_fru_uri_list}  ${ipmi_fru}

    # Compare dbus dictionary each field, with IPMI FRU device fields for each FRU device.
    Compare IPMI FRU With DBUS  ${ipmi_fru}


Verify Get FRU Inventory Area Info
    [Documentation]  Verify IPMI get FRU inventory area info command.
    [Tags]  Verify_Get_FRU_Inventory_Area_Info

    # IPMI read FRU data command.
    ${resp}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    ${bytes_read}=  Set Variable  ${resp.split()[0]}

    # IPMI get FRU inventory area info command.
    ${bytes_inventory}=  Get FRU Inventory Area Info

    # Compare read FRU data Count returned -- count is ‘1’ based, with inventory area count.
    Should Be Equal  ${bytes_inventory}  ${bytes_read}


Verify Get FRU Inventory Area Info For Invalid Device Data
    [Documentation]  Verify IPMI get FRU inventory area info command for Invalid Device Data.
    [Tags]  Verify_Get_FRU_Inventory_Area_Info_For_Invalid_Device_Data

    # Verify response for invalid FRU device id.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['FRU']['Inventory_Area_Info'][1]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['FRU']['Inventory_Area_Info'][0]} ${fru_device_id_invalid}


Verify Get FRU Inventory Area Info For Invalid Data Request
    [Documentation]  Verify IPMI get FRU inventory area info command for Invalid Data Request.
    [Tags]  Verify_Get_FRU_Inventory_Area_Info_For_Invalid_Data_Request

    # Verify response for invalid response data - extra bytes.
    Run Keyword and Expect Error  *${IPMI_RAW_CMD['FRU']['Inventory_Area_Info'][2]}*
    ...  Run IPMI Command  ${IPMI_RAW_CMD['FRU']['Inventory_Area_Info'][0]} ${fru_device_id} 0x00


Verify IPMI Write FRU Data
    [Documentation]  Verify write data in FRU and compare data from read FRU data command via IPMI.
    [Tags]  Verify_IPMI_Write_FRU_Data
    [Setup]  Get Default FRU Data
    [Teardown]  Restore Default FRU Data

    # Generate random data to write in FRU device.
    ${write_data_prefixed}  ${write_data}=  Generate Random Data For FRU

    # Get the length of the data generated and convert to hex.
    ${write_data_length}=  Get Length  ${write_data}
    ${write_data_length}=  Convert To Hex  ${write_data_length}  lowercase=yes

    # Write the data to FRU device.
    Write FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}  ${write_data_prefixed}  ${write_data_length}

    # Read the FRU data.
    ${resp}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    ${resp_data}=  Set Variable  ${resp.split()[1:]}

    # Verify if the data written and read are same.
    Should Be Equal  ${write_data}  ${resp_data}


Verify IPMI Write FRU Data With BMC Reboot
    [Documentation]  Verify IPMI write data in FRU and compare data from read FRU data command after BMC reboot.
    [Tags]  Verify_IPMI_Write_FRU_Data_With_BMC_Reboot
    [Setup]  Get Default FRU Data
    [Teardown]  Restore Default FRU Data

    # Generate random data to write in FRU device.
    ${write_data_prefixed}  ${write_data}=  Generate Random Data For FRU

    # Get the length of the data generated and convert to hex.
    ${write_data_length}=  Get Length  ${write_data}
    ${write_data_length}=  Convert To Hex  ${write_data_length}  lowercase=yes

    # Write the data to FRU device.
    Write FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}  ${write_data_prefixed}  ${write_data_length}

    # Read the FRU data.
    ${resp}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    ${resp_data}=  Set Variable  ${resp.split()[1:]}

    # Verify if the data written and read are same.
    Should Be Equal  ${write_data}  ${resp_data}

    # Reboot BMC and verify if the data written and read are same.
    IPMI MC Reset Cold (run)
    ${resp}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    Should Not Be Equal  ${resp}  ${initial_fru_data}
    Should Be Equal  ${resp[1:]}  ${write_data}


*** Keywords ***

Get IPMI FRU Devices Data
    [Documentation]  Get response from IPMI FRU command and format data
    ...  with Board or Product serial as key and corresponding data as value.
    [Arguments]  ${ipmi_output}

    # Description of Argument(s):
    # ipmi_output        All the FRU devices listed in IPMI FRU command.

    # Get the FRU list and return as a dictionary with serial number as key.
    # Example:
    # fru_data = {
    # "123456789012345XYZ":
    #  {
    #     FRU Device Description : Builtin FRU Device (ID 0),
    #     Chassis Type          : Rack Mount Chassis,
    #     Chassis Part Number   : xxx-xxxxx-xxxx-xxx,
    #     Board Mfg Date        : Fri Oct 16 06:34:00 2020 UTC,
    #     Board Mfg             : XXXXX,
    #     Board Product         : XXXXX,
    #     Board Serial          : 123456789012345XYZ,
    #     Board Part Number     : xxx.xxxxx.xxxx
    #     Board Extra           : 01
    #     Product Manufacturer  : XXXXX
    #     Product Name          : XXXXX
    #     Product Part Number   : xxx-xxxx-xxxx-xxx
    #     Product Version       : v1.0
    #     Product Serial        : 1234567890XYZ
    #  },....}

    # Gets response from FRU data and split each device.
    ${output}=  Set Variable  ${ipmi_output.strip("\n")}
    ${output}=  Split String  ${output}  \n\n
    &{fru}=  Create Dictionary
    ${num}=  Set Variable  0

    # For each device, identify either Board Serial/Product Serial (whichever is available).
    FOR  ${devices}  IN  @{output}
        &{tmp}=  Create Dictionary
        ${dev}=  Split String  ${devices}  \n
        FOR  ${device}  IN  @{dev}
            ${ipmi_fru_board_serial_status}=  Run Keyword And Return Status  Should Contain  ${device}  Board Serial
            IF  '${ipmi_fru_board_serial_status}' == 'True'  BREAK
        END
        ${frudata}=  Get From List  ${output}  ${num}

        ${serial_str}=  Set Variable If  '${ipmi_fru_board_serial_status}' == 'True'
        ...  Board Serial  Product Serial

        ${serial_no}=  Get Lines Containing String  ${frudata}  ${serial_str}

        # Get each device and split field as key and value and append to a dictionary.
        ${serial_nos}=  Set Variable  ${serial_no.strip()}
        ${data}=  Split String  ${serial_nos}  :
        ${serial_number}=  Get From List  ${data}  1
        ${num}=  Evaluate  int(${num}) + 1
        FOR  ${entry}  IN  @{dev}
            ${entry}=  Split String  ${entry}  ${SPACE}:${SPACE}
            ${entry1}=  Set Variable  ${entry[0].strip()}
            ${entry2}=  Set Variable  ${entry[1].strip()}
            Set To Dictionary  ${tmp}  ${entry1}  ${entry2}
        END
        ${serial_number}=  Set Variable  ${serial_number.strip()}
        # Assign serial number as key for main dictionary and a each device detail as value.
        Set To Dictionary  ${fru}  ${serial_number}  ${tmp}
    END

    RETURN  ${fru}


Get DBUS Dictionary For FRU Devices
    [Documentation]  Provides the dictionary of DBUS FRU devices from DBUS FRU.
    [Arguments]  ${dbus_fru}  ${ipmi_fru}

    # Description of Argument(s):
    # dbus_fru    FRU dbus uri list.
    # ipmi_fru    IPMI FRU details.

    # Execute DBUS Introspect Command for each device,
    # Appends dictionary with serial number as key and FRU dbus uri as value,
    # if the IPMI FRU key matches the serial number of each device dbus response.
    # Example :
    #    ${dbus_output} = { "123456789012345XYZ" : "xyz.openbmc_project.FruDevice/xyz/openbmc_project/FruDevice/Device_0" }
    FOR  ${fru}  IN  @{dbus_fru}
        ${cmd}=  Catenate  ${BUSCTL_FRU} ${fru}
        ${dbus_output}=  Execute DBUS Introspect Command  ${cmd}
        ${dbus_fru_board_serial_status}=  Run Keyword And Return Status  Should Contain  ${dbus_output}  .BOARD_SERIAL
        ${dbus_fru_product_serial_status}=  Run Keyword And Return Status  Should Contain  ${dbus_output}  .PRODUCT_SERIAL
        IF  '${dbus_fru_board_serial_status}' == 'True' or '${dbus_fru_product_serial_status}' == 'True'
            Create Dictionary For DBUS URI  ${dbus_output}  ${ipmi_fru}  ${dbus_fru_board_serial_status}  ${cmd}
        END
    END


Create Dictionary For DBUS URI
    [Documentation]  Create Dictionary For DBUS URI
    [Arguments]  ${dbus_output}  ${ipmi_fru}  ${dbus_fru_board_serial_status}  ${fru_command}

    # Description of Argument(s):
    # dbus_output                             Dbus response got from BMC console.
    # ipmi_fru                                IPMI FRU details.
    # dbus_fru_board_serial_status            FRU devices may have either BOARD_SERIAL or PRODUCT_SERIAL
    # ...                                     if status was true value of BOARD_SERIAL will be taken for dictionary as an key
    # ...                                     otherwise value of PRODUCT_SERIAL will be taken as an key for dictionary.
    # fru_command                             FRU command to map into dictionary as value.

    # Validates the IPMI FRU dictionary key with dbus uri response serial number.
    # If matches then, sets the serial number as key and FRU uri as value.
    # ${dbus_dict} defined under variable section.
    FOR  ${ipmi_fru_serial_no}  IN  @{ipmi_fru.keys()}
        ${serial_str}=  Set Variable If  '${ipmi_fru_board_serial_status}' == 'True'
        ...  Board Serial  Product Serial

        ${serial_no}=  Get Lines Containing String  ${frudata}  ${serial_str}

        ${serial_no}=  Split String  ${serial_no}  "
        ${dbus_serial_no}=  Set Variable  ${serial_no[1].strip()}
        ${serial_no_status}=  Run Keyword And Return Status  Should Be Equal As Strings
        ...  ${ipmi_fru_serial_no}  ${dbus_serial_no}

        IF  '${serial_no_status}' == 'True'
            Set To Dictionary  ${dbus_dict}  ${dbus_serial_no}  ${fru_command}
            BREAK
        END
    END


Compare IPMI FRU With DBUS
    [Documentation]  Compare the IPMI FRU dictionary values with DBUS dictionary values,
    ...  if the serial number is present in both FRU and dbus dictionaries.
    [Arguments]  ${ipmi_fru}

   # Description of Argument(s):
   # ipmi_fru    IPMI FRU device details.

    # With each IPMI FRU key, get the corresponding valid from dbus dictionary,
    # Execute the value which is dbus uri and,
    # validate each dbus field value with IPMI FRU field value.
    # Values are validated for keys present in the ipmi_dbus_name_mapping dictionary.
    # Example :
    #    IPMI FRU field :
    #             Board Part Number     : 111.22222.0000
    #    DBUS FRU field :
    #            .BOARD_PART_NUMBER      property  s     "111.22222.0000"        emits-change
    FOR  ${key}  ${ipmi_fru_value}  IN  &{ipmi_fru}
        ${dbus_resp}=  Execute DBUS Introspect Command  ${dbus_dict}[${key}]
        ${ipmi_fru_subkeys}=  Get Dictionary Keys  ${ipmi_fru_value}
        FOR  ${subkeys}  IN  @{ipmi_fru_subkeys}
            ${key_status}=  Run Keyword And Return Status  Dictionary Should Contain Key
            ...  ${ipmi_dbus_name_mapping}  ${subkeys}
            IF  '${key_status}' == 'False'  CONTINUE
            ${property_name}=  Get From Dictionary  ${ipmi_dbus_name_mapping}  ${subkeys}
            ${dbus_data}=  Get Lines Containing String  ${dbus_resp}  ${property_name}
            ${dbus_value}=  Set Variable  ${dbus_data.split('"')[1].strip()}
            ${ipmi_response}=  Get From Dictionary  ${ipmi_fru_value}  ${subkeys}
            ${status}=  Run Keyword And Return Status  Should Contain  ${property_name}  DATE
            IF  ${status}
                # If the required IPMI field has date field, the IPMI FRU value is converted to
                # format = %Y-%m-%d - %H:%M:%S and validated against dbus FRU data.
                ${ipmi_date}=  Convert Date  ${ipmi_response}  date_format=%a %b %d %H:%M:%S %Y
                ...  result_format=%Y-%m-%d - %H:%M:%S
                Run Keyword And Continue On Failure  Should Be Equal As Strings  ${ipmi_date}  ${dbus_value}
                ...  message=${property_name} Property value mismatch with IPMI and DBUS
            ELSE
                Run Keyword And Continue On Failure  Should Be Equal As Strings  ${ipmi_response}  ${dbus_value}
                ...  message=${property_name} Property value mismatch with IPMI and DBUS
            END
        END
    END


Get FRU Inventory Area Info
    [Documentation]  IPMI Get FRU Inventory Area Info and returns FRU Inventory area size in bytes.

    ${resp}=  Run IPMI Command  ${IPMI_RAW_CMD['FRU']['Inventory_Area_Info'][0]} ${fru_device_id}
    ${resp}=  Split String  ${resp}

    RETURN  ${resp[0]}


Read FRU Data Via IPMI
    [Documentation]  Read FRU data using IPMI raw command.
    [Arguments]  ${fru_id}  ${offset}

    # Description of Argument(s):
    # fru_id        FRU id.
    # offset        Offset byte for read FRU command.

    # IPMI Read FRU Data Command.
    # 0xff - Count to read --- count is ‘1’ based
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['FRU']['Read'][0]} ${fru_id} ${offset} 0xff

    RETURN  ${resp}


Write FRU Data Via IPMI
    [Documentation]  Write FRU data using IPMI raw command.
    [Arguments]  ${fru_id}  ${offset}  ${data}  ${length}

    # Description of Argument(s):
    # fru_id        FRU id.
    # offset        Offset byte for read FRU command.
    # data          Data to write for write FRU command.
    # length        Count of bytes that gets written in write FRU command.

    # IPMI Write FRU Data Command.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['FRU']['Write'][0]} ${fru_id} ${offset} ${data}

    Should Be Equal As Strings  ${resp}  ${length}


Generate Random Data For FRU
    [Documentation]  Generate random data for write in FRU.

    # Description:
    #  Generates string of bytes and convert to hexadecimal data.
    #  Gets the length of initial FRU data read with IPMI read FRU device command.

    # ${frudata_prefixed}    string with bytes prefixed 0x by default
    # ${fru_data}            string with only hexadecimal bytes without prefix

    ${string}=  Generate Random String  ${initial_fru_length}  [LETTERS]
    ${frudata_prefixed}  ${fru_data}=  Identify Request Data  ${string}

    RETURN  ${frudata_prefixed}  ${fru_data}


Get Default FRU Data
    [Documentation]  Get default data via read FRU data IPMI command.

    # Read the default FRU device data.
    # split the response and identify length of Requested data.
    ${initial_fru_data}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    ${initial_fru_list}=  Split String  ${initial_fru_data}
    ${initial_fru_list}=  Set Variable  ${initial_fru_list[1:]}
    ${initial_fru_length}=  Get Length  ${initial_fru_list}
    Set Test Variable  ${initial_fru_data}
    Set Test Variable  ${initial_fru_list}
    Set Test Variable  ${initial_fru_length}


Restore Default FRU Data
    [Documentation]  Restore default FRU data.

    # Prefix 0x to initial request data.
    ${fru_list}=  Prefix Bytes  ${initial_fru_list}
    ${fru_byte}=  Evaluate  " ".join(${fru_list})
    ${initial_frulength_hex}=  Convert To Hex  ${initial_fru_length}  lowercase=yes
    # Write the initial FRU data to restore.
    Write FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}  ${fru_byte}  ${initial_frulength_hex}
    # Verify whether initial FRU data is restored.
    ${fru_data}=  Read FRU Data Via IPMI  ${fru_device_id}  ${read_write_offset}
    Should Be Equal  ${fru_data}  ${initial_fru_data}
