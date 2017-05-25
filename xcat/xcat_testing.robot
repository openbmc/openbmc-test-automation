*** Settings ***
Documentation   Module for testing BMC via XCAT.

Resource        ../lib/xcat/resource.txt
Resource        ../lib/xcat/xcat_utils.robot

Library         OperatingSystem
Library         String

Suite Setup  Validate XCAT Setup

*** Variables ***

${poweron_flag}   ON
${poweroff_flag}  OFF

*** Test Cases ***

Add BMC Nodes To XCAT
    [Documentation]  Connect and add BMC nodes.
    [Tags]  Add_BMC_Nodes_To_XCAT

    # Add BMC nodes one by one and check whether it is successfully added.
    : FOR  ${bmc}  IN  @{BMC_LIST}
    \  Add Nodes To XCAT  ${bmc}
    \  Validate Added Node  ${bmc}

Power On Via XCAT And Validate
    [Documentation]  Power on via XCAT and validate.
    [Tags]  Power_On_Via_XCAT_And_Validate

    # Power on each BMC node and validate the power status.
    : FOR  ${bmc}  IN  @{BMC_LIST}
    \  Power On Via XCAT  ${bmc}
    \  Validate Power Status Via XCAT  ${bmc}  ${poweron_flag}

Power Off Via XCAT And Validate
    [Documentation]  Power off via XCAT and validate.
    [Tags]  Power_Off_Via_XCAT_And_Validate

    # Power off each BMC node and validate the power status.
    : FOR  ${bmc}  IN  @{BMC_LIST}
    \  Power Off Via XCAT  ${bmc}
    \  Validate Power Status Via XCAT  ${bmc}  ${poweroff_flag}

Add Nodes To Group List
    [Documentation]  Add BMC nodes into group.
    [Tags]  Move_Added_Nodes_To_Group

    # Add BMC nodes to group and validate.
    : FOR  ${bmc}  IN  @{BMC_LIST}
    /  Add Nodes To Group  ${bmc}  ${GROUP}
    /  Validate Node Added In Group  ${bmc}  ${GROUP}

*** Keywords ***

Validate XCAT Setup
    [Documentation]  Validate XCAT setup.

    Open Connection And Login To XCAT

    # Check if XCAT is installed.
    ${cmd_output}=  Execute Command  ${XCAT_DIR_PATH}/lsxcatd -v
    Should Not Be Empty  ${cmd_output}  msg=XCAT not installed.

    Log  \n XCAT Version is: \n${cmd_output}

    # Get all the BMC nodes from the config file.
    ${nodes}=  Get List Of BMC Nodes
    # Make a list of BMC nodes.
    @{BMC_LIST}=  Split To Lines  ${nodes}
    Log To Console  BMC nodes to be added:\n ${BMC_LIST}
    Set Suite Variable  @{BMC_LIST}

Validate Power Status Via XCAT
    [Documentation]  Validate power status.
    [Arguments]  ${node}  ${flag}=ON

    ${status}=  Get Power Status  ${node}
    Run Keyword If  '${flag}' == 'ON'
    ...  Should Contain  ${status}  on  msg=Host is off.
    ...  ELSE  Should Contain  ${status}  off  msg=Host is on.
