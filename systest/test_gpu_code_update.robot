*** Settings ***
Documentation    Install latest GPU driver.
Library          SSHLibrary
Library          OperatingSystem
Library          String
Resource         ../syslib/utils_os.robot
Variables        ../data/variables.py
Suite Setup      Check Var No Empty
Suite Teardown   Close All Connections


*** Test Cases ***
GPU Code Update
    [Documentation]  Install GPU driver

    # TODO: Boot a system with standard firmware
    # Logging Target Host
    Login To OS  ${OS_HOST}  ${OS_USERNAME}  ${OS_PASSWORD}  target_host
    ${file}=    Download_Driver    ${DRIVER_PATH}    target_host:/tmp
    Log To Console  Cuda file saved at: ${file}
    # Set system to start installation
    Log To Console  Seting system before install Repos and CUDA driver
    Set System To Install Cuda
    # Setting needed repos EPEL and PEGAS
    Log To Console  Installing Repos EPEL and Pegas
    Set Pegas and EPEL Repos
    #Installing cuda's repo
    ${stdout}  ${stderr}=  Execute Command  yes | rpm -ivh ${file}
    ...    return_stderr=True
    ${result}=  Install Verify  ${stderr}
    Run Keyword if  '${result}'=='${False}'
    ...    Fail  rpm -ivh ${file} failed by ${stdout}
    # Installing Cuda driver
    ${stdout}  ${stderr}=  Execute Command  yum -y install cuda
    ...    return_stderr=True
    ${result}=  Install Verify  ${stdout}
    Run Keyword if  '${result}'!='Complete!'
    ...    Fail  yum -y install cuda failed by ${\n}${stdout}
    ${result}=  Execute Command On OS  dkms status
    Log To Console  ${\n}${result}
    Should Contain  ${result}  ${VERSION}

*** Keywords ***
Set System To Install Cuda
    [Documentation]  Set OS before install Driver

    ${rhel_packages}=  catenate  SEPARATOR=
    ...    kernel-devel kernel-headers gcc make gcc-
    ...    c++ numactl openssh-server wget net-tools libX11-devel mesa-libGLU-
    ...    devel freeglut-devel ntpdate
    ${sed}=  catenate  SEPARATOR=
    ...    sed -i 's/SELINUX=.*/SELINUX=permissive/'
    ...     /etc/selinux/config
    ${blacklist}=  catenate  SEPARATOR=
    ...    sudo echo "blacklist nouveau" > /etc/modprobe.d/
    ...    blacklist-nouveau.conf; sudo echo "options nouveau modeset=0" >
    ...    > /etc/modprobe.d/blacklist-nouveau.conf
    # Disable selinux enforcement
	Execute Command  ${sed}
	# Create NVIDIA blacklist file to prevent
	# open source GPU driver from loading.
    Execute Command  sudo rmmod nouveau
    # Adding the following content:
    Execute Command  ${blacklist}
    # Reload the file with one of these commands, depending upon linux distro
    ${os_dist}=  Check Os Distribution
    Run Keyword if  '${os_dist}'=='Red Hat'
    ...    Run Keywords
    ...    Execute Command  sudo dracut -f
    ...    AND
    ...    Execute Command  yum clean expire-cache
    ...    AND
    ...    Execute Command  sudo yum -y install ${rhel_packages}
    ...    AND
    ...    Execute Command  yes | yum remove $(rpm -qa |grep epel)
    ...    AND
    ...    Execute Command  yes | yum remove cuda
    Run Keyword if  '${os_dist}'=='Ubuntu'
    ...    Run Keywords
    ...    Execute Command  sudo update-initramfs -u
    ...    AND
    ...    Execute Command  sudo apt-get clean
    ...    AND
    ...    Execute Command  sudo apt-get -y install ${rhel_packages}
    Run Keyword if  '${os_dist}'=='SUSE'
    ...    Fail  SLES is not supported yet
    # Clean up from any older .run driver installation and other stuff
    Execute Command  rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia
    Execute Command  /usr/bin/nvidia-uninstall
    # Delete work around from prior nvidia driver before start installation
    Execute Command  rm -f /etc/modprobe.d/nvidia_stuff.conf
    Execute Command  rm -f /etc/modprobe.d/nvidia.conf
    Execute Command  rm -f /etc/modprobe.d/nvidia-uvm.conf
    Execute Command  rpm -e `rpm -qa | grep "nvidia\|cuda"`
    Execute Command  rm -fr /usr/local/cuda*

Check Os Distribution
    [Documentation]  Return OS distribution

    @{os_list}  Create List  Red Hat  SUSE  Ubuntu
    ${output}=  Execute Command On OS  cat /proc/version
    :FOR  ${element}  IN  @{os_list}
    \    ${match}  ${value}  Run Keyword And Ignore Error
    \    ...    Should Contain  ${output}  ${element}
    \    Return From Keyword If  '${match}'=='PASS'  ${element}
    [Return]  ${False}

