*** Settings ***
Documentation   This module is for IPMI client for copying ipmitool to
...             openbmc box and execute ipmitool commands.

Resource        ../lib/resource.txt
Resource        ../lib/connection_client.robot

*** Keywords ***
Run IPMI Command
    [arguments]    ${args}
    Copy ipmitool
    ${output}   ${stderr}=  Execute Command    /tmp/ipmitool -I dbus raw ${args}  return_stderr=True
    Should Be Empty 	${stderr}
    set test variable    ${OUTPUT}     "${output}"

Run IPMI Standard Command
    [arguments]    ${args}
    Copy ipmitool
    ${stdout}    ${stderr}    ${output}=  Execute Command    /tmp/ipmitool -I dbus ${args}    return_stdout=True    return_stderr= True    return_rc=True
    Should Be Equal    ${output}    ${0}    msg=${stderr}
    [return]    ${stdout}

Copy ipmitool
    OperatingSystem.File Should Exist   tools/ipmitool      msg=The ipmitool program could not be found in the tools directory. It is not part of the automation code by default. You must manually copy or link the correct openbmc version of the tool in to the tools directory in order to run this test suite.

    Import Library      SCPLibrary      WITH NAME       scp
    scp.Open connection     ${OPENBMC_HOST}     username=${OPENBMC_USERNAME}      password=${OPENBMC_PASSWORD}
    scp.Put File    tools/ipmitool   /tmp
    SSHLibrary.Open Connection     ${OPENBMC_HOST}
    Login   ${OPENBMC_USERNAME}    ${OPENBMC_PASSWORD}
    Execute Command     chmod +x /tmp/ipmitool
