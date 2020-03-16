*** Settings ***

Documentation        Test to discover the BMC.

Resource             ../../syslib/utils_os.robot
Library              ../../lib/management_console_utils.py

Suite Setup          Suite Setup Execution

Test Teardown        FFDC On Test Case Fail

*** Test Cases ***

Discover BMC With REST Service Type
    [Documentation]  Discover all the BMC with REST service type support.
    [Tags]  Discover_BMC_With_REST_Service_Type
    [Template]  Discover BMC With Service Type

    # Service type
    RESTService


Discover BMC With Redfish Service Type
    [Documentation]  Discover all the BMC with Redfish service type support.
    [Tags]  Discover_BMC_With_Redfish_Service_Type
    [Template]  Discover BMC With Service Type

    # Service type
    RedfishService


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

    # Expexted command output as below.
    # avahi-tools-0.6.31-19.el7.x86_64

    ${command}=  Set Variable  rpm -qa | grep avahi-tools
    ${resp_rpm}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${resp_rpm}  avahi-tools  ignore_case=True  msg=avahi-tools is not available.

Check Avahi Service Status
    [Documentation]  To check for avahi service.

     # Expexted command output as below.
     # CGroup: /system.slice/avahi-daemon.service
     #      ├─289 avahi-daemon: running [System Name]
     #      └─317 avahi-daemon: chroot helper

    ${command}=  Set Variable  systemctl status avahi-daemon
    ${resp_rpm}  ${stderr}=  Execute Command  ${command}  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${resp_rpm}  avahi-daemon: running  ignore_case=True  msg=avahi-daemon is not running.

Discover BMC With Service Type
    [Documentation]  To get the discoverd BMC list.
    [Arguments]  ${service_type}

    # Description of argument(s):
    # ${service_type}  BMC published type e.g.
    #                  (REST Service = _obmc_rest._tcp, Redfish Service = _obmc_redfish._tcp).

    ${code_base_dir_path}=  Get Code Base Dir Path
    ${published_service}=  Evaluate
    ...  json.load(open('${code_base_dir_path}data/BMC_publish_service.json'))  modules=json
    Rprint Vars  published_service
    ${resp_service}  ${stderr}=  Execute Command  ${published_service['${service_type}']}  return_stderr=True
    ${bmc_list}  ${exc_msg}=  Get BMC Records  ${service_type}  ${resp_service}
    Print Timen  Exception message is ${exc_msg}
    Rprint Vars  bmc_list
    Pass Execution If  '${exc_msg}' == 'None'  BMC records captured.
    Should Not Be Empty  ${bmc_list}