Set Pegas and EPEL Repos
    [Documentation]  Set Pegas and EPEL Repos, ftp3 credentials needed

    ${repo}=  Set Variable  /etc/yum.repos.d/pegas.repo
    ${epel_rel}=  catenate  SEPARATOR=
    ...    yes | sudo yum install https://dl.fedoraproject.org/pub/epel/epel-r
    ...    elease-latest-7.noarch.rpm
    ${cred_repo}=  Split String  ${PEGAS_REPO_USER}  @
    ${pegas_repo}=  catenate  SEPARATOR=
    ...    "baseurl=ftp://${cred_repo[0]}%40${cred_repo[1]}:
    ...    ${PEGAS_REPO_PASS}@ftp3.linux.ibm.com//redhat/release_cds/
    ...    RHEL-ALT-7.4-GA/Server/ppc64le/os/" >> ${repo}
    Log  Setting EPEL repo
    ${match}  ${value}  Run Keyword And Ignore Error
    ...    Execute Command On OS  echo ${epel_rel}
    ${result}=  Run Keyword if  '${match}'=='FAIL'
    ...    Install Verify  ${value}
    Run Keyword if  ${result}==${False}
    ...    Fail  Fail to install epel repo
    Log  Setting Pegas repo
    Execute Command On OS  echo "[pegas]" > ${repo}
    Execute Command On OS  echo "name=Red Hat Enterprise Linux" >> ${repo}
    # TODO: Get path to latest version
    Execute Command On OS  echo ${pegas_repo}
    Execute Command On OS  echo "enabled=1" >> ${repo}
    Execute Command On OS  echo "gpgcheck=0" >> ${repo}
    Execute Command  yum clean all
    Execute Command  yum repolist

Install Verify
    [Documentation]  Verify process finished with possible values  
    [Arguments]  ${data}

    ${match}  ${value}  Run Keyword And Ignore Error
    ...    Should Contain  ${data}  already installed
    Return From Keyword If  '${match}'=='PASS'  already installed
    ${match}  ${value}  Run Keyword And Ignore Error
    ...    Should Contain  ${data}  metadata files removed
    Return From Keyword If  '${match}'=='PASS'  metadata files removed
    ${match}  ${value}  Run Keyword And Ignore Error
    ...    Should Contain  ${data}  Complete!
    Return From Keyword If  '${match}'=='PASS'  Complete!
    [Return]  ${False}

Download Driver
    [Documentation]  To copy files from source to target system, machine where
    ...    keyword is use must have write permitions.
    ...    Example: SCP_File | source:path | target:path
    [Arguments]  ${source}  ${target}

    Set Client Configuration  timeout=10 minutes
    # Checking if source is in correct format, is local or remote
    ${source_result}=  Check If Local  ${source}
    ${source_list}=  Split String  ${source}  :
    ${target_list}=  Split String  ${target}  :
    ${path_msg}=  catenate  SEPARATOR=
    ...    Wrong format for target system, Correct format:\n Remote: <ip>:
    ...    <user>:<pass>:<full path>\nLocal: :::<full path> or <fullpath>
    Run Keyword if  '${source_result}'=='Invalid Format'
    ...    or '${source_result}'=='File path not specified'
    ...    Fail  ${path_msg}  
    # To avoid download the file if same file exists locally
    ${match}  ${value}  Run Keyword And Ignore Error
    ...    OperatingSystem.File Should Exist  ${source_list[-1]}
    ${source_result}=  Set Variable If  '${match}'=='PASS'
    ...    local  ${source_result}

    Run Keyword if  '${source_result}'=='remote'
    ...    Run Keywords
    ...    Log  Getting file from ${source_list[0]}
    ...    AND
    ...    Login To OS  ${source_list[0]}  ${source_list[1]}  ${source_list[2]}

    ${file}=  Run Keyword if  '${source_result}'=='remote'
    ...    Get Filename Remote  ${source_list[-1]}
    ...  ELSE IF
    ...    Get Filename Local  ${source_list[-1]}

    # Downloading file
    Run Keyword if  '${source_result}'=='remote'
    ...    SSHLibrary.Get File  /${file[0]}/${file[-1]}
    ...  ELSE
    ...    Return From Keyword  /${file[0]}/${file[-1]}

    # Uploading file
    Switch Connection  ${target_list[0]}
    Log  Copying file ${file[-1]} to ${OS_HOST}:${target_list[1]}
    SSHLibrary.Put File  ${file[-1]}  ${target_list[1]}
    [Return]  /tmp/${file[-1]}


