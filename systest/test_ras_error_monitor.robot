*** Settings ***
Documentation    This robot script is created to test "OP:RAS:Error Monitor_Garrison" TC 
Library    SSHLibrary    60 seconds
Library    String    
Library    Collections
Resource    ../lib/connection_client.robot
Suite Setup     Open Connection And Log In
Suite Teardown  Close All Connections




*** Variables ***
${OS_ROOT_PASS}    ${EMPTY}
${HTTPS_PORT}    ${EMPTY}
${SSH_PORT}    ${EMPTY}
${OS_VERSION}    ${EMPTY}
${TARGET}    0x0 0x05010800 0x4000000000000000


*** Test Cases ***
Ras Error Monitor
    Set Client Configuration    prompt=#
    @{PACKAGES}     Create List    opal-prd    opal-utils
    # Install opal packages
    ${result}    Install Linux Packages   ${PACKAGES} 
    
    # Checking Opla service is active
    Log To Console    Checking OPAL service is active
    ${result} =    Chech if service is active    ${PACKAGES[0]}    
    Run keyword if    '${result}' == '${True}'   
    ...    Log To Console    Service is active
    ...    ELSE
    ...    Run Keywords
    ...    Log To Console    Service is down, triying to start it
    ...    AND
    ...    Log To Console    Starting service ${PACKAGES[0]}
    ...    AND
    ...    Run Keyword    Start service    ${PACKAGES[0]}
    
    # Lsit gard errors
    Log To Console    Checking for gard errors    
    ${result} =    Check Gard Errors
          
    # Clearing gard errors if there are
    Run Keyword If    '${result}' != '${True}' 
    ...    Run Keywords
    ...    Log To Console    Celaring all logs
    ...    AND
    ...    Clear Gard Errors
    ...    ELSE
    ...    Log To Console    No Errors Found    
    
    # Injecting error
    # TODO: Create Keyword to get full chip target
    Log To Console    \nInjecting error to ${TARGET}
    ${result} =     Inject Errors    ${TARGET}
    Run Keyword If    '${result}' == '${False}'    
    ...    Fail    Test Case failed due error could not be injected
    
    Log To Console    \nVerifying injected error is registered 
    ${result} =    Check Gard Errors
    
    Run Keyword If    '${result}'=='${True}'            
    ...    Fail    No errors Found
      
    Log To Console    \nError injected (ID- ERROR): ${result}
    ${result} =    Split String    ${result}    -
    Write    opal-gard show ${result[0]}
    ${output} =    Read Until Prompt 
    Log To Console    \nERROR ${output}
        



*** Keywords ***
############################################################################################################    
# Keyword to inject errors
############################################################################################################
Inject Errors
    [Documentation]    Keyword to inject errors by putscom
    [Arguments]    ${target}
    Set Client Configuration    timeout=2 minutes
    Write    putscom -c ${target}
    #Write    echo ${target}
    Log To Console    \nWating for reboot    
    ${match}    ${value}    Run Keyword And Ignore Error    Read Until Regexp    --== Welcome to Hostboot hostboot-.*/.* ==--
    Return From Keyword If    '${match}'=='FAIL'    ${True}
    Set Client Configuration    timeout=10 minutes
    Log To Console    \nWating for loging prompt
    Read Until Regexp    login:
    Set Client Configuration    timeout=10 seconds
    Write    ${OPENBMC_USERNAME}
    Read Until Regexp    Password:
    Write    ${OS_ROOT_PASS}            
    ${output} =    Read Until Prompt 
############################################################################################################




############################################################################################################    
# Keyword to inject errors
############################################################################################################
Check Gard Errors
    [Documentation]    Keyword to inject errors by putscom
    Set Client Configuration    timeout=10 seconds
    Write    opal-gard list
    ${match}    ${value}    Run Keyword And Ignore Error    Read Until Regexp    No GARD entries to display
    # Return True if there is no errors else continue checking for error id 
    Return From Keyword If    '${match}' == 'PASS'    ${True}        
    ${value} =    Split String    ${value}    +---------------------------------------+
    ${output} =    Split String   ${value[-1]}    |     
    [Return]    ${output[1]} - ${output[2]}    
    
############################################################################################################
    
    


############################################################################################################    
# Keyword to clear errors
############################################################################################################
Clear Gard Errors
    [Documentation]    Keyword to clear errors with opal utils 
    Set Client Configuration    timeout=10 minutes
    Write    opal-gard clear all
    ${output} =    Read Until Regexp    done    
    ${match}    ${value}    Run Keyword And Ignore Error    Should Contain    ${output}    done
    Set Client Configuration    timeout=10 seconds
    [Return]    ${match}
    
############################################################################################################ 
    
    


