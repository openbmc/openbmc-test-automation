*** Settings ***
Resource                ../lib/utils.robot

*** Variables ***
${BMC_STATE_URI}        /xyz/openbmc_project/state/bmc0/
${BMC_READY_STATE}      READY
${BMC_NOT_READY_STATE}  NOT.READY

*** Keywords ***
# Below are two main keywords for BMC state management

Is BMC Ready
    [Documentation]  Check if BMC state is Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_READY_STATE}   ${bmc_state}

Put BMC State
    [Arguments]  ${expected_state}
    ${bmc_state}=  Get BMC State
    Run Keyword If  ${bmc_state} == ${expected_state};
    ...  Log BMC is already in ${expected_state} state
    ...  ELSE  Initiate BMC Reboot
    
    Wait for BMC state  ${expected_state}

# All below are supportive keyword for above

Get BMC State
    [Documentation]  Return the state of BMC.
    ${state}=
    ...  Read Attribute  ${BMC_STATE_URI}  CurrentBMCState
    [Return]  ${state}
    
Initiate BMC Reboot
    [Documentation]  Initiate BMC reboot.
    ${resp}=  openbmc post request
    ...  ${BMC_STATE_URI}action/Reboot   data=${NIL}
    ${jsondata}=  To Json  ${resp.content}
    should be equal as strings  ${jsondata['status']}  ok

Is BMC Not Ready
    [Documentation]  Check if BMC state is Not Ready.
    ${bmc_state}=  Get BMC State
    Should Be Equal  ${BMC_NOT_READY_STATE}   ${bmc_state}

Wait for BMC state
    [Arguments]  ${expected_state}
    Run Keyword If  ${expected_state} == ${BMC_READY_STATE}
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Ready  
    ...  ELSE IF  ${expected_state} == ${BMC_NOT_READY_STATE}
    ...    Wait Until Keyword Succeeds
    ...    10 min  10 sec  Is BMC Not Ready
