*** Settings ***
Documentation       This suite is for testing general IPMI functions.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../../lib/boot_utils.robot
Resource            ../../lib/utils.robot
Resource            ../../lib/bmc_network_utils.robot
Resource            ../../lib/logging_utils.robot
Library             ../../lib/ipmi_utils.py
Variables           ../../data/ipmi_raw_cmd_table.py
Library             ../../lib/gen_misc.py
Library             ../../lib/gen_robot_valid.py

Test Setup          Log to Console  ${EMPTY}
Test Teardown       FFDC On Test Case Fail

*** Variables ***

${allowed_temp_diff}=  ${1}
${allowed_power_diff}=  ${10}

*** Test Cases ***

Test Watchdog Reset Via IPMI And Verify Using REST
    [Documentation]  Test watchdog reset via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Reset_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Resetting the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog reset

    # Verify the watchdog is reset using REST after an interval of 1000ms.
    Sleep  1000ms
    ${watchdog_time_left}=
    ...  Read Attribute  ${HOST_WATCHDOG_URI}  TimeRemaining
    Should Be True
    ...  ${watchdog_time_left}<${1200000} and ${watchdog_time_left}>${2000}
    ...  msg=Watchdog timer didn't reset.


Test Watchdog Off Via IPMI And Verify Using REST
    [Documentation]  Test watchdog off via IPMI and verify using REST.
    [Tags]  Test_Watchdog_Off_Via_IPMI_And_Verify_Using_REST

    Initiate Host Boot

    Set Watchdog Enabled Using REST  ${1}

    Watchdog Object Should Exist

    # Turn off the watchdog via IPMI.
    Run IPMI Standard Command  mc watchdog off

    # Verify the watchdog is off using REST
    ${watchdog_state}=  Read Attribute  ${HOST_WATCHDOG_URI}  Enabled
    Should Be Equal  ${watchdog_state}  ${0}
    ...  msg=msg=Verification failed for watchdog off check.


Verify Get Device ID
    [Documentation]  Verify get device ID command output.
    [Tags]  Verify_Get_Device_ID

    # Example of get device ID command output:
    # Device ID                 : 0
    # Device Revision           : 0
    # Firmware Revision         : 2.01
    # IPMI Version              : 2.0
    # Manufacturer ID           : 42817
    # Manufacturer Name         : Unknown (0xA741)
    # Product ID                : 16975 (0x424f)
    # Product Name              : Unknown (0x424F)
    # Device Available          : yes
    # Provides Device SDRs      : yes
    # Additional Device Support :
    #     Sensor Device
    #     SEL Device
    #     FRU Inventory Device
    #     Chassis Device
    # Aux Firmware Rev Info     :
    #     0x04
    #     0x38
    #     0x00
    #     0x03

    # Verify Manufacturer and Product IDs, etc. directly from json file.
    ${device_id_config}=  Get Device Id Config
    ${mc_info}=  Get MC Info

    Rprint Vars  device_id_config  mc_info
    Valid Value  ${mc_info['device_id']}  [${device_id_config['id']}]
    Valid Value  ${mc_info['device_revision']}  [${device_id_config['device_revision']}]

    # Get firmware revision from mc info command output i.e. 2.01
    ${ipmi_fw_major_version}  ${ipmi_fw_minor_version}=
    ...  Split String  ${mc_info['firmware_revision']}  .
    # Convert minor firmware version from BCD format to integer. i.e. 01 to 1
    ${ipmi_fw_minor_version}=  Convert To Integer  ${ipmi_fw_minor_version}

    # Get BMC version from BMC CLI i.e. 2.2 from "v2.2-253-g00050f1"
    ${bmc_version_full}=  Get BMC Version
    ${bmc_version}=
    ...  Remove String Using Regexp  ${bmc_version_full}  ^[^0-9]+  [^0-9\.].*

    # Get major and minor version from BMC version i.e. 2 and 1 from 2.1
    @{major_minor_version}=  Split String  ${bmc_version}  .

    Should Be Equal As Strings  ${ipmi_fw_major_version}  ${major_minor_version[0]}
    ...  msg=Major version mismatch.
    Should Be Equal As Strings  ${ipmi_fw_minor_version}  ${major_minor_version[1]}
    ...  msg=Minor version mismatch.

    Valid Value  mc_info['ipmi_version']  ['2.0']

    Valid Value  ${mc_info['manufacturer_id']}  [${device_id_config['manuf_id']}]
    ${product_id_hex} =  Convert To Hex  ${device_id_config['prod_id']}  lowercase=True
    Valid Value  mc_info['product_id']  ['${device_id_config['prod_id']} (0x${product_id_hex})']

    Valid Value  mc_info['device_available']  ['yes']
    Valid Value  mc_info['provides_device_sdrs']  ['yes']
    Should Contain  ${mc_info['additional_device_support']}  Sensor Device
    Should Contain  ${mc_info['additional_device_support']}  SEL Device
    Should Contain
    ...  ${mc_info['additional_device_support']}  FRU Inventory Device
    Should Contain  ${mc_info['additional_device_support']}  Chassis Device

    # Auxiliary revision data verification.
    ${aux_version}=  Get Aux Version  ${bmc_version_full}

    # From aux_firmware_rev_info field ['0x04', '0x38', '0x00', '0x03']
    ${bmc_aux_version}=  Catenate
    ...  SEPARATOR=
    ...  ${mc_info['aux_firmware_rev_info'][0][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][1][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][2][2:]}
    ...  ${mc_info['aux_firmware_rev_info'][3][2:]}

    Should Be Equal As Integers
    ...  ${bmc_aux_version}  ${aux_version}
    ...  msg=BMC aux version ${bmc_aux_version} does not match expected value of ${aux_version}.


