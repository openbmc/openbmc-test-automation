*** Settings ***
Documentation   OEM IPMI in-band BMC authentication reset.

# This resets the BMC authentication:
# - Enable local users if they were disabled.
# - Delete the LDAP configuration if there was one.
# - Reset the root password back to the default one.

Resource        ../lib/resource.robot
Resource        ../lib/ipmi_client.robot
Resource        ../lib/boot_utils.robot
Library         ../lib/ipmi_utils.py

Test Teardown   FFDC On Test Case Fail

*** Test Cases ***

Test Inband IPMI Auth Reset
    [Documentation]  Trigger in-band BMC authentication reset and verify.
    [Tags]  Test_Inband_IPMI_Auth_Reset

    Create Session  openbmc  ${AUTH_URI}  max_retries=1
    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${data}=  create dictionary   data=@{credentials}
    ${resp}=  Post Request  openbmc  /login  data=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_UNAUTHORIZED}

    # Call reset method.
    Run Inband IPMI Raw Command  0x3a 0x11

    Initialize OpenBMC
