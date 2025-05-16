*** Settings ***
Documentation  This module provides general keywords for date time and ntp.

Resource                     ../../lib/resource.robot
Resource                     ../../lib/bmc_redfish_resource.robot
Resource                     ../../lib/common_utils.robot
Resource                     ../../lib/openbmc_ffdc.robot
Resource                     ../../lib/utils.robot
Resource                     ../../lib/rest_client.robot
Library                      ../../lib/gen_robot_valid.py

*** Variables ***

${year_without_ntp}          1970

*** Keywords ***


Redfish Get DateTime
    [Documentation]  Returns BMC Datetime value from Redfish.

    ${date_time}=  Redfish.Get Attribute  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}  DateTime
    RETURN  ${date_time}


Redfish Set DateTime
    [Documentation]  Set DateTime using Redfish.
    [Arguments]  ${date_time}=${EMPTY}  ${request_type}=valid
    # Description of argument(s):
    # date_time                     New time to set for BMC (eg.
    #                               "2019-06-30 09:21:28"). If this value is
    #                               empty, it will be set to the UTC current
    #                               date time of the local system.
    # request_type                  By default user request is valid.
    #                               User can pass invalid to identify the user
    #                               date time input will result in failure as
    #                               expected.

    # Assign default value of UTC current date time if date_time is empty.
    ${current_date_time}=  Get Current Date  time_zone=UTC
    ${date_time}=  Set Variable If  '${date_time}' == '${EMPTY}'
    ...  ${current_date_time}  ${date_time}

    # Patch date_time based on type of ${request_type}.
    IF  '${request_type}' == 'valid'
        ${date_time}=  Convert Date  ${date_time}  result_format=%Y-%m-%dT%H:%M:%S+00:00
        Wait Until Keyword Succeeds  1min  5sec
        ...  Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}
        ...  body={'DateTime': '${date_time}'}
        ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
    ELSE
        Wait Until Keyword Succeeds  1min  5sec
        ...  Redfish.Patch  ${REDFISH_BASE_URI}Managers/${MANAGER_ID}
        ...  body={'DateTime': '${date_time}'}
        ...  valid_status_codes=[${HTTP_BAD_REQUEST}]
    END


Set Time To Manual Mode
    [Documentation]  Set date time to manual mode via Redfish.

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${False}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Set BMC Date And Verify
    [Documentation]  Set BMC Date Time at a given host state and verify.
    [Arguments]  ${host_state}
    # Description of argument(s):
    # host_state  Host state at which date time will be updated for verification
    #             (eg. on, off).

    IF  '${host_state}' == 'on'
        Redfish Power On  stack_mode=skip
    ELSE
        Redfish Power off  stack_mode=skip
    END

    ${current_date}=  Get Current Date  time_zone=UTC
    ${new_value}=  Subtract Time From Date  ${current_date}  1 day
    Redfish Set DateTime  ${new_value}
    ${current_value}=  Redfish Get DateTime
    ${time_diff}=  Subtract Date From Date  ${current_value}  ${new_value}
    Should Be True  '${time_diff}'<='3'


Set NTP state
    [Documentation]  Set NTP service inactive.
    [Arguments]  ${state}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'ProtocolEnabled': ${state}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]


Get NTP Initial Status
    [Documentation]  Get NTP service Status.

    ${original_ntp}=  Redfish.Get Attribute  ${REDFISH_NW_PROTOCOL_URI}  NTP
    Set Suite Variable  ${original_ntp}


Restore NTP Status
    [Documentation]  Restore NTP Status.

    IF  '${original_ntp["ProtocolEnabled"]}' == 'True'
        Set NTP state  ${TRUE}
    ELSE
        Set NTP state  ${FALSE}
    END


Verify NTP Servers Are Populated
    [Documentation]  Redfish GET request /redfish/v1/Managers/${MANAGER_ID}/NetworkProtocol response
    ...              and verify if NTP servers are populated.

    ${network_protocol}=  Redfish.Get Properties  ${REDFISH_NW_PROTOCOL_URI}
    Should Contain  ${network_protocol["NTP"]["NTPServers"]}  ${ntp_server_1}
    ...  msg=NTP server value ${ntp_server_1} not stored.
    Should Contain  ${network_protocol["NTP"]["NTPServers"]}  ${ntp_server_2}
    ...  msg=NTP server value ${ntp_server_2} not stored.


Verify System Time Sync Status
    [Documentation]  Verify the status of service systemd-timesyncd matches the NTP protocol enabled state.
    [Arguments]  ${expected_sync_status}=${True}

    # Description of argument(s):
    # expected_sync_status  expected status at which NTP protocol enabled will be updated for verification
    #                       (eg. True, False).

    ${resp}=  BMC Execute Command
    ...  systemctl status systemd-timesyncd
    ...  ignore_err=${1}
    ${sync_status}=  Get Lines Matching Regexp  ${resp[0]}  .*Active.*
    IF  ${expected_sync_status}==${True}
        Should Contain  ${sync_status}  active (running)
    END
    IF  ${expected_sync_status}==${False}
        Should Contain  ${sync_status}  inactive (dead)
    END


Enable NTP And Add NTP Address
    [Documentation]  Enable NTP Protocol and Add NTP Address.

    Set NTP state  ${TRUE}

    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}  body={'NTP':{'NTPServers': ${NTP_SERVER_ADDRESSES}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]

    Wait Until Keyword Succeeds  1 min  10 sec  Check Date And Time Was Changed


Check Date And Time Was Changed
    [Documentation]  Verify date was current date and time.

    ${new_date_time}=  CLI Get BMC DateTime
    Should Not Contain  ${new_date_time}  ${year_without_ntp}


Restore NTP Mode
    [Documentation]  Restore the original NTP mode.

    Return From Keyword If  &{original_ntp} == &{EMPTY}
    Print Timen  Restore NTP Mode.
    Redfish.Patch  ${REDFISH_NW_PROTOCOL_URI}
    ...  body={'NTP':{'ProtocolEnabled': ${original_ntp["ProtocolEnabled"]}}}
    ...  valid_status_codes=[${HTTP_OK}, ${HTTP_NO_CONTENT}]
