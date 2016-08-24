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
    Validate BMC Version   before

    Preserve BMC Network Setting
    SCP Tar Image File to BMC   ${FILE_PATH}

    Activate BMC flash image

    Trigger Warm Reset
    # TODO: openbmc/openbmc#519
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Trigger Warm Reset via Reboot

    Wait for BMC to respond
    Sleep  1 min
    Validate BMC Version
