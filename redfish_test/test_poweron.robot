*** Settings ***
Resource    ../lib/resource.txt
Resource    ../lib/bmc_redfish_resource.robot

Suite Teardown   Suite Teardown Execution

*** Variables ***

${POWER_ON}              On
${POWER_GRACEFULL_OFF}   GracefulShutdown
${POWER_FORCE_OFF}       ForceOff

${REDFISH_POWER_URI}     Systems/1/Actions/ComputerSystem.Reset

*** Test Cases ***

Test GET Call Request
    [Documentation]  Do the GET operation.

    bmc_redfish.Logout
    Initialize OpenBMC Redfish
    ${resp}=  bmc_redfish.Get  Systems/1
    Log To Console  ${resp.text}

Test List Request
    [Documentation]  Do the GET list operation.

    ${resp}=  List Request  ${EMPTY}
    Log To Console  ${resp}

Test Enumerate Request
    [Documentation]  Do the GET enumerate operation.

    ${resp}=  Enumerate Request  ${EMPTY}
    Log To Console  ${resp}

Test Power On Call Request
    [Documentation]  Do the power on operations.

    Boot Action  ResetType  GracefulShutdown


*** Keywords ***

Boot Action
    [Documentation]  Host boot to power on, off or reboot.
    [Arguments]  ${action}  ${boot_option}

    # Description of argument(s):
    # action        Resource action object name.
    # boot_option   Type of allowed boot
    #              (e.g. "On", "ForceOff", "GracefulShutdown", "GracefulRestart").

    ${resp}=  bmc_redfish.Post  ${REDFISH_POWER_URI}  ${action}  ${boot_option}
    Log To Console  ${resp}


Suite Teardown Execution
    bmc_redfish.Logout
