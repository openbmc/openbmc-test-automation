*** Settings ***
Documentation        Test to discover the BMC.

Variables            ../../data/variables.py
Library              SSHLibrary
Library              ../../lib/external_intf/management_console_utils.py
Library              ../../lib/gen_robot_print.py
Library              ../../lib/gen_print.py
Library              ../../lib/gen_misc.py
Library              ../../lib/tftp_update_utils.py
Resource             ../../lib/code_update_utils.robot
Resource             ../../lib/redfish_code_update_utils.robot
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


Discover BMC Pre And Post Reboot
    [Documentation]  Discover BMC before and after reboot.
    [Tags]  Discover_BMC_Pre_And_Post_Reboot
    [Template]  Disable Daemon And Discover BMC In Next Reboot

    # Service type
    _obmc_rest._tcp
    _obmc_redfish._tcp


Disable AvahiDaemon And Discover BMC In Next Reboot
    [Documentation]  Check the input BMC is discoverd and then disable the avahi daemon,
    ...  in next reboot same input BMC should discoverable.
    [Tags]  Disable_AvahiDaemon_And_Discover_BMC_In_Next_Reboot
    [Template]  Disable Daemon And Discover BMC In Next Reboot

    # Service type    skip
    _obmc_rest._tcp   True


Discover BMC After Code Update Of Same Build
    [Documentation]  Discover BMC, when code update occurs for same build.
    [Tags]  Discover_BMC_After_Code_Update_Of_Same_Build
    [Template]  Discover BMC After Code Update

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
    # service_type    BMC service type e.g.
    #                 (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

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


Disable Daemon And Discover BMC In Next Reboot
    [Documentation]  Discover BMC in Next reboot.
    [Arguments]  ${service_type}  ${skip}=False

    # Description of argument(s):
    # service_type  BMC service type e.g.
    #               (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).
    # skip          Run part of code, based on the input provided e.g. (True or False).

    Verify Existence Of BMC Record From List  ${service_type}
    Run Keyword If  '${skip}' == 'True'  Set AvahiDaemon Service  command=stop
    Redfish OBMC Reboot (off)
    Verify AvahiDaemon Service Status  message=start
    Login To OS  ${AVAHI_CLIENT}  ${AVAHI_CLIENT_USERNAME}  ${AVAHI_CLIENT_PASSWORD}
    Verify Existence Of BMC Record From List  ${service_type}


Redfish Code Update
    [Documentation]  Redfish Code update.
    [Arguments]  ${file_path}

    # Description of argument(s):
    # file_path   The path to image file.

    Redfish.Login
    ${post_code_update_actions}=  Get Post Boot Action
    ${state}=  Get Pre Reboot State
    Rprint Vars  state
    Set ApplyTime  policy=Immediate
    Redfish Upload Image And Check Progress State
    Run Key  ${post_code_update_actions['BMC image']['Immediate']}
    Redfish.Login
    Redfish Verify BMC Version  ${file_path}


Discover BMC After Code Update
    [Documentation]  Discover BMC, After code update.
    [Arguments]  ${service_type1}  ${service_type2}

    # Description of argument(s):
    # service_type     BMC service type e.g.
    #                  (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).
    # IMAGE_FILE_PATH  The path to BMC image file.

    Verify Existence Of BMC Record From List  ${service_type1}
    Verify Existence Of BMC Record From List  ${service_type2}
    Redfish Code Update  ${IMAGE_FILE_PATH}
    Verify Existence Of BMC Record From List  ${service_type1}
    Verify Existence Of BMC Record From List  ${service_type2}

