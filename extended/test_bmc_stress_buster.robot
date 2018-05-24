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

# Caller can specify a value for the following using -v parms
# Currently REST/SSH/IPMI session allowed.
${REST_BUSTER_MAX}    ${16}
${SSH_BUSTER_MAX}     ${16}
${IPMI_BUSTER_MAX}    ${5}

***Test Cases***

Stress BMC REST Server
    [Documentation]  Execute maximum allowed REST operation.
    [Tags]  Stress_BMC_REST_Server
    ${dict}=  Execute Process
    ...  ${REST_BUSTER_MAX}  REST Enumerate Request On BMC
    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more REST operations has failed.


Stress BMC SSH Server
    [Documentation]  Execute maximum allowed SSH operation.
    [Tags]  Stress_BMC_SSH_Server
    ${dict}=  Execute Process
    ...  ${SSH_BUSTER_MAX}  SSH Connect And Execute Command
    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more SSH operations has failed.


Stress BMC IPMI Server
    [Documentation]  Execute maximum allowed IPMI operation.
    [Tags]  Stress_BMC_IPMI_Server
    ${dict}=  Execute Process  ${IPMI_BUSTER_MAX}  IPMI Check Status
    Dictionary Should Not Contain Value  ${dict}  False
    ...  msg=One or more IPMI operations has failed.

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
    BMC Execute Command  df -h


IPMI Check Status
    [Documentation]  Execute IPMI command execution operation.
    Run IPMI Standard Command  chassis status
