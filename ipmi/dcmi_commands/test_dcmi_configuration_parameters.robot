*** Settings ***
Documentation    Module to test IPMI DCMI functionality.
Resource         ../../lib/ipmi_client.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/bmc_network_utils.robot
Resource         ../../lib/boot_utils.robot
Variables        ../../data/ipmi_raw_cmd_table.py
Variables        ../../data/dcmi_raw_cmd_table.py
Variables        ../../data/ipmi_variable.py
Library          ../../lib/bmc_network_utils.py
Library          ../../lib/ipmi_utils.py
Library          ../../lib/utilities.py
Library          JSONLibrary

*** Variables ***

*** Test Cases ***
Get Default DCMI Configuration Parameters For Param 2
    [Documentation]  Get discovery configuration default values.
    [Tags]  Get_Default_DCMI_Config_Parameter_For_Param_2

    ${dcmi_rsp}=  Get DCMI Configuration Parameter Response  2
    @{rsp}=  Split String  ${dcmi_rsp}
    Valid Value  rsp[1]  valid_values=['01']
    Valid Value  rsp[2]  valid_values=['05']
    Valid Value  rsp[3]  valid_values=['01']
    Valid Value  rsp[4]  valid_values=['00', '01']

Set DCMI Configuration For Param 2 Discovery Method Without Random Backoff For Option 12
    [Documentation]  Set discovery method without random backoff for option 12.
    [Tags]  Set_Option_12_Without_Random_Backoff
    [Teardown]  Set DCMI Configuration Parameter  2  ${default_value[4]}

    ${initial_value}=  Get DCMI Configuration Parameter Response  2
    @{default_value}=  Split String  ${initial_value}
    Set DCMI Configuration Parameter  2  Option_12_Without_Random_Backoff
    ${after_set}=  Get DCMI Configuration Parameter Response  2
    @{value_after_set}=  Split String  ${after_set}
    Valid Value  value_after_set[4]  valid_values=['01']

Check Error Completion Code For Param 2 Discovery Method Without Random Backoff For Option 60 And 43
    [Documentation]  Check error completion code for param 2 discovery method without random backoff
    [Tags]  Check_Error_Completion_Code_For_Param_2_Discovery_Method_Without_Random_Backoff_For_Option_60_And_43

    ${cmd}=  Catenate  0x2c 0x12 0xdc 0x02 0x00 0x02
    ${resp}=  Run Keyword And Expect Error  *
    ...  Run External IPMI Raw Command  ${cmd}
    Should Contain  ${resp}  rsp=0xd6): Cannot execute command, command disabled:  ignore_case=True

Check Error Completion Code For Param 2 Discovery Method With Random Backoff For Option 60 And 43
    [Documentation]  Check error completion code for param 2 discovery method with random backoff
    [Tags]  Check_Error_Completion_Code_For_Param_2_Discovery_Method_With_Random_Backoff_For_Option_60_And_43

    ${cmd}=  Catenate  0x2c 0x12 0xdc 0x02 0x00 0x82
    ${resp}=  Run Keyword And Expect Error  *
    ...  Run External IPMI Raw Command  ${cmd}
    Should Contain  ${resp}  rsp=0xd6): Cannot execute command, command disabled:  ignore_case=True

Check Error Completion Code For Param 2 Discovery Method With Random Backoff For Option 12
    [Documentation]  Check error completion code for param 2 discovery method with random backoff
    [Tags]  Check_Error_Completion_Code_For_Param_2_Discovery_Method_With_Random_Backoff_For_Option_12

    ${cmd}=  Catenate  0x2c 0x12 0xdc 0x02 0x00 0x81
    ${resp}=  Run Keyword And Expect Error  *
    ...  Run External IPMI Raw Command  ${cmd}
    Should Contain  ${resp}  rsp=0xd6): Cannot execute command, command disabled:  ignore_case=True

