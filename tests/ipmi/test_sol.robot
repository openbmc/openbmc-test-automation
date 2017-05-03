*** Settings ***
Documentation       This suite tests IPMI SOL in OpenBMC.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot

Test Teardown       Post Test Case Execution

*** Variables ***

*** Test Cases ***

Verify SOL During Boot
    [Documentation]  Verify SOL during boot.
    [Tags]  Verify_SOL_During_Boot

    ${current_state}=  Get Host State Via External IPMI
    Run Keyword If  '${current_state}' == 'On'
    ...  Initiate Host PowerOff Via External IPMI
    Initiate Host Boot Via External IPMI  wait=${0}

    Activate SOL Via IPMI
    Wait Until Keyword Succeeds  10 mins  30 secs
    ...  Check IPMI SOL Output Content  Petitboot

Verify Deactivate Non Existing SOL
    [Documentation]  Verify deactivate non existing SOL session.
    [Tags]  Verify_Deactivate_Non_Existing_SOL

    ${resp}=  Deactivate SOL Via IPMI
    Should Contain  ${resp}  SOL payload already de-activated
    ...  case_insensitive=True


*** Keywords ***

Post Test Case Execution
    [Documentation]  Do the post test teardown.

    Deactivate SOL Via IPMI
    FFDC On Test Case Fail

Check IPMI SOL Output Content
    [Documentation]  Check if SOL has given content.
    [Arguments]  ${data}  ${file_path}=/tmp/sol_${OPENBMC_HOST}
    # Description of argument(s):
    # data       Content which need to be checked(e.g. Petitboot, ISTEP).
    # file_path  The file path on the local machine to check SOL content.
    #            By default it check SOL content from /tmp/sol_<BMC_IP>.

    ${rc}  ${output}=  Run and Return RC and Output  cat ${file_path}
    Should Be Equal  ${rc}  ${0}  msg=${output}

    Should Contain  ${output}  ${data}  case_insensitive=True
