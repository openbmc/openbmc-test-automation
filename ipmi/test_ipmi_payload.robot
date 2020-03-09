*** Settings ***
Documentation       This suite tests IPMI Payload in OpenBMC.

Resource            ../lib/ipmi_client.robot
Resource            ../lib/openbmc_ffdc.robot
Variables           ../data/ipmi_raw_cmd_table.py


*** Test Cases ***

Test Get Payload Activation Status
    [Documentation]  Test get payload activation status
    [Tags]  Test_Get_Payload_Activation_Status

    # SOL is the payload currently supported for payload status.
    # Currently only support one SOL session.
    # Response Data
    # 01 01 00   instance 1 is activated.
    # 01 00 00   instance 1 is deactivated.
    ${resp}=  Get Payload Activation Status
    Should Contain Any  ${resp}  01 00 00  01 01 00


Test Activate Payload
    [Documentation]  Test activate payload via IPMI raw command.
    [Tags]  Test_Activate_Payload

    ${status}=  Get Payload Activation Status
    Run Keyword If  '${status}' == ' 01 01 00'  Verify Payload Already Active
    ...  ELSE  Verify Activate Payload

    Verify Payload Already Active


Test Deactivate Payload
    [Documentation]  Test deactivate payload via IPMI raw command.
    [Tags]  Test_Dctivate_Payload

    ${status}=  Get Payload Activation Status
    Run Keyword If  '${status}' == ' 01 00 00'  Verify Payload Already Deactivate
    ...  ELSE  Deactivate Payload

    Verify Payload Already Deactivate


Test Get Payload Instance Info
    [Documentation]  Test Get Payload Instance via IPMI raw command.

    # First four bytes should be 00 if given instance is not activated.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}
    Verify Activate Payload

    # First four bytes should be session ID when payload is activated.
    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][0]}
    Should Not Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Get_Payload_Instance_Info'][1]}

    Deactivate Payload


*** Keywords ***

Get Payload Activation Status
    [Documentation]  Get payload activation status.

    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Get_Payload_Activation_Status'][0]}

    [return]  ${resp}


Verify Activate Payload
    [Documentation]  Verify Activate Payload.

    ${resp}=  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Activate_Payload'][0]}
    Should Contain  ${resp}  ${IPMI_RAW_CMD['Payload']['Activate_Payload'][1]}


Verify Payload Already Active
    [Documentation]  Verify payload already active.

    # 80h: Payload already active on another session (required).
    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Activate_Payload'][0]}
    Should Contain  ${resp}  0x80


Verify Payload Already Deactivate
    [Documentation]  Verify payload already deactivate.

    # 80h: Payload already deactivated.
    ${resp}=  Run Keyword And Expect Error  *  Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Deactivate_Payload'][0]}
    Should Contain  ${resp}  0x80


Deactivate Payload
    [Documentation]  Deactivate Payload.

    Run IPMI Standard Command
    ...  raw ${IPMI_RAW_CMD['Payload']['Deactivate_Payload'][0]}
