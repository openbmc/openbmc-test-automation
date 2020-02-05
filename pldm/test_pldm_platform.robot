*** Settings ***

Documentation    Module to test PLDM platform commands.

Library          Collections
Library          String
Library          ../lib/pldm_utils.py
Variables        ../data/pldm_variables.py
Resource         ../lib/openbmc_ffdc.robot

Test Setup       Printn
Test Teardown    FFDC On Test Case Fail

*** Test Cases ***

Verify GetPDR

    [Documentation]  Verify GetPDR (Platform descpritor record)
    ...              response message.
    [Tags]  Verify_GetPDR

    # Example output:
    # responseCount: 29
    # recordHandle: 1
    # PDRHeaderVersion: 1
    # PDRType: 11
    # recordChangeNumber: 0
    # dataLength: 19
    # PLDMTerminusHandle: 0
    # effecterID: 1
    # entityType: 33
    # entityInstanceNumber: 0
    # containerID: 0
    # effecterSemanticID: 0
    # effecterInit: 0
    # effecterDescriptionPDR: false
    # compositeEffecterCount: 1
    # stateSetID: 196
    # possibleStatesSize: 1
    # possibleStates: 6

    # Verify GetPDR for record handle 0.
    ${pldm_cmd}=  Evaluate  $CMD_GETPDR % '0'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    ${result}=  Pldm Key Value Compare  ${pldm_output}  ${RESPONSE_DICT_GETPDR}
    Should Be Equal  ${result}  ${TRUE}

    # Verify GetPDR for record handle 1.
    ${pldm_cmd}=  Evaluate  $CMD_GETPDR % '1'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    ${result}=  Pldm Key Value Compare  ${pldm_output}  ${RESPONSE_DICT_GETPDR}
    Should Be Equal  ${result}  ${TRUE}

    # Verify GetPDR for record handle 2.
    ${pldm_cmd}=  Evaluate  $CMD_GETPDR % '2'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    ${result}=  Pldm Key Value Compare  ${pldm_output}  ${RESPONSE_DICT_GETPDR}
    Should Be Equal  ${result}  ${TRUE}


Verify SetStateEffecterStates 

    [Documentation]  Verify set state effecter states response message.
    [Tags]  Verify_SetStateEffecterStates

    # Example output:
    # SetStateEffecterStates : SUCCESS

    # Verify set state effecter states for record handle 1.
    ${pldm_cmd}=  Evaluate  $CMD_SETSTATEEFFECTERSTATES % '1 1 1'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['setstateeffecterstates']  'SUCCESS'
    
    # Verify set state effecter states for record handle 2.
    ${pldm_cmd}=  Evaluate  $CMD_SETSTATEEFFECTERSTATES % '1 1 2'
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Valid Value  pldm_output['setstateeffecterstates']  'SUCCESS'
