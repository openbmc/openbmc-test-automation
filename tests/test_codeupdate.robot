*** Settings ***
Documentation  Test code update

Resource            ../lib/openbmc_ffdc.robot
Resource            ../lib/utils.robot
Resource           ../lib/connection_client.robot

Test Setup          Create Image Directory
Test Teardown       Delete Image Directory

*** Variables ***
${DEFAULT_FILENAME}=   pnor.squashfs.tar 
${DEFAULT_TFTP_SERVER}=    9.3.164.219
${DEFAULT_IMAGEDIR}=    /tmp/images/

*** Test Cases ***

Download Image via TFTP that doesn't exist
    [Documentation]  Download an image using TFTP Protocol
    ...   using a file name that doesn't exist
    [Tags]  Code_Update

    ${incorrect_file_name}=  Set Variable    wrong_pnor.squashfs.tar
    ${resp}=    TFTP Download   ${incorrect_file_name}  ${DEFAULT_TFTP_SERVER}
    ...                         ${DEFAULT_IMAGEDIR}  ${DEFAULT_FILENAME}
    Should Be Equal    ${resp}    ${1}


Download Image via TFTP using wrong server IP
    [Documentation]  Download an image using TFTP Protocol
    ...   using a wrong TFTP server IP address
    [Tags]  Code_Update

    ${incorrect_server_IP}=  Set Variable    8.8.8.8
    ${resp}=    TFTP Download   ${DEFAULT_FILENAME}  ${incorrect_server_IP}
    ...                         ${DEFAULT_IMAGEDIR}  ${DEFAULT_FILENAME}
    Should Be Equal    ${resp}    ${1}
 
Download Image via TFTP using same file name
    [Documentation]  Download an image using TFTP Protocol
    ...   using the same file name as that on the TFTP server
    [Tags]  Code_Update

    ${resp}=    TFTP Download
    Should Be Equal    ${resp}    ${0}

Download Image via TFTP using different file name
    [Documentation]  Download an image using TFTP Protocol
    ...   using a different file name as that on the TFTP server
    [Tags]  Code_Update

    ${new_file_name}=  Set Variable    test_pnor.squashfs.tar
    ${resp}=    TFTP Download   ${DEFAULT_FILENAME}  ${DEFAULT_TFTP_SERVER}  
    ...                         ${DEFAULT_IMAGEDIR}  ${new_file_name}
    Should Be Equal    ${resp}    ${0}


*** Keywords ***

TFTP Download
    [Arguments]  ${imageName}=${DEFAULT_FILENAME}  
    ...          ${serverAddress}=${DEFAULT_TFTP_SERVER}  
    ...          ${imageDir}=${DEFAULT_IMAGEDIR}
    ...          ${imageNewName}=${DEFAULT_FILENAME}

    # imageName      The name of the file to download.
    # serverAddress  The IP address of the TFTP server.
    # imageDir       The dir where the file will be downloaded to.
    # imageNewName   The name of the file created on the bmc machine.

    Open Connection And Log In 
    Execute Command   tftp -g -r ${imageName} ${serverAddress} -l ${imageDir}${imageNewName}
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${imageDir}${imageNewName} 
    ...   return_stderr=True  return_rc=True
    Close All Connections
    [Return]   ${rc}

Create Image Directory
    [Documentation]  Creates a directory in the image dir path
    ...   where all images will be stored.

    Open Connection And Log In
    Execute Command   mkdir -p ${DEFAULT_IMAGEDIR}
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${DEFAULT_IMAGEDIR}
    ...   return_stderr=True  return_rc=True
    Should Be Equal   ${rc}   ${0}

Delete Image Directory
    [Documentation]  Deletes the directory
    ...   where all images were stored.

    Open Connection And Log In
    Execute Command   rm -rf ${DEFAULT_IMAGEDIR}
    ${stdout}   ${stderr}   ${rc}=
    ...   Execute Command   ls -l ${DEFAULT_IMAGEDIR}
    ...   return_stderr=True  return_rc=True
    Should Be Equal   ${rc}   ${1}
