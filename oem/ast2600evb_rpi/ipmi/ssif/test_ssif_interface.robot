*** Settings ***
Documentation  SSIF interface test cases for AST2600 EVB+RPI setup.
...
...  Covers SSIF kernel config verification, /dev/ipmi-ssif-host device node,
...  phosphor-ipmi-host and ssifbridge service status, SSIF IPMI certificate
...  fingerprint retrieval, and bootstrap credential get operations issued
...  over the SSIF channel from the host.
...
...  Test Environment:
...  - BMC: AST2600 at ${OPENBMC_HOST}  (pass --variable OPENBMC_HOST:<ip> at runtime)
...  - Host: Raspberry Pi (RPI) at ${HOST_IP}

Resource        ../../resource.resource

Suite Setup     Redfish.Login
Suite Teardown  Suite Teardown Execution

Test Tags  EVB_RPI

*** Test Cases ***

Ssif Subsystems
    [Documentation]  Verify SSIF subsystems is enabled by default.
    ...  Checks kernel config for SSIF support and /dev/ipmi-ssif-host device node.
    ...  systemctl status phosphor-ipmi-host.service service is active and running by default.
    [Tags]  Ssif_Subsystems
    [Setup]  Setup BMC SSH Only
    [Teardown]  Close All Connections

    ${output}=  Execute Command  cat /proc/config.gz | zcat | grep SSIF
    Should Contain  ${output}  CONFIG_IPMI_SSIF=y
    Should Contain  ${output}  CONFIG_SSIF_IPMI_BMC=y
    ${dev_output}=  Execute Command  ls -l /dev/ipmi*
    Should Contain  ${dev_output}  /dev/ipmi-ssif-host
    ${output}=  Execute Command  systemctl status phosphor-ipmi-host.service
    Should Contain  ${output}  active (running)


Ssifbridge Service
    [Documentation]  Verify ssifbridge service is active and running by default.
    [Tags]  Ssifbridge_Service
    [Setup]  Setup BMC SSH Only
    [Teardown]  Close All Connections

    ${output}=  Execute Command  systemctl status ssifbridge.service
    Should Contain  ${output}  active (running)


Get Manager Certificate Fingerprint
    [Documentation]  Verify BMC returns certificate fingerprint via SSIF IPMI raw command.
    ...  Response layout: [0x52][0x01][32 SHA-256 bytes]
    ...  Compares the IPMI fingerprint with the SHA-256 fingerprint of the BMC TLS
    ...  certificate obtained via openssl to confirm they match.
    [Tags]  Get_Manager_Certificate_Fingerprint
    [Setup]  Setup Host SSH Only
    [Teardown]  Close All Connections

    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get fingerprint bytes from IPMI.
    ${raw}=  Execute Command  sudo ipmitool raw ${IPMI_RAW_CMD}[ssif_certificate_fingerprint][Get][0]
    Should Not Be Empty  ${raw}
    ${bytes}=  Split String  ${raw}
    # Skip first 2 bytes (0x52 status, 0x01 echo); remaining 32 bytes = SHA-256 fingerprint.
    ${fp_bytes}=  Get Slice From List  ${bytes}  2
    ${ipmi_fp}=  Evaluate
    ...  ':'.join(b.upper() for b in $fp_bytes if b.strip())
    Log  IPMI Fingerprint: ${ipmi_fp}
    # Get fingerprint from BMC TLS certificate via openssl.
    ${openssl_out}=  Execute Command
    ...  openssl s_client -connect ${OPENBMC_HOST}:${HTTPS_PORT} -servername ${OPENBMC_HOST} </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
    ${openssl_fp}=  Evaluate  '${openssl_out}'.split('=')[-1].strip()
    Log  OpenSSL Fingerprint: ${openssl_fp}
    # Verify IPMI fingerprint matches the actual BMC certificate fingerprint.
    Should Be Equal As Strings  ${ipmi_fp}  ${openssl_fp}


Get Bootstrap Account Credentials And Keep Credential Boot Strapping Enabled
    [Documentation]  Verify BMC returns valid username and password and Credential Boot Strapping
    ...  remains enabled after getting credentials (EnableAfterReset=true, Enabled=true).
    ...  Bootstrap account is deleted in teardown.
    [Tags]  Get_Bootstrap_Account_Credentials_And_Keep_Credential_Boot_Strapping_Enabled
    [Setup]  Setup Host SSH Only
    [Teardown]  Teardown Bootstrap Test

    # Enable Credential Bootstrapping via Redfish.
    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get credentials from host via SSIF, parse and store as suite variables.
    Get Bootstrap Credentials  ${True}
    Log  Bootstrap Username: ${BOOTSTRAP_USERNAME}
    # Verify HostInterfaces still shows Enabled=true via Redfish.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${True}


Get Bootstrap Account Credentials And Disable Credential Boot Strapping
    [Documentation]  Verify BMC returns valid username and password and Credential Boot Strapping
    ...  is disabled after getting credentials.
    ...  Bootstrap account is deleted in teardown.
    [Tags]  Get_Bootstrap_Account_Credentials_And_Disable_Credential_Boot_Strapping
    [Setup]  Setup Host SSH Only
    [Teardown]  Teardown Bootstrap Test

    # Enable Credential Bootstrapping via Redfish.
    Set And Verify Credential Bootstrapping  enabled=${True}
    # Get credentials from host via SSIF, parse and store as suite variables.
    Get Bootstrap Credentials  ${False}
    Log  Bootstrap Username: ${BOOTSTRAP_USERNAME}
    # Verify HostInterfaces shows Enabled=false after get with disable via Redfish.
    ${json}=  Get Host Interface JSON
    Should Be Equal  ${json['CredentialBootstrapping']['Enabled']}  ${False}
