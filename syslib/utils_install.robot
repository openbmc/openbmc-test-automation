***Settings***
Documentation      Keywords for system related tools installation.
...                For HTX refer to https://github.com/open-power/HTX


Resource     utils_os.robot
Resource     ../lib/boot_utils.robot

***Keywords***

Prep OS For HTX Installation
    [Documentation]  Prepare OS for HTX tool installation.

    Boot To OS
    ${status}=  Run Keyword And Return Status  Tool Exist  htxcmdline

    Return From Keyword If  '${status}' == 'True'
    ...  HTX tool already installed.

    # Downloads the package lists from the repositories and "update"
    # them to get information on the newest versions of packages and
    # their dependencies.
    Log To Console  \n Update package list.
    Execute Command On OS  sudo apt-get update

    # Download and install Git.
    Log To Console  \n Install Git.
    Execute Command On OS  sudo apt-get -y install git


Prep OS For OPAL PRD Installation
    [Documentation]  Prepare OS for OPAL PRD tool installation.

    Boot To OS
    ${status}=  Run Keyword And Return Status  Tool Exist  opal-gard

    Return From Keyword If  '${status}' == 'True'  ${False}


    # Downloads the package lists from the repositories and "updates"
    # them to get information on the newest versions of packages and
    # their dependencies.
    Log To Console  \n Update package list.
    Execute Command On OS  sudo apt-get update


Setup HTX On OS
    [Documentation]  Download and install HTX exerciser tool from github.

    # Download HTX source code from github.
    Log To Console  \n Download HTX source code from github.
    Execute Command  sudo git clone https://www.github.com/open-power/HTX

    # Download and install pre-requisite packages before compiling HTX.
    Log To Console  \n Download pre-requisite packages before compiling HTX.
    Execute Command On OS
    ...  sudo apt-get -y install gcc make libncurses5 g++ libdapl-dev

    # To fix ncurse compile warning and errors.
    Execute Command On OS
    ...  sudo apt-get -y install libncurses5-dev libncursesw5-dev

    Execute Command On OS  sudo apt-get -y install libibverbs-dev librdmacm-dev

    # Compile HTX source code and install.
    Log To Console  \n Compile HTX source code.
    Execute Command On OS  cd HTX && sudo make all

    Log To Console  \n Installed compiled HTX binaries.
    Execute Command On OS  sudo make install


Install HTX On RedHat
    [Documentation]  Download and install HTX on Red Hat.
    [Arguments]  ${htx_rpm}
    # Description of argument(s):
    # htx_rpm    The url of the rqm file for htx.


    OS Execute Command  wget ${htx_rpm}  ignore_err=1
    @{str}=  Split String From Right  ${htx_rpm}  /  1
    SSHLibrary.File Should Exist  ${str[1]}
    # Remove the old version.
    OS Execute Command  rpm -e `rpm -qa | grep htx`  ignore_err=1
    OS Execute Command  rpm -Uvh ${str[1]}
    Tool Exist  htxcmdline


Setup Opal Prd On OS
    [Documentation]  Download and install opal prd tool.

    # Download and install PRD packages.
    Execute Command  sudo apt-get install opal-prd
    Execute Command  sudo apt-get install opal-utils

    # Reboot OS to activate installation.
    Host Reboot

    # Login to OS and verify opal prd installation working.
    Login To OS
    ${out}=  Execute Command  opal-gard list
    Should Contain  ${out}  No GARD entries to display

