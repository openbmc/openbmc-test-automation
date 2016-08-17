*** Settings ***
Resource        ../lib/utils.robot
Resource        ../lib/connection_client.robot

Suite Setup       Open Connection And Log In
Suite Teardown    Close All Connections

*** Variables ***

*** Test Cases ***

Reach System Steady State
    [Documentation]  Reboot the BMC, power off the Host and clear any previous
    ...              events
    Trigger Warm Reset
    Power Off Host
    Clear BMC Record Log

Update PNOR Image
    [Documentation]  Copy the PNOR image to the BMC /tmp dir and flash it
    Copy PNOR to BMC
    ${pnor_path}    ${pnor_basename}=   Split Path    %{PNOR}
    Flash PNOR     /tmp/${pnor_basename}
    Wait Until Keyword Succeeds  6 min    10 sec    Is PNOR Flash Done

Validate IPL
    [Documentation]  Power the host on, and validate the IPL
    Power On Host
    Wait Until Keyword Succeeds  10 min    30 sec    Is System State Host Booted


*** Keywords ***
