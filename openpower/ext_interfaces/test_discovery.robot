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
Resource             ../../lib/boot_utils.robot
Resource             ../../syslib/utils_os.robot

Suite Setup          Suite Setup Execution

*** Test Cases ***

Discover BMC With Different Service Type
    [Documentation]  Discover all the BMC with different service type support.
    [Tags]  Discover_BMC_With_Different_Service_Type
    [Template]  Discover BMC With Service Type

    # Service type
    _obmc_rest._tcp
    _obmc_redfish._tcp


Disable AvahiDaemon And Discover BMC After Reboot
    [Documentation]  Check the input BMC is discoverd and then disable the avahi daemon,
    ...  in next reboot same input BMC should discoverable.
    [Tags]  Disable_AvahiDaemon_And_Discover_BMC_After_Reboot
    [Template]  Disable Daemon And Discover BMC After Reboot

    # Service type
    _obmc_rest._tcp
    _obmc_redfish._tcp

*** Keywords ***

Suite Setup Execution
    [Documentation]  Do the suite setup.

    Should Not Be Empty  ${AVAHI_CLIENT}
    Should Not Be Empty  ${AVAHI_CLIENT_USERNAME}
    Should Not Be Empty  ${AVAHI_CLIENT_PASSWORD}
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    Check Avahi Package


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


Disable Daemon And Discover BMC After Reboot
    [Documentation]  Discover BMC After reboot.
    [Arguments]  ${service_type}

    # Description of argument(s):
    # service_type  BMC service type e.g.
    #               (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

    Set AvahiDaemon Service  command=stop
    Redfish OBMC Reboot (off)
    Verify AvahiDaemon Service Status  message=start
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    Wait Until Keyword Succeeds  2 min  30 sec
    ...  Verify Existence Of BMC Record From List  ${service_type}
