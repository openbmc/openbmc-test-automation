*** Settings ***
Documentation        Test to discover the BMC. Before running suit,
...                  check BMC and Avahi browse machine should be in same subnet.

Variables            ../../data/variables.py
Library              SSHLibrary
Library              ../../lib/external_intf/management_console_utils.py
Library              ../../lib/gen_robot_print.py
Library              ../../lib/gen_print.py
Library              ../../lib/gen_misc.py
Resource             ../../lib/external_intf/management_console_utils.robot
Resource             ../../lib/redfish_code_update_utils.robot
Resource             ../../lib/boot_utils.robot
Resource             ../../syslib/utils_os.robot
Resource             ../../lib/code_update_utils.robot

Suite Setup          Suite Setup Execution
Suite Teardown       Redfish.Logout
Test Setup           Printn
Test Teardown        FFDC On Test Case Fail

*** Test Cases ***

Discover BMC With Different Service Type
    [Documentation]  Discover all the BMC with different service type support.
    [Tags]  Discover_BMC_With_Different_Service_Type
    [Template]  Discover BMC With Service Type

    # Service type
    _obmc_rest._tcp
    _obmc_redfish._tcp


Discover BMC Pre And Post Reboot
    [Documentation]  Discover BMC before and after reboot.
    [Tags]  Discover_BMC_Pre_And_Post_Reboot
    [Template]  Set Daemon And Discover BMC After Reboot

    # Service type
    _obmc_rest._tcp
    _obmc_redfish._tcp


Disable AvahiDaemon And Discover BMC After Reboot
    [Documentation]  BMC should be discoverable in next reboot even after disabling Avahi daemon.
    [Tags]  Disable_AvahiDaemon_And_Discover_BMC_After_Reboot
    [Template]  Set Daemon And Discover BMC After Reboot

    # Service type       skip
    _obmc_rest._tcp      True
    _obmc_redfish._tcp   True


Discover BMC Pre And Post Firmware Update Of Same Release
    [Documentation]  Discover BMC, when firmware update occurs for same release.
    [Tags]  Discover_BMC_Pre_And_Post_Firmware_Update_Of_Same_Release
    [Template]  Discover BMC Pre And Post Firmware Update

    # Service type   Service type        status
    _obmc_rest._tcp  _obmc_redfish._tcp  True


Discover BMC Pre And Post Firmware Update Of Different Release
    [Documentation]  Discover BMC, when firmware update occurs for different release.
    [Tags]  Discover_BMC_Pre_And_Post_Firmware_Update_Of_Different_Release
    [Template]  Discover BMC Pre And Post Firmware Update

    # Service type   Service type        status
    _obmc_rest._tcp  _obmc_redfish._tcp  True


Discover BMC Fail After Firmware Update Of Different Release
    [Documentation]  Discover BMC fail, when firmware update occurs for different release.
    [Tags]  Discover_BMC_Fail_After_Firmware_Update_Of_Different_Release
    [Template]  Discover BMC Pre And Post Firmware Update

    # Service type   Service type        status
    _obmc_rest._tcp  _obmc_redfish._tcp  False


Discover BMC Pre And Post When Host Boot InProgress
    [Documentation]  Discover BMC, when Host boot in progress.
    [Tags]  Discover_BMC_Pre_And_Post_When_Host_Boot_InProgress
    [Template]  Discover BMC Pre And Post When Host Boot

    # Service type   Service type
    _obmc_rest._tcp  _obmc_redfish._tcp

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${AVAHI_CLIENT}
    Should Not Be Empty  ${AVAHI_CLIENT_USERNAME}
    Should Not Be Empty  ${AVAHI_CLIENT_PASSWORD}
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    Check Avahi Package
    Redfish.Login


Check Avahi Package
    [Documentation]  To check for avahi-tools package.

    # Expected command output as below.
    # avahi-tools-0.6.31-19.el7.x86_64

    ${command}=  Set Variable  rpm -qa | grep avahi-tools
    ${resp_rpm}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${resp_rpm}  avahi-tools  ignore_case=True  msg=avahi-tools is not available.