############################################################################################################
# Keyword to install opal packages
############################################################################################################
Install Linux Packages
    [Documentation]    Keyword to install  packages
    [Arguments]    ${packages}  
    ${error} =    Set Variable    command not foun
    
    &{repo_command}    Create Dictionary    Red Hat=yum -y install    SUSE=zypper -y install    Ubuntu=apt-get -y install        
    # getting OS Distro
    ${os_res} =    Check Os
    Log To Console    \nOS detected: ${os_res}
    
    # checking if packages are installed 
    ${str_join_packs}    Catenate    SEPARATOR=", "    @{packages}
    Log To Console    Checking if packages "${str_join_packs}" are installed
    ${packages_to_install} =    Check for packages   ${os_res}    ${packages}      
    # TODO: IF there is any packages to install, run this keword
    ${result} =    Get Length    ${packages_to_install}
    
    Run Keyword If    ${result} > 1
    ...    Log To Console    Installing packages...
    ...    ELSE
    ...    Return From Keyword    ${False}    
    Configure IBM Repo
    :FOR    ${element}  IN    @{packages_to_install}
    \    Write   &{repo_command}[${os_res}] ${element}
    \    ${output} =    Read Until Prompt
    \    Log To Console    ${output}    
    [Return]    ${False}
############################################################################################################




############################################################################################################    
# Keyword that returns the OS distro, it must receive as argument next list [u'Red Hat', u'SUSE', u'Ubuntu']
############################################################################################################
Check Os
    @{os_list}    Create List      Red Hat    SUSE    Ubuntu
    Write    cat /proc/version
    ${output} =    Read  delay=1s
    :FOR  ${element}  IN  @{os_list}    
    \    ${match}    ${value}    Run Keyword And Ignore Error    Should Contain    ${output}    ${element}
    \    Return From Keyword If    '${match}' == 'PASS'   ${element}  
    [Return]    ${False}
############################################################################################################
    
 

  
############################################################################################################    
# Keyword that returns if package is inatlled the list of OS distros are [u'Red Hat', u'SUSE', u'Ubuntu']
############################################################################################################
Check for packages
    [Arguments]       ${os}    ${packages}
    &{query_repo_command}    Create Dictionary    Red Hat=rpm -qa |grep    SUSE=rpm -qa |grep    Ubuntu=dpkg -l
    ${res} =    Create List   ${EMPTY}  
    :FOR  ${element}  IN  @{packages}
    \    Log To Console    Runnign query: &{query_repo_command}[${os}] ${element}    
    \    Write    &{query_repo_command}[${os}] ${element}   
    \    ${output} =    Read Until Prompt
    \    ${match}    ${value}    Run Keyword And Ignore Error    Should Contain    ${output}    ${element}  
    \    Run Keyword If    '${match}' == 'PASS'
    \    ...    Log To Console    Package ${element} already installed
    \    ...    ELSE
    \    ...    Run Keywords
    \    ...    Log To Console    Package ${element} not found
    \    ...    AND
    \    ...    Append To List   ${res}   ${element}    
    [Return]    ${res}
############################################################################################################
    
    
    

############################################################################################################    
# Keyword to check if Service is active
############################################################################################################
Chech if service is active
    [Documentation]    Keyword to check if Service is avtive or not, return True in case it is and False in
    ...     case it is not
    [Arguments]    ${service}
    write    service ${service} status -l
    ${output} =    Read Until Regexp    Active:.*active.*(running).              
    ${length} =  Get Length  ${output}   
    ${result}    Set Variable If    ${length} > 0    ${True}    ${False}    
    [Return]    ${result}
    
############################################################################################################
    



############################################################################################################    
# Keyword to configure IBM repo
############################################################################################################
Configure IBM Repo
    [Documentation]    Keyword to configure IBM repo
    [Arguments]    
    write    wget -N http://public.dhe.ibm.com/software/server/POWER/Linux/yum/download/ibm-power-repo-latest.noarch.rpm
    Read Until Prompt
    write    echo $?
    ${output} =    Read Until Prompt
    ${match} =    Split To Lines    ${output}   
    Run Keyword If    ${match[0]} != 0
    ...    Return From Keyword    ${False}
    Write    rpm -ivh ibm-power-repo-latest.noarch.rpm
    ${output} =    Read Until Prompt
        Write    /opt/ibm/lop/configure
    Write Until Expected Output    ${\n}    Do you agree with the above [y/n]?    30    .5   
    Write    y\n    
    ${output} =    Read Until Prompt
    [Return]    ${True}
    
############################################################################################################



############################################################################################################    
# Keyword to start service
############################################################################################################
Start service
    [Documentation]    Keyword to start a service it receives the service to be started and it return true,
    ...    in case it is successful and fales in case it is not
    [Arguments]    ${service}
    Write    service ${service} start
    Sleep    5s        
    ${output} =    Read Until Prompt
    ${result}    Chech if service is active    ${service}
    Run Keyword If    '${result}'=='${True}'
    ...    Log To Console    Service ${service} started successfully
    ...    ELSE
    ...    Run Keywords
    ...    Log To Console    Service ${service} start process failed
    ...    AND
    ...    Fail    Service needs to be Activated
    [Return]    ${result}
    
############################################################################################################    