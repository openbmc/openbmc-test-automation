*** Settings ***
Documentation  Test IPMI sensor IDs.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/rest_client.robot
Resource               ../lib/openbmc_ffdc.robot
Resource               ../lib/boot_utils.robot
Resource               ../lib/bmc_redfish_resource.robot
Library                ../lib/ipmi_utils.py
Library                ../lib/utilities.py
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

    # Check if delete, partially add, reserve SDR and get SDR alloc info command are supported or not.
    ${support_delete_sdr}=  Fetch IPMI Command Support Status
    ...  ${IPMI_RAW_CMD['SDR']['Delete SDR'][0]}
    ${support_partial_add}=  Fetch IPMI Command Support Status
    ...  ${IPMI_RAW_CMD['SDR']['Partially Add SDR'][0]}
    ${support_reserve_sdr_repository}=  Fetch IPMI Command Support Status
    ...  ${IPMI_RAW_CMD['SDR']['Reserve SDR Repository'][0]}
    ${support_sdr_repository_alloc_info}=  Fetch IPMI Command Support Status
    ...  ${IPMI_RAW_CMD['SDR']['Get SDR allocation Info'][0]}

    ${sdr_info}=  Get SDR Info
    Should Be Equal  ${sdr_info['sdr_version']}  0x51

    # Get sensor count from "sdr elist all" command output.
    ${sensor_count}=  Get Sensor Count
    Should Be Equal As Strings
    ...  ${sdr_info['record_count']}  ${sensor_count}

    Should Be Equal  ${sdr_info['free_space']}  unspecified
    Should Not Be Equal  ${sdr_info['most_recent_addition']}  ${EMPTY}
    Should Not Be Equal  ${sdr_info['most_recent_erase']}  ${EMPTY}
    Should Be Equal  ${sdr_info['sdr_overflow']}  yes
    Should Be Equal  ${sdr_info['sdr_repository_update_support']}  unspecified
    Should Be Equal  ${sdr_info['delete_sdr_supported']}  ${support_delete_sdr}
    Should Be Equal  ${sdr_info['partial_add_sdr_supported']}  ${support_partial_add}
    Should Be Equal  ${sdr_info['reserve_sdr_repository_supported']}  ${support_reserve_sdr_repository}
    Should Be Equal  ${sdr_info['sdr_repository_alloc_info_supported']}  ${support_sdr_repository_alloc_info}


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


Test Reserve SDR Repository
    [Documentation]  Verify Reserve SDR Repository IPMI command.
    [Tags]  Test_Reserve_SDR_Repository

    ${reservation_id}=  Get Reservation ID  convert_lsb_to_msb=True

    # Getting another Reservation ID and verify it is different from previous Reservation ID.
    ${new_reservation_id}=  Get Reservation ID  convert_lsb_to_msb=True

    Should Not Be Equal  ${reservation_id}  ${new_reservation_id}
    ...  msg=Getting same reservation ID for second time, reservation ID must be different.


Test Get SDR Using Reservation ID
   [Documentation]  Verify get SDR command using reservation ID obtained from Reserve SDR repository.
   [Tags]  Test_Get_SDR_Using_Reservation_ID

   ${reservation_id}=  Get Reservation ID  add_prefix=True

   # Get SDR full without using Reservation ID.
   Run External IPMI Raw Command  ${IPMI_RAW_CMD['SDR']['Get'][0]}

   # Get SDR Partially using Reservation ID.
   ${get_sdr_raw_cmd}=  Catenate
   ...  ${IPMI_RAW_CMD['Get SDR']['Get'][1]} ${reservation_id} 0x${record_id} 0x00
   ...  ${IPMI_RAW_CMD['Get SDR']['Get'][2]}
   Run External IPMI Raw Command  ${get_sdr_raw_cmd}

   # Get SDR partially without using reservation ID and expect error.
   Verify Invalid IPMI Command  ${IPMI_RAW_CMD['SDR']['Get'][3]}  0xc5


