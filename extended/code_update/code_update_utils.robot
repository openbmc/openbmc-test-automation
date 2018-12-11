*** Settings ***
Documentation    Code update utility

Resource         ../../lib/rest_client.robot
Resource         ../../lib/connection_client.robot
Resource         ../../lib/utils.robot
Library          OperatingSystem

*** Variables ***

# Fix old org path locally for non-witherspoon system.
${ORG_OPENBMC_BASE_URI}  /org/openbmc/
${BMC_UPD_METHOD}    ${ORG_OPENBMC_BASE_URI}control/flash/bmc/action/update
${BMC_PREP_METHOD}   ${ORG_OPENBMC_BASE_URI}control/flash/bmc/action/PrepareForUpdate
${BMC_UPD_ATTR}      ${ORG_OPENBMC_BASE_URI}control/flash/bmc
${HOST_SETTING}      ${ORG_OPENBMC_BASE_URI}settings/host0

*** Keywords ***

Preserve BMC Network Setting
    [Documentation]   Preserve Network setting
    ${policy}=       Set Variable   ${1}
    ${value}=    create dictionary   data=${policy}
    Write Attribute   ${BMC_UPD_ATTR}  preserve_network_settings  data=${value}
    ${data}=      Read Properties   ${BMC_UPD_ATTR}
    Should Be Equal As Strings    ${data['preserve_network_settings']}   ${True}
    ...   msg=False indicates network is not preserved.


Activate BMC Flash Image
    [Documentation]   Activate and verify the update status.
    ...               The status could be either one of these:
    ...               'Deferred for mounted filesystem. reboot BMC to apply.'
    ...               'Image ready to apply.'
    @{img_path}=  Create List  /tmp/flashimg
    ${data}=  Create Dictionary  data=@{img_path}
    ${resp}=  OpenBMC Post Request  ${BMC_UPD_METHOD}  data=${data}
    ...  timeout=${30}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

    ${data}=  Read Properties  ${BMC_UPD_ATTR}
    Should Be Equal As Strings  ${data["filename"]}  /tmp/flashimg
    Should Contain  ${data['status']}  to apply


Prepare For Update
    [Documentation]   Switch to update mode in progress. This method calls
    ...               the Abort method to remove the pending update if there
    ...               is any before code activation.
    ${data}=  Create Dictionary  data=@{EMPTY}
    ${resp}=  Openbmc Post Request  ${BMC_PREP_METHOD}  data=${data}

    # Update method will reset the BMC, adding delay for reboot to
    # come into force.
    Sleep  10s


SCP Tar Image File to BMC
    [Documentation]  Copy BMC tar image to BMC.
    [Arguments]  ${image_file_path}
    # Description of argument(s):
    # image_file_path  Downloaded BMC tar file image path.


    Open Connection for SCP
    Open Connection And Log In
    Loop SCP Retry  ${image_file_path}


Loop SCP Retry
    [Documentation]  Try transferring the file 4 times.
    [Arguments]  ${image_file_path}
    # Description of argument(s):
    # image_file_path  Downloaded BMC tar file image path.

    : FOR  ${index}  IN RANGE  0  4
    \  ${status}=  Retry SCP  ${image_file_path}
    \  Exit For Loop If  '${status}' == '${True}'


Retry SCP
    [Documentation]  Delete the incomplete file and scp file.
    [Arguments]  ${image_file_path}
    # Description of argument(s):
    # image_file_path  Downloaded BMC tar file image path.

    ${targ_file_path}=  Set Variable  /tmp/flashimg

    # TODO: Need to remove this when new code update in place.
    # Example output:
    # root@witherspoon:~# ls -lh /tmp/flashimg
    # -rwxr-xr-x    1 root     root       32.0M Jun 29 01:12 /tmp/flashimg
    BMC Execute Command  rm -f /tmp/flashimg
    scp.Put File  ${image_file_path}  ${targ_file_path}

    ${file_size}  ${stderr}  ${rc}=  BMC Execute Command
    ...  ls -lh ${targ_file_path}
    ${status}=  Run Keyword And Return Status
    ...  Should Contain  ${file_size}  32.0M  msg=Incomplete file transfer.
    [return]  ${status}


Check If File Exist
    [Documentation]  Verify that the file exists on this machine.
    [Arguments]  ${filepath}
    Log   \n PATH: ${filepath}
    OperatingSystem.File Should Exist  ${filepath}
    ...    msg=${filepath} doesn't exist [ ERROR ]

    Set Global Variable   ${FILE_PATH}  ${filepath}


System Readiness Test
    [Documentation]  Verify that the system can be pinged and authenticated through REST.
    ${l_status}=   Run Keyword and Return Status
    ...   Verify Ping and REST Authentication
    Run Keyword If  '${l_status}' == '${False}'
    ...   Fail  msg=System not in ideal state to use [ERROR]


Validate BMC Version
    [Documentation]  Get BMC version from /etc/os-release and compare.
    [Arguments]  ${version}

    # Description of argument(s):
    # version  Software version (e.g. "v1.99.8-41-g86a4abc").

    Open Connection And Log In
    ${cmd}=  Set Variable  grep ^VERSION_ID= /etc/os-release | cut -f 2 -d '='
    ${output}  ${stderr}  ${rc}=  BMC Execute Command  ${cmd}
    Should Be Equal As Strings  ${version}  ${output[1:-1]}


Trigger Warm Reset via Reboot
    [Documentation]    Execute reboot command on the remote BMC and
    ...                returns immediately. This keyword "Start Command"
    ...                returns nothing and does not wait for the command
    ...                execution to be finished.
    Open Connection And Log In

    Start Command   /sbin/reboot

Set Policy Setting
    [Documentation]   Set the given test policy
    [Arguments]   ${policy}

    ${valueDict}=     create dictionary  data=${policy}
    Write Attribute    ${HOST_SETTING}    power_policy   data=${valueDict}
    ${currentPolicy}=  Read Attribute     ${HOST_SETTING}   power_policy
    Should Be Equal    ${currentPolicy}   ${policy}
