*** Settings ***
Documentation  Host Interface (Credential Bootstrapping) test cases for AST2600 EVB+RPI setup.
...
...  Covers Redfish-side credential bootstrapping lifecycle: default state verification,
...  enable/disable bootstrapping, negative tests (fingerprint and credential requests
...  when disabled), Redfish API access and account deletion via bootstrap credentials,
...  host interface accessibility checks, and bootstrapping state persistence across
...  BMC force and graceful restarts.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}
...  - USB Ethernet: BMC at ${BMC_USB_ETH_IP}, Host at ${HOST_USB_ETH_IP}

Resource        ../../resource.resource

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution

Test Tags  EVB_RPI

*** Test Cases ***

Default Credential Boot Strapping Enableafterreset True Enabled True
    [Documentation]  Verify Default Credential Boot Strapping values.
    ...  EnableAfterReset and Enabled should both be true by default.
    [Tags]  Default_Credential_Boot_Strapping_Enableafterreset_True_Enabled_True

    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['EnableAfterReset']}  ${True}
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}

Enable Credential Boot Strapping
    [Documentation]  Verify Enabling Credential Boot Strapping using redfish.
    [Tags]  Enable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${True}


Disable Credential Boot Strapping
    [Documentation]  Verify disabling Credential Boot Strapping using redfish.
    [Tags]  Disable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}


Disable Credential Boot Strapping And Get Manager Certificate Fingerprint
    [Documentation]  Certificate fingerprint generation should fail when Credential Boot Strapping is disabled and
    ...  manager certificate fingerprint is requested.
    [Tags]  Disable_Credential_Boot_Strapping_And_Get_Manager_Certificate_Fingerprint
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}
    ${output}=  Execute Command  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_certificate_fingerprint][Get][0]
    Should Be Empty  ${output}  CredentialBootstrapping is not disabled


Disable Credential Boot Strapping And Get Bootstrap Account Credentials
    [Documentation]  Bootstrap Account User creation should fail when Credential Boot Strapping is disabled.
    [Tags]  Disable_Credential_Boot_Strapping_And_Get_Bootstrap_Account_Credentials
    [Setup]  Setup Host SSH Only
    [Teardown]  Setup Teardown

    Set And Verify Credential Bootstrapping  enabled=${False}
    ${output}=  Execute Command  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_bootstrap_credentials][Get_Enabled][0]
    Should Be Empty  ${output}  CredentialBootstrapping is not disabled
    Set And Verify Credential Bootstrapping  enabled=${True}


Redfish Api Access With Received Bootstrap Account Credential From Host
    [Documentation]  Verify Redfish API access with Bootstrap Account Credential Generated.
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Redfish_Api_Access_With_Received_Bootstrap_Account_Credential_From_Host
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${HOST_INTERFACE_URI}
    ${output}=  Execute Command  ${cmd}  timeout=5
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['Description']}  Host Interface


Delete Bootstrap Account With Redfish From Host
    [Documentation]  Delete Bootstrap Account with Redfish API using bootstrap credentials.
    ...  Generates bootstrap credentials in setup; account is deleted by the test itself.
    [Tags]  Delete_Bootstrap_Account_With_Redfish_From_Host
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}' -X DELETE
    ...  https://${BMC_USB_ETH_IP}${REDFISH_ACCOUNTS_URI}${BOOTSTRAP_USERNAME}
    ${output}=  Execute Command  ${cmd}  timeout=5
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['@Message.ExtendedInfo'][0]['Message']}  The account was successfully removed.


Host Interface External Accessible Is Disabled
    [Documentation]  Verify External Access to Host Interface is disabled.
    ...  ExternallyAccessible should be false for the Host Interface.
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Host_Interface_External_Accessible_Is_Disabled
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${HOST_INTERFACE_URI}
    ${output}=  Execute Command  ${cmd}
    ${json}=  Evaluate  json.loads('''${output}''')  json
    Should Be Equal  ${json['ExternallyAccessible']}  ${False}
    Should Be Equal  ${json['Description']}  Host Interface
    Should Be Equal  ${json['HostInterfaceType']}  NetworkHostInterface
    Should Be Equal  ${json['Id']}  rhi
    Should Be Equal  ${json['InterfaceEnabled']}  ${True}