# Set DCMI Configuration For Param 2 Discovery Method With Random Backoff For Option 12
#     [Documentation]  Set discovery method with random backoff for option 12.
#     [Tags]  Set_Option_12_With_Random_Backoff
#     [Teardown]  Set DCMI Configuration Parameter  2  ${default_value[4]}

#     ${initial_value}=  Get DCMI Configuration Parameter Response  2
#     @{default_value}=  Split String  ${initial_value}
#     Set DCMI Configuration Parameter  2  Option_12_With_Random_Backoff
#     ${after_set}=  Get DCMI Configuration Parameter Response  2
#     @{value_after_set}=  Split String  ${after_set}
#     Valid Value  value_after_set[4]  valid_values=['81']

# Set DCMI Configuration For Param 2 Discovery Method Without Random Backoff For Option 60 And 43
#     [Documentation]  Set discovery method without random backoff for option 60 and 43.
#     [Tags]  Set_Option_60_With_Option_43_Without_Random_Backoff
#     [Teardown]  Set DCMI Configuration Parameter  2  ${default_value[4]}

#     ${initial_value}=  Get DCMI Configuration Parameter Response  2
#     @{default_value}=  Split String  ${initial_value}
#     Set DCMI Configuration Parameter  2  Option_60_With_Option_43_Without_Random_Backoff
#     ${after_set}=  Get DCMI Configuration Parameter Response  2
#     @{value_after_set}=  Split String  ${after_set}
#     Valid Value  value_after_set[4]  valid_values=['02']

# Set DCMI Configuration For Param 2 Discovery Method With Random Backoff For Option 60 And 43
#     [Documentation]  Set discovery method with random backoff for option 60 and 43.
#     [Tags]  Set_Option_60_With_Option_43_With_Random_Backoff
#     [Teardown]  Set DCMI Configuration Parameter  2  ${default_value[4]}

#     ${initial_value}=  Get DCMI Configuration Parameter Response  2
#     @{default_value}=  Split String  ${initial_value}
#     Set DCMI Configuration Parameter  2  Option_60_With_Option_43_With_Random_Backoff
#     ${after_set}=  Get DCMI Configuration Parameter Response  2
#     @{value_after_set}=  Split String  ${after_set}
#     Valid Value  value_after_set[4]  valid_values=['82']

*** Keywords ***
Get DCMI Configuration Parameter Response
    [Documentation]  Return DCMI configuration parameter response.
    [Arguments]  ${parameter}

    ${parameter_selector}=  Set Variable IF
    ...  '${parameter}' == '2'  DISCOVERY_CONFIGURATION

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['GET_DCMI_CONFIG_PARAMETER']['${parameter_selector}']}
    ${rsp}=  Run External IPMI Raw Command  ${cmd}

    [Return]  ${rsp}

Set DCMI Configuration Parameter
    [Documentation]  Set dcmi configuration parameter value.
    [Arguments]  ${parameter}  ${data}

    ${parameter_selector}=  Set Variable IF
    ...  '${parameter}' == '2'  DISCOVERY_CONFIGURATION

    ${parameter_data}=  Set Variable IF
    ...  '${data}' == 'Option_60_With_Option_43_Without_Random_Backoff' or '${data}' == '02'  OPTION_60_AND_43_WITHOUT_RANDOM_BACKOFF
    ...  '${data}' == 'Option_12_Without_Random_Backoff' or '${data}' == '01'  OPTION_12_WITHOUT_RANDOM_BACKOFF
    ...  '${data}' == 'Option_60_With_Option_43_With_Random_Backoff' or '${data}' == '82'  OPTION_60_AND_43_WITH_RANDOM_BACKOFF
    ...  '${data}' == 'Option_12_With_Random_Backoff' or '${data}' == '81'  OPTION_12_WITH_RANDOM_BACKOFF

    ${cmd}=  Catenate  ${DCMI_RAW_CMD['DCMI']['SET_DCMI_CONFIG_PARAMETER']['${parameter_selector}']['${parameter_data}']}
    Run External IPMI Raw Command  ${cmd}
