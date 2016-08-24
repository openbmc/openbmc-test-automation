*** Settings ***
Documentation    Code update utility

Resource         ../../lib/rest_client.robot
Resource         ../../lib/connection_client.robot
Resource         ../../lib/utils.robot
Library          OperatingSystem

*** Variables ***

${BMC_UPD_METHOD}   /org/openbmc/control/flash/bmc/action/update
${BMC_UPD_ATTR}     /org/openbmc/control/flash/bmc

*** Keywords ***

Preserve BMC Network Setting
    [Documentation]   Preserve Network setting
    ${policy} =       Set Variable   ${1}
    ${value} =    create dictionary   data=${policy}
    Write Attribute   ${BMC_UPD_ATTR}  preserve_network_settings  data=${value}
    ${data}=      Read Properties   ${BMC_UPD_ATTR}
    should be equal as strings    ${data['preserve_network_settings']}   ${1}
    ...   msg=0 indicates network is not preserved


Activate BMC flash image
    [Documentation]   Activate and verify the update status
    @{img_path} =   Create List    /tmp/flashimg
    ${data} =   create dictionary   data=@{img_path}
    ${resp}=    openbmc post request    ${BMC_UPD_METHOD}   data=${data}
    should be equal as strings   ${resp.status_code}   ${HTTP_OK}
    ${content}=     To Json    ${resp.content}
    should be equal as strings   ${content["data"]["filename"]}   /tmp/flashimg

    ${data}=      Read Properties     ${BMC_UPD_ATTR}
    should not be equal as strings    ${data['status']}     Idle
    should not be equal as strings    ${data['status']}     Unpack Error


SCP Tar Image File to BMC
    [arguments]         ${filepath}
    Open Connection for SCP
    scp.Put File      ${filepath}   /tmp/flashimg


Check If warmReset is Initiated
    # Ping would be still alive, so try SSH to connect if fails
    # the ports are down indicating reboot in progress
    ${alive}=   Run Keyword and Return Status
    ...    Open Connection And Log In
    Return From Keyword If   '${alive}' == '${False}'    ${False}
    [return]    ${True}


Check If File Exist
    [Arguments]  ${filepath}
    Log   \n PATH: ${filepath}
    OperatingSystem.File Should Exist  ${filepath}
    ...    msg=${filepath} doesn't exist [ ERROR ]

    Set Global Variable   ${FILE_PATH}  ${filepath}


System Readiness Test
    ${l_status} =   Run Keyword    Verify Ping and REST Authentication
    Run Keyword If  '${l_status}' == '${False}'
    ...   Fail  msg=System not in ideal state to use [ERROR]


Wait for BMC to respond
    # Average code update takes from 15 -20 minutes
    # For worse case 30 minutes, check every 1 min
    Wait For Host To Ping  ${OPENBMC_HOST}  30 min   1 min


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
    Open Connection And Log In

    ${rc}=  SSHLibrary.Execute Command
    ...     /sbin/reboot  return_stdout=False   return_rc=True
    Should Be Equal As Integers   ${rc}   0
