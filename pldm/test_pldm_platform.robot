*** Settings ***

Documentation    Module to test PLDM platform commands.

Library           ../lib/pldm_utils.py
Variables         ../data/pldm_variables.py
Resource          ../lib/openbmc_ffdc.robot
Resource          ../lib/bmc_redfish_resource.robot
Resource          ../lib/boot_utils.robot

Test Setup        Printn
Test Teardown     FFDC On Test Case Fail
Suite Teardown    Pldmtool Platform Suite Cleanup

*** Test Cases ***

Verify GetPDR
    [Documentation]  Verify GetPDR (Platform Descpritor Record) response message.
    [Tags]  Verify_GetPDR
    [Template]  Verify GetPDR For Record Handle

    # RecordHandle
    '0'
    '1'
    '2'


Verify SetStateEffecterStates
    [Documentation]  Verify set state effecter states response message.
    [Tags]  Verify_SetStateEffecterStates
    [Template]  Verify SetStateEffecterStates For Effecter States

    # EffecterStates (effecterID requestSet effecterState)
    '1 1 1'  # (effecterState -> 1 move OSStatus to 'standby')
    '1 1 2'  # (effecterState -> 2 move OSStatus to 'BootComplete')

*** Keywords ***

Verify GetPDR For Record Handle
    [Documentation]  Verify GetPDR (Platform Descpritor Record) for given input record handle.
    [Arguments]  ${record_handle}

    # Description of argument(s):
    # ${record_handle}  Record handle (e.g. '1').

    # pldm_output:
    # [responseCount]:                               29
    # [recordHandle]:                                1
    # [PDRHeaderVersion]:                            1
    # [PDRType]:                                     11
    # [recordChangeNumber]:                          0
    # [dataLength]:                                  19
    # [PLDMTerminusHandle]:                          0
    # [effecterID]:                                  1
    # [entityType]:                                  33
    # [entityInstanceNumber]:                        0
    # [containerID]:                                 0
    # [effecterSemanticID]:                          0
    # [effecterInit]:                                0
    # [effecterDescriptionPDR]:                      false
    # [compositeEffecterCount]:                      1
    # [stateSetID]:                                  196
    # [possibleStatesSize]:                          1
    # [possibleStates]:                              6

    ${pldm_cmd}=  Evaluate  $CMD_GETPDR % ${record_handle}
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Rprint Vars  pldm_output
    Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR}


Verify SetStateEffecterStates For Effecter States
    [Documentation]  Verify set state effecter states for given input effecter states.
    [Arguments]  ${effecter_states}

    # Description of argument(s):
    # ${effecter_states}   (effecterID requestSet effecterState).
    #                      e.g. '1 1 1'.

    # Example output:
    # SetStateEffecterStates ]: SUCCESS

    ${pldm_cmd}=  Evaluate  $CMD_SETSTATEEFFECTERSTATES % ${effecter_states}
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Rprint Vars  pldm_output
    Valid Value  pldm_output['setstateeffecterstates']  ['SUCCESS']


Pldmtool Platform Suite Cleanup
    [Documentation]    Reset BMC at suite cleanup.

    Redfish OBMC Reboot (off)
