*** Settings ***
Documentation    Code update utility

Resource         ../../lib/rest_client.robot
Resource         ../../lib/connection_client.robot
Resource         ../../lib/utils.robot
Library          OperatingSystem

*** Variables ***

${BMC_UPD_METHOD}    ${OPENBMC_BASE_URI}control/flash/bmc/action/update
${BMC_PREP_METHOD}   ${OPENBMC_BASE_URI}control/flash/bmc/action/PrepareForUpdate
${BMC_UPD_ATTR}      ${OPENBMC_BASE_URI}control/flash/bmc
${HOST_SETTING}      ${OPENBMC_BASE_URI}settings/host0

*** Keywords ***

Preserve BMC Network Setting
    [Documentation]   Preserve Network setting
    ${policy}=       Set Variable   ${1}
    ${value}=    create dictionary   data=${policy}
    Write Attribute   ${BMC_UPD_ATTR}  preserve_network_settings  data=${value}
    ${data}=      Read Properties   ${BMC_UPD_ATTR}
    should be equal as strings    ${data['preserve_network_settings']}   ${1}
    ...   msg=0 indicates network is not preserved


Activate BMC flash image
    [Documentation]   Activate and verify the update status
    ...               The status could be either one of these
    ...               'Deferred for mounted filesystem. reboot BMC to apply.'
    ...               'Image ready to apply.'
    @{img_path}=   Create List    /tmp/flashimg
    ${data}=   create dictionary   data=@{img_path}
    ${resp}=    openbmc post request    ${BMC_UPD_METHOD}   data=${data}
    should be equal as strings   ${resp.status_code}   ${HTTP_OK}

    ${data}=      Read Properties     ${BMC_UPD_ATTR}
    should be equal as strings   ${data["filename"]}   /tmp/flashimg
    should contain    ${data['status']}   to apply


Prepare For Update
    [Documentation]   Switch to update mode in progress. This method calls
    ...               the Abort method to remove the pending update if there
    ...               is any before code activation.
    ${data}=   create dictionary   data=@{EMPTY}
    ${resp}=    openbmc post request    ${BMC_PREP_METHOD}   data=${data}
    should be equal as strings   ${resp.status_code}   ${HTTP_OK}

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
    Execute Command On BMC  rm -f /tmp/flashimg
    scp.Put File  ${image_file_path}  ${targ_file_path}

    ${file_size}=  Execute Command On BMC  ls -lh ${targ_file_path}
    ${status}=  Run Keyword And Return Status
    ...  Should Contain  ${file_size}  32.0M  msg=Incomplete file transfer.
    [return]  ${status}


Check If File Exist
    [Arguments]  ${filepath}
    Log   \n PATH: ${filepath}
    OperatingSystem.File Should Exist  ${filepath}
    ...    msg=${filepath} doesn't exist [ ERROR ]

    Set Global Variable   ${FILE_PATH}  ${filepath}


System Readiness Test
    ${l_status}=   Run Keyword and Return Status
    ...   Verify Ping and REST Authentication
    Run Keyword If  '${l_status}' == '${False}'
    ...   Fail  msg=System not in ideal state to use [ERROR]


Validate BMC Version
    [Arguments]   ${args}=post
    # Check BMC installed version
    Open Connection And Log In
    ${version}   ${stderr}=    Execute Command   cat /etc/version
    ...    return_stderr=True
    Should Be Empty     ${stderr}
    # The File name contains the version installed
    Run Keyword If   '${args}' == 'before'
    ...    Should not Contain  ${FILE_PATH}   ${version}
    ...    msg=Same version already installed
    ...    ELSE
    ...    Should Contain      ${FILE_PATH}   ${version}
    ...    msg=Code update Failed


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
