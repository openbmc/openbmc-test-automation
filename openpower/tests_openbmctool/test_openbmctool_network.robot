*** Settings ***
Documentation  Verify OBMC tool's network fuctionality.


Library                 String
Library                 OperatingSystem
Library                 ../../lib/gen_print.py
Library                 ../../lib/gen_robot_print.py
Library                 ../../lib/openbmctool_utils.py
Library                 ../../lib/gen_misc.py
Library                 ../../lib/gen_robot_valid.py
Resource                ../../syslib/utils_os.robot
Resource                ../../lib/resource.robot
Resource                ../../lib/bmc_network_utils.robot
Resource                ../../lib/utils.robot


Suite Setup             Suite Setup Execution
Test Setup              Printn

*** Variables ***

${ip}                   10.5.5.5
${uri}                  \/xyz\/openbmc_project\/network\/enumerate
${parser_a}             |grep ${ip}|awk -F\\" '{print$4}'
${parser_b}             |grep "ipv4"|awk -F/ 'NR==1{print$5}'

*** Test Cases ***

Verify GetIP
    [Documentation]  Verify that openbmctool.py can run the getIP command.
    [Tags]  Verify_GetIP

    ${resp}=  OpenBMC Get Request  ${uri}
    Create Binary File  ${EXECDIR}${/}rest_op  ${resp.content}

    ${bmc_ip}=  Run  cat rest_op|grep -A1 ipv4|awk -F\\" 'NR==2{print$4}'
    ${rc}  ${config}=  Openbmctool Execute Command
    ...  network view-config

    Should Not Be Empty  ${bmc_ip}
    Should Contain  ${config}  ${bmc_ip}

    Run  rm ${EXECDIR}${/}rest_op

Verify GetDefaultGW
    [Documentation]  Verify that openbmctool.py can run the getDefaultGW command.
    [Tags]  Verify_GetDefaultGW

    ${resp}=  OpenBMC Get Request  ${uri}
    Create Binary File  ${EXECDIR}${/}rest_op  ${resp.content}

    ${default_gw}=
    ...  Run  cat rest_op|grep DefaultGateway|awk -F\\" 'NR==1{print$4}'
    ${rc}  ${config}=  Openbmctool Execute Command
    ...  network view-config

    Should Not Be Empty  ${default_gw}
    Should Contain  ${config}  ${default_gw}

    Run  rm ${EXECDIR}${/}rest_op

Verify AddIP
    [Documentation]  Verify that openbmctool.py can run the addIP command.
    [Tags]  Verify_AddIP

    ${rc}  ${op}=  Openbmctool Execute Command
    ...  network addIP -I ${interface} -a "${ip}" -l 24 -p ipv4

    ${rc}  ${op}=  Openbmctool Execute Command
    ...  network getIP -I ${interface}${parser_a}

    Should Be Equal As Strings  '${op.strip()}'  '${ip}'

Verify RemoveIP
    [Documentation]  Verify that openbmctool.py can run the rmIP command.
    [Tags]  Verify_RemoveIP

    Openbmctool Execute Command
    ...  network addIP -I ${interface} -a ${ip} -l 24 -p ipv4
    ${rc}  ${op}=  Openbmctool Execute Command
    ...  network getIP -I ${interface}${parser_a}
    Should Be Equal As Strings  '${op.strip()}'  '${ip}'

    Openbmctool Execute Command
    ...  network rmIP -I ${interface} -a ${ip}

    ${rc}  ${op}=  Openbmctool Execute Command
    ...  network getIP -I ${interface}|grep ${ip}
    Should Be Equal As Strings  '${op.strip()}'  ""


*** Keywords ***


Suite Setup Execution
    [Documentation]  Verify connectivity to run openbmctool commands.

    # Verify connectivity to the BMC host.
    ${bmc_version}=  Run Keyword And Ignore Error  Get BMC Version
    Run Keyword If  '${bmc_version[0]}' == 'FAIL'  Fail
    ...  msg=Could not connect to BMC ${OPENBMC_HOST} to get firmware version.

    # Verify can find the openbmctool.
    ${openbmctool_file_path}=  which  openbmctool.py
    Printn
    Rprint Vars  openbmctool_file_path

    # Get the version number from openbmctool.
    ${openbmctool_version}=  Get Openbmctool Version

    ${rc}  ${res}=  Openbmctool Execute Command  network view-config${parser_b}
    Set Suite Variable  ${interface}  ${res.strip()}

    Rprint Vars  openbmctool_version  OPENBMC_HOST  bmc_version[1]
