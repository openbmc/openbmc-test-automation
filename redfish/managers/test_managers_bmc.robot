*** Settings ***
Documentation    Test BMC Manager functionality.
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/boot_utils.robot
Resource         ../../lib/open_power_utils.robot
Resource         ../../lib/bmc_network_utils.robot
Library          ../../lib/gen_robot_valid.py

Test Setup       Test Setup Execution
Test Teardown    Test Teardown Execution


*** Variables ***

${SYSTEM_SHUTDOWN_TIME}    ${5}

# Strings to check from journald.
${REBOOT_REGEX}    ^\-- Boot

*** Test Cases ***

Verify Redfish BMC Firmware Version
    [Documentation]  Get firmware version from BMC manager.
    [Tags]  Verify_Redfish_BMC_Firmware_Version

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    ${bmc_version}=  Get BMC Version
    Should Be Equal As Strings
    ...  ${resp.dict["FirmwareVersion"]}  ${bmc_version.strip('"')}


Verify Redfish BMC Manager Properties
    [Documentation]  Verify BMC managers resource properties.
    [Tags]  Verify_Redfish_BMC_Manager_Properties

    Redfish.Login
    ${resp}=  Redfish.Get  /redfish/v1/Managers/bmc
    Should Be Equal As Strings  ${resp.status}  ${HTTP_OK}
    # Example:
    #  "Description": "Baseboard Management Controller"
    #  "Id": "bmc"
    #  "Model": "OpenBmc",
    #  "Name": "OpenBmc Manager",
    #  "UUID": "xxxxxxxx-xxx-xxx-xxx-xxxxxxxxxxxx"
    #  "PowerState": "On"

    Should Be Equal As Strings
    ...  ${resp.dict["Description"]}  Baseboard Management Controller
    Should Be Equal As Strings  ${resp.dict["Id"]}  bmc
    Should Be Equal As Strings  ${resp.dict["Name"]}  OpenBmc Manager
    Should Not Be Empty  ${resp.dict["UUID"]}
    Should Be Equal As Strings  ${resp.dict["PowerState"]}  On


Verify MAC Address Property Is Populated
    [Documentation]  Verify BMC managers resource properties.
    [Tags]  Verify_MAC_Address_Property_Is_Populated

    # Get OrderedDict from the BMC which contains active ethernet channel.
    # Example: ([('1', {'name': 'eth0',
    #                   'is_valid': True,
    #                   'active_sessions': 0,
    #                   'channel_info': {'medium_type': 'lan-802.3',
    #                                    'protocol_type': 'ipmb-1.0',
    #                                    'session_supported': 'multi-session',
    #                                    'is_ipmi': True
    #                                   }
    #                  }
    #          )])

    ${active_channel_config}=  Get Active Channel Config

    FOR  ${channel_number}  IN  @{active_channel_config.keys()}
        Log Dictionary  ${active_channel_config["${channel_number}"]}

        # Get ethernet valid paths in redfish.
        # Example: ['/redfish/v1/Managers/bmc/EthernetInterfaces']
        ${eth_interface}=  redfish_utils.Get Endpoint Path List
        ...  /redfish/v1/Managers/  EthernetInterfaces

        # Get the MACAddress attrivute value with the 'name': 'eth0'.
        # Example: /redfish/v1/Managers/bmc/EthernetInterfaces/eth0
        ${redfish_mac_addr}=  Redfish.Get Attribute
        ...  ${eth_interface[0]}/${active_channel_config["${channel_number}"]["name"]}
        ...  MACAddress
    END

    Rprint Vars  redfish_mac_addr  fmt=terse
    Valid Value  redfish_mac_addr

    ${ipaddr_mac_addr}=  Get BMC MAC Address List
    Rprint Vars  ipaddr_mac_addr  fmt=terse

    List Should Contain Value  ${ipaddr_mac_addr}  ${redfish_mac_addr}


Redfish BMC Manager GracefulRestart When Host Off
    [Documentation]  BMC graceful restart when host is powered off.
    [Tags]  Redfish_BMC_Manager_GracefulRestart_When_Host_Off

    # "Actions": {
    # "#Manager.Reset": {
    #  "ResetType@Redfish.AllowableValues": [
    #    "GracefulRestart"
    #  ],
    #  "target": "/redfish/v1/Managers/bmc/Actions/Manager.Reset"
    # }

    ${test_file_path}=  Set Variable  /tmp/before_bmcreboot
    BMC Execute Command  touch ${test_file_path}

    Redfish OBMC Reboot (off)

    BMC Execute Command  if [ -f ${test_file_path} ] ; then false ; fi
    Verify BMC RTC And UTC Time Drift

    # Check for journald persistency post reboot.
    Check For Regex In Journald  ${REBOOT_REGEX}  error_check=${1}


Verify Boot Count After BMC Reboot
    [Documentation]  Verify boot count increments on BMC reboot.
    [Tags]  Verify_Boot_Count_After_BMC_Reboot

    Set BMC Boot Count  ${0}
    Redfish OBMC Reboot (off)
    ${boot_count}=  Get BMC Boot Count
    Should Be Equal  ${boot_count}  ${1}  msg=Boot count is not incremented.


Redfish BMC Manager GracefulRestart When Host Booted
    [Documentation]  BMC graceful restart when host is running.
    [Tags]  Redfish_BMC_Manager_GracefulRestart_When_Host_Booted

    Redfish OBMC Reboot (run)

    # TODO: Replace OCC state check with redfish property when available.
    Verify OCC State


*** Keywords ***

Test Setup Execution
    [Documentation]  Do test case setup tasks.

    redfish.Login


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    FFDC On Test Case Fail
    Run Keyword And Ignore Error  redfish.Logout
