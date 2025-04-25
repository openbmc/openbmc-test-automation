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

Test Tags         Pldm_Platform

*** Test Cases ***
Verify GetPDR
    [Documentation]  Verify GetPDR (Platform Descpritor Record) response message.
    [Tags]  Verify_GetPDR

    ${record_handle}=  Set Variable  ${1}
    # Note: Record handle count is unknown and it is dynamic in nature.
    #       Assuming there are 100 record handle.
    FOR   ${i}  IN RANGE  100
       ${next_record_handle}=  Run Keyword  Verify GetPDR For Record Handle  ${record_handle}
       IF  ${next_record_handle} == 0  BREAK
       ${record_handle}=  Set Variable  ${next_record_handle}
    END

Verify SetStateEffecterStates
    [Documentation]  Verify set state effecter states response message.
    [Tags]  Verify_SetStateEffecterStates
    [Template]  Verify SetStateEffecterStates For Effecter States

    # EffecterHandle  Count  EffecterStates (effecterID effecterState)

    '1'              '1'    '1 1'  # (effecterState -> 1 -> 'Boot Not Active')
    '1'              '1'    '1 2'  # (effecterState -> 2 -> 'Boot Completed')
    '2'              '1'    '1 9'  # (effecterState -> 9 -> 'System Power is in soft off mode')
    '3'              '1'    '1 6'  # (effecterState -> 6 -> 'Graceful Restart Requested')

*** Keywords ***

Verify GetPDR For Record Handle
    [Documentation]  Verify GetPDR (Platform Descpritor Record) for given input
    ...              record handle and return next record handle.
    [Arguments]  ${record_handle}

    # Description of argument(s):
    # ${record_handle}  Record handle.
    #                   e.g. '1' is record handle 'Boot Progress' (196).
    #                        '2' is record handle 'System Power State (260)'.
    #                        '3' is record handle 'Software Termination Status (129)'.

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

    IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_STATE_EFFECTER_PDR']}'
        Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR_SETSTATEEFFECTER}
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_PDR_FRU_RECORD_SET']}'
        Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR_FRURECORDSETIDENTIFIER}
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_PDR_ENTITY_ASSOCIATION']}'
        Log To Console  "Found PDR Type - PLDM_ENTITY_ASSOCIATION_PDR"
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_STATE_SENSOR_PDR']}'
        Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR_STATESENSORPDR}
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_NUMERIC_EFFECTER_PDR']}'
        Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR_NUMERICEFFECTERPDR}
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_TERMINUS_LOCATOR_PDR']}'
        Valid Dict  pldm_output  valid_values=${RESPONSE_DICT_GETPDR_TERMINUSLOCATORPDR}
    ELSE IF  '${pldm_output['PDRType']}' == '${PLDM_PDR_TYPES['PLDM_COMPACT_NUMERIC_SENSOR_PDR']}'
        Log To Console  "Found PDR Type - PLDM_COMPACT_NUMERIC_SENSOR_PDR'
    ELSE
        Fail  msg="Unknown PDR Type is received"
    END

    Should Be Equal As Strings  ${pldm_output['recordHandle']}  ${record_handle}
    RETURN  ${pldm_output['nextRecordHandle']}

Verify SetStateEffecterStates For Effecter States
    [Documentation]  Verify set state effecter states for given input effecter states.
    [Arguments]  ${effecter_handle}  ${count}  ${effecter_states}

    # Description of argument(s):
    # ${effecter_handle}   A handle that is used to identify and access the effecter (e.g. '1').
    #                      e.g. '1' is effecter handle 'Boot Progress'.
    #                           '2' is effecter handle 'System Power State'.
    # ${count}             The number of individual sets of effecter information (e.g. '1').
    # ${effecter_states}   (effecterID effecterState).
    #                      e.g. '1 1'.

    # Example output:
    # {
    #     "Response": "SUCCESS"
    # }

    ${pldm_cmd}=  Evaluate  $CMD_SETSTATEEFFECTERSTATES % (${effecter_handle}, ${count}, ${effecter_states})
    ${pldm_output}=  Pldmtool  ${pldm_cmd}
    Rprint Vars  pldm_output
    Valid Value  pldm_output['Response']  ['SUCCESS']

Pldmtool Platform Suite Cleanup
    [Documentation]    Reset BMC at suite cleanup.

    Redfish.Login
    Redfish OBMC Reboot (off)
