*** Settings ***
Documentation  Cleanup left over code from BMC.

Resource   ../lib/utils.robot

*** Variables ***

# Path to cleanup.
${PATH}

*** Test Cases ***

Remove Old Files
    [Documentation]   Cleanup old patches from BMC.

    Open Connection And Log In
    ${output}=  Execute Command  ls ${PATH} | wc -l
    Run Keyword If  ${output}!= 1
    ...  Remove Files

*** Keywords ***
    [Documentation]  Remove all files in ${PATH} except python libraries.

Remove Files
    Write  cd ${PATH}
    Write  ls | grep -v python2.7 | xargs rm -rf
