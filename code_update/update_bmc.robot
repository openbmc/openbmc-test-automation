*** Settings ***
Documentation     Trigger code update to a target BMC.
...               Execution Method :
...               python -m robot -v OPENBMC_HOST:<hostname> 
...               -v FILE_PATH:<path/*all.tar>  update_bmc.robot

Resource          code_update_utils.robot

*** Variables ***

${FILE_PATH}      ${EMPTY}

*** Test cases ***

Initiate Code update BMC
    [Documentation]    BMC code update process initiation

    #-----------------------------------------
    # 1. Check the user input file path exist
    #-----------------------------------------
    Check If File Exist    ${FILE_PATH}

    #-----------------------------------------
    # 2. Ping Test and REST connection check
    #-----------------------------------------
    System Readiness Test
    BMC Version Validation  before

    #-----------------------------------------
    # 3. Preserve BMC Network setting
    #-----------------------------------------
    Preserve BMC Network Setting    ${1}
    BMC Network Preserve Policy

    #-----------------------------------------
    # 4. Copy image to /tmp/flashimg
    #-----------------------------------------
    SCP Tar Image File to BMC   ${FILE_PATH}

    #-----------------------------------------
    # 5. BMC update method for activation
    #-----------------------------------------
    Activate BMC flash image
    BMC Code Activation Status

    #-----------------------------------------
    # 6. Warm reset to apply activated flash
    #-----------------------------------------
    Trigger Warm Reset
    ${session_active}=   Check If warmReset is Initiated
    Run Keyword If   '${session_active}' == '${True}'
    ...    Fail  \n Warm reset failed [ ERROR ]


    #-----------------------------------------
    # 7. Wait for BMC to come online
    #-----------------------------------------
    Wait for BMC to respond
    Sleep  1 min
    BMC Version Validation
