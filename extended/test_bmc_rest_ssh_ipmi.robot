***Settings***
Documentation   Generic REST/SSH/IPMI stress buster program.

Library        ../lib/jobs_processing.py
Resource       ../lib/rest_client.robot
Resource       ../lib/connection_client.robot
Resource       ../lib/ipmi_client.robot
Resource       ../lib/utils.robot
Resource       ../lib/openbmc_ffdc.robot

Test Teardown  FFDC On Test Case Fail

***Variables***

# Currently REST session is set to MAX_SESSIONS = 16
${BUSTER_COUNT}    ${16}

***Test Cases***

Stress BMC REST Server
    [Documentation]  Execute 20 REST operation and expect success.
    [Tags]  Stress_BMC_REST_Server
    ${dict}=  Execute Process  ${BUSTER_COUNT}  REST Enumerate Request On BMC
    Dictionary Should Not Contain Value   ${dict}  False


Stress BMC SSH Server
    [Documentation]  Execute 20 SSH operation and expect success.
    [Tags]  Stress_BMC_SSH_Server
    ${dict}=  Execute Process  ${BUSTER_COUNT}  SSH Connect And Execute Command
    Dictionary Should Not Contain Value   ${dict}  False


Stress BMC IPMI Server
    [Documentation]  Execute 20 IPMI operation and expect success.
    [Tags]  Stress_BMC_IPMI_Server
    ${dict}=  Execute Process  ${BUSTER_COUNT}  IPMI Check Status
    Dictionary Should Not Contain Value   ${dict}  False

***Keywords***

REST Enumerate Request On BMC
    [Documentation]  Execute REST GET operation.

    # Create REST session.
    Create Session  openbmc  ${AUTH_URI}
    ${headers}=  Create Dictionary  Content-Type=application/json
    @{credentials}=  Create List  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
    ${data}=  Create Dictionary  data=@{credentials}
    ${resp}=  Post Request  openbmc  /login  data=${data}  headers=${headers}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    # Trigger GET REST enumeration.
    ${resp}=  Get Request  openbmc  /xyz/openbmc_project/software/enumerate
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    Delete All Sessions


SSH Connect And Execute Command
    [Documentation]  Execute SSH command execution operation.
    Open Connection And Log In
    Execute Command On BMC  df -h
    Close Connection


IPMI Check Status
    [Documentation]  Execute IPMI command execution operation.
    Run IPMI Standard Command  chassis status
