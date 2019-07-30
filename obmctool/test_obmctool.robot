*** Settings ***
Documentation  Verify OBMC tool's network fuctionality.

Resource  ../lib/resource.robot

Library  OperatingSystem
Library  String

Suite Setup     Suite Setup Execution
Test Teardown   Test Teardown Execution

*** Variables ***

${path}              openbmc-tools/thalerj/openbmctool.py
${sub}               s/\\/usr\\/bin\\/python3/
${ip}                10.7.7.7
${parser_a}          |grep status|awk -F\\" '{print$4}'
${parser_b}          |grep ${ip}|awk -F\\" '{print$4}'
${obmc_cmd}          ${EXECDIR}${/}${path} -H ${OPENBMC_HOST}
                     ...  -U ${OPENBMC_USERNAME}
                     ...  -P ${OPENBMC_PASSWORD}  network


*** Test Cases ***

Verify GetIP
    [Documentation]  Verify getIP option in openbmctool.
    [Tags]  Verify_GetIP

    ${Interface}=  Get Interface
    Log  ${Interface}
    ${op}=  Run  ${obmc_cmd} getIP -I ${Interface}${parser_a}
    Should Be Equal As Strings  '${op}'  'ok'

Verify GetDefaultGW
    [Documentation]  Verify getDefaultGW option in openbmctool.
    [Tags]  Verify_GetDefaultGW

    ${op}=  Run  ${obmc_cmd} getDefaultGW${parser_a}
    Should Be Equal As Strings  '${op}'  'ok'


Verify AddIP
    [Documentation]  Verify addIP option in openbmctool.
    [Tags]  Verify_AddIP

    ${Interface}=  Get Interface
    Run  ${obmc_cmd} addIP -I ${Interface} -a ${ip} -l 24 -p ipv4
    ${op}=  Run  ${obmc_cmd} getIP -I ${Interface}${parser_b}
    Should Be Equal As Strings  '${op}'  '${ip}'


Verify RemoveIP
    [Documentation]  Verify rmIP option in openbmctool.
    [Tags]  Verify_RemoveIP

    ${Interface}=  Get Interface
    ${rm_ip}=  Get IP
    Run  ${obmc_cmd} rmIP -I ${Interface} -a ${rm_ip}
    ${op}=  Run  ${obmc_cmd} getIP -I ${Interface}|grep ${rm_ip}
    Should Be Equal As Strings  '${op}'  ""


*** Keywords ***

Suite Setup Execution
    [Documentation]  Validate the setup.

    Should Not Be Empty  ${OPENBMC_HOST}  msg=BMC IP address not provided.
    ${res}=  Check OBMC Tool Exist
    ${py_version}=  Run  which python
    ${replace}=  Replace String Using Regexp  ${py_version}  /  \\/  count=-1
    Run Keyword if  '${res}' != 'True'
    ...  Run  git clone https://github.com/openbmc/openbmc-tools.git
    Run Keyword if  '${res}' != 'True'
    ...  Run  sed -i '${sub}${replace}/g' ${EXECDIR}${/}${path}

Check OBMC Tool Exist
    ${res}=  Run  ls openbmc-tools/thalerj/openbmctool.py 1> /dev/null ; echo $?
    Run Keyword if  '${res}'== '0'  Return From Keyword   True
    ...   ELSE    Return From Keyword    False

Get Interface
    ${res}=  Run  ${obmc_cmd} view-config|grep "ipv4"|awk -F/ 'NR==1{print$5}'
    [Return]  ${res}

Get IP
    ${res}=  Run
    ...  ${obmc_cmd} view-config|grep "Address"|awk -F\\" 'NR==2{print$4}'
    [Return]  ${res}


Test Teardown Execution
    [Documentation]  Do the post test teardown.

    Run  ${obmc_cmd} nwReset
