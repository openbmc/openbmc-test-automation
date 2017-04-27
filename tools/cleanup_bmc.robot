*** Settings ***
Documentation  Cleanup user patches from BMC.

Resource   ../lib/utils.robot

*** Variables ***

# User defined path to cleanup.
${PATH}

*** Test Cases ***

Celanup User Patches
    [Documentation]   Check leftover code and do the cleanup.

    Open Connection And Log In
    ${output}=  Execute Command  ls ${PATH} | wc -l
    Run Keyword If  ${output}!= 1
    ...  Remove Files
    Start Command  /sbin/reboot
    Check If BMC is Up
    ${output}=  Execute Command  ls ${PATH} | wc -l
    Should Be Equal  ${output}  1

*** Keywords ***

Remove Files
    [Documentation]  Remove leftover files in ${PATH} except python libraries.

    Write  cd ${PATH}
    Write  ls | grep -v python2.7 | xargs rm -rf
