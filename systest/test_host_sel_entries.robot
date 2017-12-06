*** Settings ***
Documentation    Test SEL records are being posted and SEL parsing tool works correctly.

Library  SSHLibrary
Resource  ../lib/rest_client.robot
Variables  ../data/variables.py
Suite Teardown  Close All Connections



*** Variables ***
${OS_HOST}          ${EMPTY}
${OS_USERNAME}      ${EMPTY}
${OS_PASSWORD}      ${EMPTY}
${SYSNAME}  ${EMPTY}
${FWLEVEL}  ${EMPTY}
${WSP_OP_TOOLS} =  witherspoon_mfg.OP.tools.tar.gz 


*** Test Cases ***
OP BMC SEL Entries
    # Opening  connection to server with tools
    Initialize OpenBMC
    ${enumerate_res} =  OpenBMC Get Request  ${BMC_LOGGING_ENTRY}/enumerate
    Log To Console	\neSEL coded generated
    ${msg}=  Catenate  SEPARATOR =  Response code:	${enumerate_res.status_code}
    ...  , Content:  ${enumerate_res.content}
    # Opening  connection to server with tools
    ${lcb} =  Open Connection    ${HOST}
    Login  ${USERNAME}	${PASSWORD}
    Set Client Configuration  prompt=$
    Set Client Configuration  timeout=5 minutes
    Create_directory_on_LCB
    
    Log To Console  \nCrating esel.out file    
    Create File	esel.out  ${msg}
    Put File  esel.out  /fspmount/witherspoon/${SYSNAME}/errlogs/
    Remove File  esel.out
    
    Log To Console  \nGetting witherspoon_mfg.OP.tools.tar.gz file and uncompressing it    
    Write  cd /afs/austin/projects/gfw/images/openpower9/${FWLEVEL}
    Write  cp /afs/austin/projects/gfw/images/openpower9/${FWLEVEL}/${WSP_OP_TOOLS} /fspmount/witherspoon/${SYSNAME}
    Write  cd /fspmount/witherspoon/${SYSNAME}
    Write Until Expected Output  tar xvf ${WSP_OP_TOOLS}\n  ./x86/bin/occBMCtool  8s  5s
    ${output} =  Read Until Prompt
    Write  rm ${WSP_OP_TOOLS}
    
    Log To Console  \nDecoding else.out file.    
    Write  /fspmount/witherspoon/${SYSNAME}/x86/bin/eSEL.pl -p decode_obmc_data -l /fspmount/witherspoon/${SYSNAME}/errlogs/esel.out Display data now.
    ${output} =  Read Until Prompt
    ${res}  ${value}  Run Keyword And Ignore Error  SSHLibrary.File Should Exist  /fspmount/witherspoon/${SYSNAME}/esel.out.txt
    Run Keyword if  '${res}'=='FAIL'
    ...  Fail  Failed to create esel.out.txt, eSEL.pl command filed output:\n${output}
    Write  cat esel.out.txt
    Set Client Configuration  prompt=$
    ${output} =  Read Until Prompt
    Log To Console  \nVerifying esel.out file was decoded correctly         
    ${matches} =  Get Regexp Matches  ${output}  .*Platform Event Log - .*x.*
    ${len} =  Get Length  ${matches}
    Run Keyword If  ${len} < 1
    ...  Fail  Error: Seems esel.out was not decoded correctly, check /fspmount/witherspoon/${SYSNAME}/esel.out.txt:\n${output}
    ...  ELSE
    ...  Log To Console  eSEL output log:\n${output}        


*** Keywords ***
Create directory on LCB
    [Documentation]  Create errlogs directory.
    Write  mkdir -p /fspmount/witherspoon/${SYSNAME} /fspmount/witherspoon/${SYSNAME}/errlogs
    SSHLibrary.Directory Should Exist  /fspmount/witherspoon/${SYSNAME}
    SSHLibrary.Directory Should Exist  /fspmount/witherspoon/${SYSNAME}/errlogs
    Write  chmod 777 /fspmount/witherspoon/${SYSNAME}