Use Bootstrap Account Credential With Internal Connection Ethernet Over Usb
    [Documentation]  Verify Bootstrap Account Credential are usable over internal network
    ...  using Redfish interface (Ethernet over USB).
    ...  Generates bootstrap credentials in setup and deletes the account in teardown.
    [Tags]  Use_Bootstrap_Account_Credential_With_Internal_Connection_Ethernet_Over_Usb
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    ${cmd}=  Catenate
    ...  curl -k -s -u '${BOOTSTRAP_USERNAME}:${BOOTSTRAP_PASSWORD}'
    ...  https://${BMC_USB_ETH_IP}${REDFISH_BASE_URI}
    ${output}=  Execute Command  ${cmd}
    Should Contain  ${output}  RedfishVersion


Verify Bootstrap Account Deletion After Bmc Force Restart
    [Documentation]  Verify on service reset (BMC Force Restart) Bootstrap Account should get deleted.
    [Tags]  Verify_Bootstrap_Account_Deletion_After_Bmc_Force_Restart
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    Verify Bootstrap Account Deleted


Verify Bootstrap Account Deletion After Bmc Graceful Restart
    [Documentation]  Verify on service reset (BMC Graceful Restart) Bootstrap Account should get deleted.
    [Tags]  Verify_Bootstrap_Account_Deletion_After_Bmc_Graceful_Restart
    [Setup]  Setup Bootstrap Test
    [Teardown]  Teardown Bootstrap Test

    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    Verify Bootstrap Account Deleted


Reset Service Bmc Force Restart Credential Bootstrapping Enabled
    [Documentation]  Verify Credential Bootstrapping gets enabled after BMC Force Restart.
    ...  When EnableAfterReset=true and Enabled=false, after BMC restart Enabled should become true.
    [Tags]  Reset_Service_Bmc_Force_Restart_Credential_Bootstrapping_Enabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping (EnableAfterReset remains true by default).
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${True}
    # Force restart BMC.
    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping is enabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Reset Service Bmc Graceful Restart Credential Bootstrapping Enabled
    [Documentation]  Verify Credential Bootstrapping gets enabled after BMC Graceful Restart.
    ...  When EnableAfterReset=true and Enabled=false, after BMC restart Enabled should become true.
    [Tags]  Reset_Service_Bmc_Graceful_Restart_Credential_Bootstrapping_Enabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping (EnableAfterReset remains true by default).
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${True}
    # Graceful restart BMC.
    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping is enabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Reset Service Bmc Force Restart Credential Bootstrapping Remain Disabled
    [Documentation]  Verify Credential Bootstrapping remains disabled after BMC Force Restart.
    ...  When EnableAfterReset=false and Enabled=false, after BMC restart Enabled should remain false.
    [Tags]  Reset_Service_Bmc_Force_Restart_Credential_Bootstrapping_Remain_Disabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping with EnableAfterReset=false.
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${False}
    # Force restart BMC.
    BMC Force Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping remains disabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}


Reset Service Bmc Graceful Restart Credential Bootstrapping Remain Disabled
    [Documentation]  Verify Credential Bootstrapping remains disabled after BMC Graceful Restart.
    ...  When EnableAfterReset=false and Enabled=false, after BMC restart Enabled should remain false.
    [Tags]  Reset_Service_Bmc_Graceful_Restart_Credential_Bootstrapping_Remain_Disabled
    [Teardown]  Setup Teardown

    # Disable Credential Bootstrapping with EnableAfterReset=false.
    Set And Verify Credential Bootstrapping  enabled=${False}  enable_after_reset=${False}
    # Graceful restart BMC.
    BMC Graceful Restart
    Sleep  ${BMC_RESET_WAIT}  Wait for BMC to restart
    Wait Until Keyword Succeeds  3 min  10 sec  Redfish.Login
    # Verify Credential Bootstrapping remains disabled after restart.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}