Test Get SDR Using Invalid Reservation ID
    [Documentation]  Verify get SDR command using invalid reservation ID.
    [Tags]  Test_Get_SDR_Using_Invalid_Reservation_ID

    # Generate two reservation ID and verify get SDR partial using old reservation ID.
    ${first_reservation_id}=  Get Reservation ID  add_prefix=True
    ${second_reservation_id}=  Get Reservation ID  add_prefix=True

    # Creating the raw cmd with First reservation ID.
    ${get_sdr_raw_cmd}=  Catenate
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][1]} ${first_reservation_id} 0x${record_id} 0x00
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][2]}


Test Reserve SDR Repository After BMC Reboot
    [Documentation]  Verify reserve SDR repository reservation ID after BMC Reboot.
    [Tags]  Test_Reserve_SDR_Repository_After_BMC_Reboot

    #  Get Reservation ID before reboot.
    ${reservation_id_before_reboot}=  Get Reservation ID  add_prefix=True

    # Cold reset BMC
    IPMI MC Reset Cold (run)

    # Waiting to for sdr to populate.
    Sleep  10s

    # Create Get SDR Partially command using reservation ID which got before reboot.
    ${get_sdr_raw_cmd}=  Catenate
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][1]} ${reservation_id_before_reboot} 0x${record_id} 0x00
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][2]}

    Verify Invalid IPMI Command  ${get_sdr_raw_cmd}  0xc5

    #  Verify get SDR partially with new reservation ID after reboot.
    ${reservation_id_after_reboot}=  Get Reservation ID  add_prefix=True
    ${get_sdr_raw_cmd}=  Catenate
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][1]} ${reservation_id_after_reboot} 0x${record_id} 0x00
    ...  ${IPMI_RAW_CMD['Get SDR']['Get'][2]}
    Run External IPMI Raw Command  ${get_sdr_raw_cmd}


*** Keywords ***

Get Reservation ID
    [Documentation]  Get reservation ID using reserve SDR repository.
    [Arguments]  ${add_prefix}=False  ${convert_lsb_to_msb}=False

    # Description of argument(s):
    # add_prefix             If True will prefix "0x" to the reservation ID.
    #                        e.g. IPMI response for Reservation ID command will be  like 01 00
    #                        return reservation ID will be "0x01" for above response.

    # convert_lsb_to_msb     If True will convert the reservation ID from LSB first to MSB first.
    #                        e.g. IPMI response for reservation ID command will be like  01 0a
    #                        return reservation ID will be "a1" for above response.

    ${reservation_id}=  Run External IPMI Raw Command
    ...  ${IPMI_RAW_CMD['SDR']['Reserve SDR Repository'][0]}

    ${reservation_id}=  Run Keyword If  ${add_prefix}
    ...  Add Prefix To String  ${reservation_id}  0x
    ...  ELSE IF  ${convert_lsb_to_msb}
    ...  Convert LSB To MSB  ${reservation_id}
    ...  ELSE
    ...  Return From Keyword  ${reservation_id}

    [Return]  ${reservation_id}


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

Fetch IPMI Command Support Status
    [Documentation]  Return yes if IPMI command is supported.
    [Arguments]  ${ipmi_cmd}

    # Description of argument(s):
    # ipmi_cmd    IPMI command.

    ${resp}=  Run External IPMI Raw Command  ${ipmi_cmd}  fail_on_err=0
    ${resp_code_match}=  Get Regexp Matches  ${resp}  rsp=0xc1

    ${cmd_support}=  Set Variable If  ${resp_code_match} != []  no  yes

    [Return]  ${cmd_support}


Get SDR Record ID
    [Documentation]  Fetch one record ID from SDR elist IPMI cmd response.

    ${resp}=  Run External IPMI Standard Command  sdr elist
    ${record_id}=  Get Regexp Matches  ${resp}  \\|\\s+([0-9]+)h\\s+\\|  1

    [Return]  ${record_id[0]}


Suite Setup Execution
    [Documentation]  Do the initial suite setup.

    Redfish.Login
    Redfish Power On  stack_mode=skip  quiet=1

    ${record_id}=  Get SDR Record ID
    Set Suite Variable  ${record_id}

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
