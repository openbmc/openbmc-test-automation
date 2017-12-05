*** Settings ***
Library         SSHLibrary
Library         Dialogs
Library         String
Suite Teardown      Run Keyword If All Tests Passed     Begin_Installation 
#Suite Teardown  Close All Connections



*** Variables ***
${HOST}         ${empty}
${USERNAME}     root
${PASSWORD}     0penBmc
${INTERFACE}    ${empty}
${IP}           ${empty}
${NET}          ${empty}
${GATEWAY}      ${empty}
${DNS}          ${empty}
${MAC}          ${empty}
${DEV}          ${empty}
${FTP}          ${empty}



*** Test Cases ***
Connecting To Server
     open_connection_and_login

Configuring Interface
     Setup_interface

Select Installation Type
     Select_Media


*** Keywords ***

open_connection_and_login
    Open Connection    ${HOST}    port=2200
    Login    ${USERNAME}  ${PASSWORD}

Locate_interface
    WRITE                ip link | grep "ST,UP" | cut -d ":" -f 2 | cut -d" " -f 2 | head -1
    ${INTERFACE}=        Read      delay=1s
    ${INTERFACE}=        Split to lines    ${INTERFACE}
    ${INTERFACE}=        Set Variable   @{INTERFACE}[0]
    Set Suite Variable   ${INTERFACE}
    [Return]             ${INTERFACE}

Locate_Mac
    Write                ip link sh ${INTERFACE} | tail -1 | tr -s ' ' | cut -d" " -f 3
    ${MAC}=              Read      delay=1s
    ${MAC}=              Split to lines      ${MAC}
    ${MAC}=              Set Variable        @{MAC}[0]
    Set Suite Variable   ${MAC}
    [Return]             ${MAC}

Locate_Dev
     WRITE               ls -l /dev/disk/by-id/ |grep USB | egrep -v part | tr -s " " | cut -d" " -f 11 | tr -d "./"
     ${DEV}=             Read      delay=2s
     Log To Console      ${DEV}
     ${DEV}=             Split to lines      ${DEV}
     ${DEV}=             Set Variable        @{DEV}[0]
     Set Suite Variable  ${DEV}
     [Return]            ${DEV}

Setup_interface
     ${INTERFACE}=       Locate_interface
     ${MAC}=             Locate_Mac
     ${DEV}=             Locate_Dev
     WRITE       echo "auto ${INTERFACE}" > /etc/network/interfaces
     WRITE       echo "iface ${INTERFACE} inet static" >> /etc/network/interfaces
     Run keyword if      '${IP}'=='${empty}'
     ...                 Get Value From User    Type system IP address
     Set Suite Variable  ${IP}
     WRITE       echo "address ${IP}" >> /etc/network/interfaces
     Run keyword if      '${NET}'=='${empty}'
     ...                 Get Value From User      Type System Netmask
     Set Suite Variable  ${NET}
     WRITE       echo "netmask ${NET}" >> /etc/network/interfaces
     Run keyword if      '${GATEWAY}'=='${empty}'
     ...          Get Value From User      Type system Gateway
     Set Suite Variable  ${GATEWAY}
     WRITE       echo "gateway ${GATEWAY}" >> /etc/network/interfaces
     WRITE       route add default gw ${GATEWAY}
     Run keyword if      '${DNS}'=='${empty}'
     ...                 Get Value From User      Type DNS
     Set Suite Variable  ${DNS}
     WRITE       echo "nameserver ${DNS}" >> /etc/resolv.conf
     WRITE       ifdown ${INTERFACE}
     WRITE       ifup ${INTERFACE}
     Run keyword if      '${HOSTNAME}'=='${empty}'
     ...        Get Value From User      Type System Hostname
     Set Suite variable  ${HOSTNAME}
     Log To Console      \nSetting up the installation for: \nInterface= ${INTERFACE} \nIP= ${IP} \nMAC= ${MAC} \nGateway= ${GATEWAY} \nNetmask= ${NET} \nHostname= ${HOSTNAME} \nDNS= ${DNS} /nUSB on=${DEV}\n\nOk to continue??

Select_Media
     ${TYPE}=            Get Selection From User  Choose Installation Media      USB  FTP
     ${opt1}=            Run Keyword If      '${TYPE}'=='USB'        USB_Install
     ...                 ELSE IF             '${TYPE}'=='FTP'        Request_ftp3_credendtials
     ...                 ELSE                FAIL

USB_Install
     ${DEV}=             Locate_Dev
     WRITE               kexec -l /var/petitboot/mnt/dev/${DEV}/ppc/ppc64/vmlinuz --initrd /var/petitboot/mnt/dev/${DEV}/ppc/ppc64/initrd.img --append="ro root=/var/petitboot/mnt/dev/${DEV}/LiveOS/squashfs.img rd.dm=0 rd.md=0 nodmraid console=hvc0 ifname=net0:${MAC} ip=${IP}::${GATEWAY}:${NET}:${HOSTNAME}:net0:none nameserver=${DNS}"

Request_ftp3_credendtials
     ${USER}=            Get Value From User      Type ftp3 user ID
     ${PASSWD}=          Get Value From User      Type your ftp3 password       hidden=yes
     ${MyRepo}=          Set variable             ftp://${USER}:${PASSWD}@${FTP}/redhat/beta_cds/RHEL-ALT-7.4-RC-1/Server/ppc64le/os/
     Set Suite Variable  ${MyRepo}
     Set Client configuration      prompt=#
     WRITE               wget ${MyRepo}/ppc/ppc64/vmlinuz
     ${ro1}=             read      delay=1s
     WRITE               wget ${MyRepo}/ppc/ppc64/initrd.img
     ${ro2}=             read      delay=2s
     WRITE               kexec -l vmlinuz --initrd initrd.img --append="root=live:${MyRepo}/LiveOS/squashfs.img repo=${MyRepo} rd.dm=0 rd.md=0 nodmraid console=hvc0 ifname=net0:${MAC} ip=${IP}::${GATEWAY}:${NET}:${HOSTNAME}:net0:none nameserver=${DNS} "
     ${ro3}=             read until prompt

Begin_Installation
     WRITE               kexec -e


