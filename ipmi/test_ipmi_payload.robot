*** Settings ***
Documentation       This suite tests IPMI Payload in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py


*** Test Cases ***

Test Get Payload Activation Status
    [Documentation]  Test get payload activation status.
    [Tags]  Test_Get_Payload_Activation_Status

    # SOL is the payload currently supported for payload status.
    # Currently supports only one SOL session.
    # Response Data
    # 01 01 00   instance 1 is activated.
    # 01 00 00   instance 1 is deactivated.
    ${resp}=  Get Payload Activation Status
    Should Contain Any  ${resp}  01 00 00  01 01 00


Test Activate Payload
    [Documentation]  Test activate payload via IPMI raw command.
    [Tags]  Test_Activate_Payload

    ${status}=  Get Payload Activation Status
    Run Keyword If  '${status}' == ' 01 01 00'
    ...    Run Keywords  Deactivate Payload  AND  Activate Payload
    ...  ELSE  Activate Payload


Test Deactivate Payload
    [Documentation]  Test deactivate payload via IPMI raw command.
    [Tags]  Test_Deactivate_Payload

    ${status}=  Get Payload Activation Status
    Run Keyword If  '${status}' == ' 01 00 00'
    ...    Run Keywords  Activate Payload  AND  Deactivate Payload
    ...  ELSE  Deactivate Payload


Test Get Payload Instance Info
    [Documentation]  Test Get Payload Instance via IPMI raw command.
    [Tags]  Test_Get_Payload_Instance_Info

    ${payload_status}=  Get Payload Activation Status
    Run keyword If  '${payload_status}' == ' 01 01 00'
    ...  Deactivate Payload

    # First four bytes should be 00 if given instance is not activated.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}
    Activate Payload

    # First four bytes should be session ID when payload is activated.
    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}

    Deactivate Payload


*** Keywords ***

Get Payload Activation Status
    [Documentation]  Get payload activation status.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Activation_Status'][0]}

    [return]  ${resp}


Activate Payload
    [Documentation]  Activate Payload.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Activate_Payload'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Activate_Payload'][1]}


Deactivate Payload
    [Documentation]  Deactivate Payload.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Deactivate_Payload'][0]}
    Should Be Empty  ${resp}