Test IPMI Restriction Mode
    [Documentation]  Set restricition mode via REST and verify IPMI operation.
    [Tags]  Test_IPMI_Restriction_Mode
    # Forego normal test setup:
    [Setup]  No Operation
    [Teardown]  Run Keywords  FFDC On Test Case Fail  AND
    ...  Set IPMI Restriction Mode  xyz.openbmc_project.Control.Security.RestrictionMode.Modes.None

    # By default no IPMI operations are restricted.
    # /xyz/openbmc_project/control/host0/restriction_mode/attr/RestrictionMode
    # {
    #    "data": "xyz.openbmc_project.Control.Security.RestrictionMode.Modes.None",
    #    "message": "200 OK",
    #    "status": "ok"
    # }

    # Refer to: #openbmc/phosphor-host-ipmid/blob/master/host-ipmid-whitelist.conf
    # Set the restriction mode to Allowed list IPMI commands only:
    # /xyz/openbmc_project/control/host0/restriction_mode/attr/RestrictionMode
    # {
    #    "data": "xyz.openbmc_project.Control.Security.RestrictionMode.Modes.Whitelist",
    #    "message": "200 OK",
    #    "status": "ok"
    # }

    Set IPMI Restriction Mode  xyz.openbmc_project.Control.Security.RestrictionMode.Modes.Whitelist

    # Attempt allowed listed operation expecting success.
    IPMI Power On

    # Attempt non allowed listed operation expecting failure.
    Run Keyword And Expect Error  *Insufficient privilege level*
    ...  Run Inband IPMI Standard Command  lan set 1 access on


*** Keywords ***

Set Watchdog Enabled Using REST
    [Documentation]  Set watchdog Enabled field using REST.
    [Arguments]  ${value}

    # Description of argument(s):
    # value  Integer value (eg. "0-Disabled", "1-Enabled").

    ${value_dict}=  Create Dictionary  data=${value}
    ${resp}=  OpenBMC Put Request  ${HOST_WATCHDOG_URI}attr/Enabled
    ...  data=${value_dict}


Fetch Details From LAN Print
    [Documentation]  Fetch details from LAN print.
    [Arguments]  ${field_name}

    # Description of argument(s):
    # ${field_name}   Field name to be fetched from LAN print
    #                 (e.g. "MAC Address", "Source").

    ${stdout}=  Run IPMI Standard Command  lan print
    ${fetch_value}=  Get Lines Containing String  ${stdout}  ${field_name}
    ${value_fetch}=  Fetch From Right  ${fetch_value}  :${SPACE}
    [Return]  ${value_fetch}


Set IPMI Restriction Mode
    [Documentation]  Set the IPMI restriction mode.
    [Arguments]  ${restriction_mode}

    # Description of argument(s):
    # restriction_mode   IPMI valid restriction modes.

    ${valueDict}=  Create Dictionary  data=${restriction_mode}

    Write Attribute  ${CONTROL_HOST_URI}restriction_mode/
    ...  RestrictionMode  data=${valueDict}
