***Settings***
Documentation      Keywords for system related tools installation.
...                For HTX refer: https://github.com/open-power/HTX


Resource     utils_os.robot

***Keywords***

Prep OS For HTX Installation
    [Documentation]  Preparing OS for HTX tool install.

    Boot To OS
    ${status}=  Run Keyword And Return Status  HTX Tool Exist

    Return From Keyword If  '${status}' == 'True'
    ...  HTX tool already installed

    # Downloads the package lists from the repositories and "update"
    # them to get information on the newest versions of packages and
    # their dependencies.
    Log To Console  \n Update package list
    Execute Command On OS  sudo apt-get update

    # Download and install Git
    Log To Console  \n Install Git
    Execute Command On OS  sudo apt-get -y install git


Setup HTX On OS
    [Documentation]  Download and install HTX exerciser tool from github.

    # Download HTX source code from github
    Log To Console  \n Download HTX source code from github
    Execute Command  sudo git clone https://www.github.com/open-power/HTX

    # Download and install pre-requisite packages before compiling HTX
    Log To Console  \n Download pre-requisite packages before compiling HTX
    Execute Command On OS
    ...  sudo apt-get -y install gcc make libncurses5 g++ libdapl-dev

    # To fix ncurse compile warning and errors
    Execute Command On OS
    ...  sudo apt-get -y install libncurses5-dev libncursesw5-dev

    Execute Command On OS  sudo apt-get -y install libibverbs-dev librdmacm-dev

    # Compile HTX source code and install
    Log To Console  \n Compile HTX source code
    Execute Command On OS  cd HTX;sudo make all

    Log To Console  \n Installed compiled HTX binaries
    Execute Command On OS  sudo make install