Get Filename Remote
    [Documentation]  Get file name from full path when is remote
    [Arguments]  ${path}

    ${file}=  Split String  ${path}  /
    ${path}=  Set Variable  ${file[1:-1]}
    ${path}  Catenate  SEPARATOR=/  @{path}
    SSHLibrary.Write  cd /${path}
    SSHLibrary.Write  ls -lt ${file[-1]} |head -1
    ${output}=  Read  delay=5s
    ${file}=  Split To Lines  ${output}
    ${file}=  Split String  ${file[0]}  ${SPACE}
    [Return]  ${path}  ${file[-1]}

Get Filename Local
    [Documentation]  Get file name from full path when is local
    [Arguments]  ${path}

    ${file}=  Split String  ${path}  /
    ${path}=  Set Variable  ${file[1:-1]}
    ${path}  Catenate  SEPARATOR=/  @{path}
    Run  cd /${path}
    Run  ls -lt ${file[-1]} |head -1
    ${output}=  Run  ls -lt ${file[-1]} |head -1
    ${file}=  Split String  ${path}  /
    [Return]  ${path}  ${file}

Check If Local
    [Documentation]  Return remote or local depending provided path
    [Arguments]  ${FILE_PATH}

    ${FILE_PATH}=  Split String  ${FILE_PATH}  :
    ${result}=  Get Length  ${FILE_PATH}
    Run Keyword If  ${result}==1
    ...    Return From Keyword  local
    Run Keyword If  ${result}!=4
    ...    Return From Keyword  Invalid Format
    # Parsing source driver path
    ${match_ip}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${FILE_PATH[0]}
    ${match_user}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${FILE_PATH[1]}
    ${match_pass}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${FILE_PATH[2]}
    ${match_path}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${FILE_PATH[3]}

    Run Keyword If  '${match_path}'=='FAIL'
    ...    Return From Keyword    File path not specified
    ...  ELSE
    ...    Return From Keyword If  '${match_ip}'=='FAIL' 
    ...    or '${match_user}'=='FAIL' or '${match_pass}'=='FAIL'  local
    [Return]  remote
    
Check Var No Empty
    [Documentation]  Verify all variables are provided correctly

    ${host}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${OS_HOST}
    Run Keyword If  '${host}'=='FAIL'
    ...    Run Keywords
    ...    Log  Host IP must be provided, i.e: -v HOST:<IP>
    ...    AND
    ...    Fail  HOST variable empty
    # Check OS_USERNAME var is not empty
    ${username}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${OS_USERNAME}
    Run Keyword If  '${username}'=='FAIL'
    ...    Run Keywords
    ...    Log  Host user must be provided, i.e: -v USERNAME:<user name>
    ...    AND
    ...    Fail  USERNAME variable empty
    # Check OS_PASSWORD var is not empty
    ${password}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${OS_PASSWORD}
    Run Keyword If  '${password}'=='FAIL'
    ...    Run Keywords
    ...    Log  Os password must be provided, i.e: -v PASSWORD:<user password>
    ...    AND      
    ...    Fail  PASSWORD variable empty
    # Check DRIVER_PATH var is not empty
    ${drive_path}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${DRIVER_PATH}
    ${path_msg}=  catenate  SEPARATOR=
    ...    Host password must be provided, i.e: -v Remote i.e. DRIVER_PATH:
    ...    <ip>:<user>:<pass>:<full path>\nLocal i.e. DRIVER_PATH:(:::
    ...    <full path> or <fullpath>)
    Run Keyword If  '${DRIVER_PATH}'=='FAIL'
    ...    Run Keywords
    ...    Log  ${path_msg}
    ...    AND
    ...    Fail  DRIVER_PATH variable empty
    # Check PEGAS_REPO_USER var is not empty
    ${pegas_repo}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${PEGAS_REPO_USER}
    ${pegas_repo_@}  ${value}  Run Keyword And Ignore Error
    ...    Should Contain  ${PEGAS_REPO_USER}  @
    Run Keyword If    '${pegas_repo}'=='FAIL' or '${pegas_repo_@}'=='FAIL'
    ...    Run Keywords
    ...    Log  User must be provided, i.e: -v PEGAS_REPO_USER:<user>@<domain>
    ...    AND
    ...    Fail    PEGAS_REPO_USER variable empty or missing domain
    # Check VERSION var is not empty
    ${version}  ${value}  Run Keyword And Ignore Error
    ...    Should Not Be Empty  ${VERSION}
    Run Keyword If  '${version}'=='FAIL'
    ...    Run Keywords
    ...    Log  Expected version needed, i.e: -v VERSION:<version>
    ...    AND
    ...    Fail  VERSION variable empty