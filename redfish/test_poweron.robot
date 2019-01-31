*** Settings ***
Resource         ../lib/resource.robot
Resource         ../lib/bmc_redfish_resource.robot

Suite Teardown   redfish.Logout

*** Variables ***

${POWER_ON}              On
${POWER_GRACEFULL_OFF}   GracefulShutdown
${POWER_FORCE_OFF}       ForceOff

${REDFISH_POWER_URI}     Systems/1/Actions/ComputerSystem.Reset

*** Test Cases ***

Test GET Call Request
    [Documentation]  Do the GET operation.

    ${resp}=  redfish.Get  Systems/1
    Log To Console  ${resp}

Test List Request
    [Documentation]  Do the GET list operation.

    ${resp}=  redfish.List Request  ${EMPTY}
    Log To Console  ${resp}

Test Enumerate Request
    [Documentation]  Do the GET enumerate operation.

    ${resp}=  redfish.Enumerate Request  ${EMPTY}
    Log To Console  ${resp}

Test Power On Call Request
    [Documentation]  Do the power on operations.

    Boot Action  GracefulShutdown


*** Keywords ***

Boot Action
    [Documentation]  Host boot to power on, off or reboot.
    [Arguments]  ${boot_option}

    # Description of argument(s):
    # boot_option   Type of allowed boot
    #              (e.g. "On", "ForceOff", "GracefulShutdown", "GracefulRestart").

    ${payload}=  Create Dictionary  ResetType=${boot_option}
    ${resp}=  redfish.Post  ${REDFISH_POWER_URI}  body=&{payload}
    Log To Console  ${resp}

