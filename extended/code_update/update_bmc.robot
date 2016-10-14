*** Settings ***
Documentation     Trigger code update to a target BMC.
...               Execution Method :
...               python -m robot -v OPENBMC_HOST:<hostname>
...               -v FILE_PATH:<path/*all.tar>  update_bmc.robot
...
...               Code update method BMC using REST
...               Update work flow sequence:
...                 - User input BMC File existence check
...                 - Ping Test and REST authentication
...                 - Issue poweroff
...                 - Prepare for Update
...                 - Force reboot
...                 - Wait for BMC to come online clean
...                 - Wait for BMC_READY state
...                 - Apply preserve BMC Network setting
...                 - SCP image to BMC
...                 - Activate the flash image
...                 - Warm Reset BMC to activate code
...                 - Wait for BMC to come online time out 30 minutes
...                 - Version check post update

Resource          code_update_utils.robot

*** Variables ***

${FILE_PATH}      ${EMPTY}

*** Test cases ***

Initiate Code update BMC
    [Documentation]    BMC code update process initiation

    Check If File Exist    ${FILE_PATH}
    System Readiness Test
    ${status}=   Run Keyword and Return Status
    ...   Validate BMC Version   before

    Run Keyword if  '${status}' == '${False}'
    ...     Pass Execution   Same Driver version installed

    Initiate Power Off
    Prepare For Update
    # TODO: openbmc/openbmc#519
    Trigger Warm Reset via Reboot

    # Wait time is increased temporary to 10 mins due
    # to openbmc/openbmc#673
    Check If BMC is Up    10 min   10 sec

    Wait Until Keyword Succeeds
    ...    10 min   10 sec   Verify BMC State   BMC_READY

    Preserve BMC Network Setting
    SCP Tar Image File to BMC   ${FILE_PATH}

    Activate BMC flash image

    # TODO: openbmc/openbmc#519
    Run Keyword And Ignore Error    Trigger Warm Reset
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Trigger Warm Reset via Reboot

    Check If BMC is Up    30 min   10 sec
    Sleep  1 min
    Validate BMC Version