Discover BMC With Service Type
    [Documentation]  To get the discoverd BMC list.
    [Arguments]  ${service_type}

    # Description of argument(s):
    # service_type  BMC service type e.g.
    #               (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

    # bmc_list:
    # [1]:
    #    [service]:          _obmc_XXXX._tcp
    #    [hostname]:         System Name
    #    [address]:          XXX.XXX.XXX.XXX
    #    [port]:             XXX
    #    [txt]:
    # [2]:
    #    [service]:          _obmc_XXXX._tcp
    #    [hostname]:         System Name
    #    [address]:          XXX.XXX.XXX.XXX
    #    [port]:             XXX
    #    [txt]:

    ${resp_service}  ${stderr}=  Execute Command  avahi-browse -rt ${service_type}  return_stderr=True
    ${bmc_list}  ${exc_msg}=  Get BMC Records  ${service_type}  ${resp_service}
    Print Timen  Exception message is ${exc_msg}
    Should Not Be Empty  ${bmc_list}
    Rprint Vars  bmc_list
    [Return]  ${bmc_list}


Verify Existence Of BMC Record From List
    [Documentation]  Verify the existence of BMC record from list of BMC records.
    [Arguments]  ${service_type}

    # Description of argument(s):
    # service_type  BMC service type e.g.
    #               (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

    ${bmc_list}=  Discover BMC With Service Type  ${service_type}
    ${openbmc_host_name}  ${openbmc_ip}=  Get Host Name IP  host=${OPENBMC_HOST}
    ${resp}=  Check BMC Record Exists  ${bmc_list}  ${openbmc_ip}
    Should Be True  'True' == '${resp}'


Set Daemon And Discover BMC After Reboot
    [Documentation]  Discover BMC After reboot.
    [Arguments]  ${service_type}  ${skip}=False

    # Description of argument(s):
    # service_type  BMC service type e.g.
    #               (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).
    # skip          Default value set to False.
    #               If the value is True, Disable the AvahiDaemon.
    #               If the value is False, skip the step to disable the AvahiDaemon.

    Verify Existence Of BMC Record From List  ${service_type}
    Run Keyword If  '${skip}' == 'True'  Set AvahiDaemon Service  command=stop
    Redfish OBMC Reboot (off)
    Verify AvahiDaemon Service Status  message=start
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Verify Existence Of BMC Record From List  ${service_type}


Redfish Update Firmware
    [Documentation]  Update the BMC firmware via redfish interface and verify the bmc version
    ...              and apply time.
    [Arguments]  ${apply_time}

    # Description of argument(s):
    # apply_time    ApplyTime allowed values (e.g. "OnReset", "Immediate").

    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Set ApplyTime  policy=${apply_Time}
    Redfish Upload Image And Check Progress State
    Run Key  ${post_code_update_actions['BMC image']['${apply_time}']}
    Redfish.Login
    Redfish Verify BMC Version  ${IMAGE_FILE_PATH}
    Verify Get ApplyTime  ${apply_time}


Discover BMC Pre And Post Firmware Update
    [Documentation]  Discover BMC, After code update.
    [Arguments]  ${service_type1}  ${service_type2}  ${status}

    # Description of argument(s):
    # service_type     BMC service type e.g.
    #                  (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).
    # status           True or False

    Valid File Path  IMAGE_FILE_PATH
    Verify Existence Of BMC Record From List  ${service_type1}
    Verify Existence Of BMC Record From List  ${service_type2}
    Redfish Update Firmware  apply_time=Immediate
    ${keyword_status}=  Run Keyword And Return Status
    ...  Verify Existence Of BMC Record From List  ${service_type1}
    Should Be Equal  '${status}'  '${keyword_status}'
    ${keyword_status}=  Run Keyword And Return Status
    ...  Verify Existence Of BMC Record From List  ${service_type2}
    Should Be Equal  '${status}'  '${keyword_status}'


Discover BMC Pre And Post When Host Boot
    [Documentation]  Discover BMC, when host boot in progress.
    [Arguments]  ${service_type1}  ${service_type2}

    # Description of argument(s):
    # service_type     BMC service type e.g.
    #                  (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

    Verify Existence Of BMC Record From List  ${service_type1}
    Verify Existence Of BMC Record From List  ${service_type2}
    Redfish Power Off  stack_mode=skip
    Get Host Power State
    Redfish Power Operation  reset_type=On
    Sleep  15s
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    FOR  ${index}  IN RANGE  10
        Sleep  3s
        Verify Existence Of BMC Record From List  ${service_type1}
        Verify Existence Of BMC Record From List  ${service_type2}
    END
    Wait Until Keyword Succeeds  10 min  10 sec  Is OS Booted
