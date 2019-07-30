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
Resource                ../../lib/common_utils.robot


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

    Get BMC Network Info  file_name=rest_op

    ${bmc_ip}=  Run  cat rest_op|grep -A1 ipv4|awk -F\\" 'NR==2{print$4}'
    ${rc}  ${config}=  Openbmctool Execute Command
    ...  network getIP -I ${interface}

    Should Not Be Empty  ${bmc_ip}
    Should Contain  ${config}  ${bmc_ip}

    Run  rm ${EXECDIR}${/}rest_op

Verify GetDefaultGW
    [Documentation]  Verify that openbmctool.py can run the getDefaultGW command.
    [Tags]  Verify_GetDefaultGW

    Get BMC Network Info  file_name=rest_op

    ${default_gw}=
    ...  Run  cat rest_op|grep DefaultGateway|awk -F\\" 'NR==1{print$4}'
    ${rc}  ${config}=  Openbmctool Execute Command
    ...  network getDefaultGW

    Should Not Be Empty  ${default_gw}
    Should Contain  ${config}  ${default_gw}

    Run  rm ${EXECDIR}${/}rest_op

Verify AddIP
    [Documentation]  Verify that openbmctool.py can run the addIP command.
    [Tags]  Verify_AddIP

    ${rc}  ${op}=  Openbmctool Execute Command
    ...  network addIP -I ${interface} -a "${ip}" -l 24 -p ipv4

    ${ip_address_rest}=  Wait And Get BMC IP Info
    Validate IP On BMC  ${ip}  ${ip_address_rest}


Verify RemoveIP
    [Documentation]  Verify that openbmctool.py can run the rmIP command.
    [Tags]  Verify_RemoveIP

    Openbmctool Execute Command
    ...  network addIP -I ${interface} -a ${ip} -l 24 -p ipv4
    ${ip_address_rest}=  Wait And Get BMC IP Info
    Validate IP On BMC  ${ip}  ${ip_address_rest}

    Openbmctool Execute Command
    ...  network rmIP -I ${interface} -a ${ip}

    ${ip_address_rest}=  Wait And Get BMC IP Info
    Validate Non Existence Of IP On BMC  ${ip}  ${ip_address_rest}



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

Get BMC Network Info
    [Documentation]  Get BMC network info via REST and populate
    ...              it into a given file in the current directory.
    [Arguments]  ${file_name}

    # Description of argument(s):
    # file_name: The name of the file to which the n/w info will be populated.

    ${resp}=  OpenBMC Get Request  ${uri}
    Create Binary File  ${EXECDIR}${/}${file_name}  ${resp.content}

Validate Non Existence Of IP On BMC
    [Documentation]  Verify that IP address is not present in set of IP addresses.
    [Arguments]  ${ip_address}  ${ip_data}

    # Description of argument(s):
    # ip_address  IP address to check (e.g. xx.xx.xx.xx).
    # ip_data     Set of the IP addresses present.

    Should Not Contain Match  ${ip_data}  ${ip_address}/*
    ...  msg=${ip_address} found in the list provided.

Wait And Get BMC IP Info
    [Documentation]  Wait and get system IP address and prefix length.

    # Note:Network restart takes around 15-18s after network-config with openbmctool.

    Sleep  ${NETWORK_TIMEOUT}s
    Wait For Host To Ping  ${OPENBMC_HOST}  ${NETWORK_TIMEOUT}
    @{list}=  Get BMC IP Info

    [Return]  @{list}
