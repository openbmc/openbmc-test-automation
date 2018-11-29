*** Settings ***
Resource    ../lib/resource.txt
Library     ../lib/bmc_redfish.py  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

Suite Teardown   Suite Teardown Execution

*** Variables ***

${POWER_ON}              On
${POWER_GRACEFULL_OFF}   GracefulShutdown
${POWER_FORCE_OFF}       ForceOff

${REDFISH_POWER_URI}     Systems/1/Actions/ComputerSystem.Reset

*** Test Cases ***

Test GET Method
    [Documentation]  Do the GET operation.

    ${resp}=  Get Method  Systems/1
    Log To Console  ${resp.text}

Test List Method
    [Documentation]  Do the GET list operation.

    ${resp}=  List Method  ${EMPTY}
    Log To Console  ${resp}

Test Enumerate Method
    [Documentation]  Do the GET enumerate operation.

    ${resp}=  Enumerate Method  ${EMPTY}
    Log To Console  ${resp}

Test Power On Method
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

    ${resp}=  Post Method  ${REDFISH_POWER_URI}  ${action}  ${boot_option}
    Log To Console  ${resp}


Suite Teardown Execution
    Logout Session
