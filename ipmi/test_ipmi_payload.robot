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
    # 01   instance 1 is activated.
    # 00   instance 1 is deactivated.
    ${payload_status}=  Get Payload Activation Status
    Should Contain Any  ${payload_status}  01  00


Test Activate Payload
    [Documentation]  Test activate payload via IPMI raw command.
    [Tags]  Test_Activate_Payload

    ${payload_status}=  Get Payload Activation Status
    Run Keyword If  '${payload_status}' == '01'  Deactivate Payload

    Activate Payload

    ${payload_status}=  Get Payload Activation Status
    Should Contain  ${payload_status}  01


Test Deactivate Payload
    [Documentation]  Test deactivate payload via IPMI raw command.
    [Tags]  Test_Deactivate_Payload

    ${payload_status}=  Get Payload Activation Status
    Run Keyword If  '${payload_status}' == '00'  Activate Payload

    Deactivate Payload

    ${payload_status}=  Get Payload Activation Status
    Should Contain  ${payload_status}  00


Test Get Payload Instance Info
    [Documentation]  Test Get Payload Instance via IPMI raw command.
    [Tags]  Test_Get_Payload_Instance_Info

    ${payload_status}=  Get Payload Activation Status
    Run keyword If  '${payload_status}' == '01'
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


*** Keywords ***

Get Payload Activation Status
    [Documentation]  Get payload activation status.

    ${resp}=  Run IPMI Command
    ...  ${IPMI_RAW_CMD['Payload']['Get_Payload_Activation_Status'][0]}

    @{resp}=  Split String  ${resp}

    ${payload_status}=  Set Variable  ${resp[1]}

    [return]  ${payload_status}


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
