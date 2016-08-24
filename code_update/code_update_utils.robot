*** Settings ***
Documentation    Code update utility

Resource         ../lib/rest_client.robot
Resource         ../lib/connection_client.robot
Resource         ../lib/utils.robot
Library          OperatingSystem

*** Variables ***

${BMC_UPD_METHOD}   /org/openbmc/control/flash/bmc/action/update
${BMC_UPD_ATTR}     /org/openbmc/control/flash/bmc

*** Keywords ***

BMC Code Activation Status
    [Documentation]  Get BMC update status
    ${data}=      Read Properties     ${BMC_UPD_ATTR}
    should not be equal as strings    ${data['status']}     Idle
    should not be equal as strings    ${data['status']}     Unpack Error


Preserve BMC Network Setting
    [Documentation]   Preserve Network setting
    [Arguments]       ${args}
    ${policy} =       Set Variable   ${args}
    ${value} =    create dictionary   data=${policy}
    Write Attribute  ${BMC_UPD_ATTR}  preserve_network_settings  data=${value}


BMC Network Preserve Policy
    [Documentation]  Current BMC network preserve setting policy
    ${data}=      Read Properties   ${BMC_UPD_ATTR}
    should be equal as strings    ${data['preserve_network_settings']}   ${1}
    ...   msg=0 indicates network is not preserved


Activate BMC flash image
    @{img_path} =   Create List    /tmp/flashimg
    ${data} =   create dictionary   data=@{img_path}
    ${resp}=    openbmc post request    ${BMC_UPD_METHOD}   data=${data}
    should be equal as strings   ${resp.status_code}   ${HTTP_OK}
    ${content}=     To Json    ${resp.content}
    should be equal as strings   ${content["data"]["filename"]}   /tmp/flashimg 


SCP Tar Image File to BMC
    [arguments]         ${filepath}
    Open Connection for SCP
    Log To Console    \n Copying image to /tmp/flashimg
    scp.Put File      ${filepath}   /tmp/flashimg


Check If warmReset is Initiated
    Log To Console     \n Checking if reboot in progress
    # Ping would be still alive, so try SSH to connect if fails
    # the ports are down indicating reboot in progress
    ${alive}=   Run Keyword and Return Status
    ...    Open Connection And Log In
    Return From Keyword If   '${alive}' == '${False}'    ${False}
    [return]    ${True}


Check If File Exist
    [Arguments]  ${filepath}
    Log To Console   \n PATH: ${filepath}
    OperatingSystem.File Should Exist  ${filepath}
    ...    msg=${filepath} doesn't exist [ ERROR ]

    Set Global Variable   ${FILE_PATH}  ${filepath}

System Readiness Test
    ${l_status} =    Run Keyword   Ping and REST authentication
    Run Keyword If  '${l_status}' == '${False}'
    ...   Fail  msg=System not in ideal state to use [ERROR]


Ping and REST Authentication
    ${l_ping} =   Run Keyword And Return Status
    ...    Ping Host  ${OPENBMC_HOST}
    Return From Keyword If  '${l_ping}' == '${False}'    ${False}
    Log To Console   \n Ping test [OK]

    ${l_rest} =   Run Keyword And Return Status
    ...    Initialize OpenBMC
    Return From Keyword If  '${l_rest}' == '${False}'    ${False}
    Log To Console   \n REST test [OK]

    # Just to make sure the SSH is working for SCP
    Open Connection And Log In
    ${system}   ${stderr}=    Execute Command   hostname   return_stderr=True
    Should Be Empty     ${stderr}

    Log To Console    BMC host name: ${system}

    [return]    ${True}


Wait for BMC to respond
    Log To Console     \n Checking if BMC is online
    # Average code update takes from 15 -20 minutes
    # For worse case 30 minutes, check every 1 min
    Wait For Host To Ping  ${OPENBMC_HOST}  30 min   1 min


BMC Version Validation
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


