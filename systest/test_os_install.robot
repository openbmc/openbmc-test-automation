*** Settings ***
Documentation  Pegas OS Installation through an USB, DVD or an FTP server
Library  SSHLibrary
Library  Dialogs
Library  String
Suite Teardown  Run Keyword If All Tests Passed  Begin Installation


*** Variables ***
${host}  ${Empty}
${USERNAME}  root
${PASSWORD}  0penBmc
${interface}  ${Empty}
${ip}  ${Empty}
${net}  ${Empty}
${gateway}  ${Empty}
${dns}  ${Empty}
${mac}  ${Empty}
${usbdev}  ${Empty}
${ftp}  ${Empty}

*** Test Cases ***
Connecting To Server
     [Documentation]  Establish connection to the BMC
     Do connection

Configuring Network Interface
     [Documentation]  Setting up active network interface
     Setup Interface

#Create Install Configuration File
     #[Documentation]  Configuring Automated installation
     #Do Kickstart

Verify Media Selection
     [Documentation]  Select installation media
     Select Media



*** Keywords ***

Do connection
     [Documentation]  Generic user and password
     open Connection  ${host}    port=2200
     Login  ${USERNAME}  ${PASSWORD}
     Write  clear

Get Network Interface
     Write  ip link | grep "ST,UP" | cut -d ":" -f 2 | cut -d " " -f 2
     ${interface} =  Read  delay=1s
     ${interface} =  Split to lines  ${interface}
     ${interface} =  Set Variable  @{interface}[0]
     Set Suite Variable  ${interface}
     [Return]  ${interface}

Get MAC Address
     Write  ip link sh ${interface} | tail -1 | tr -s ' ' | cut -d" " -f 3
     ${mac} =  Read  delay=1s
     ${mac} =  Split to lines      ${mac}
     ${mac} =  Set Variable        @{mac}[0]
     Set Suite Variable  ${mac}
     [Return]  ${mac}

Get USB Device
     [Documentation]  Searching for an available USB for installation
     Write  ls -l /dev/disk/by-id/ |grep USB | egrep -v part | tr -s " " | cut -d" " -f 11 | tr -d "./"
     ${usbdev} =  Read  delay=1s
     ${usbdev} =  Split to lines  ${usbdev}
     ${usbdev} =  Set Variable  @{usbdev}[1]
     Set Suite Variable  ${usbdev}
     [Return]  ${usbdev}

Get USB UUID
     [Documentation]  Getting UUID for USB
     Write  ls -la /dev/disk/by-id/ | grep ${usbdev}-origin | tr -s " " | cut -d" " -f 11 | head -1 | tr -d "./"
     ${link} =  Read  delay=1s
     ${link} =  Split to Lines  ${link}
     ${link} =  Set Variable  @{link}[1]
     Write  ls -la /dev/disk/by-uuid | grep ${link} | tr -s " " | cut -d" " -f 9
     ${USBUUID} =  Read  delay=1s
     ${USBUUID} =  Split to Lines  ${USBUUID}
     ${USBUUID} =  Set Variable  @{USBUUID}[0]
     Set Suite Variable  ${USBUUID}
     [Return]  ${USBUUID}

Get CD Device
     [Documentation]  Searching for an available CD for installation
     Write  ls -l /dev/disk/by-id/ |grep DVD | egrep -v part | tr -s " " | cut -d" " -f 11 | tr -d "./"
     ${cd_dev} =  Read  delay=1s
     ${cd_dev} =  Split to lines  ${cd_dev}
     ${cd_dev} =  Set Variable  @{cd_dev}[1]
     Set Suite Variable  ${cd_dev}
     [Return]  ${cd_dev}

Get CD UUID
     [Documentation]  Getting UUID for CD
     Write  ls -la /dev/disk/by-id/ | grep ${cd_dev} | tr -s " " | cut -d" " -f 11 | head -1 | tr -d "./"
     ${link} =  Read  delay=1s
     ${link} =  Split to Lines  ${link}
     ${link} =  Set Variable  @{link}[1]
     Write  ls -la /dev/disk/by-uuid | grep ${link} | tr -s " " | cut -d" " -f 9
     ${CDUUID} =  Read  delay=1s
     ${CDUUID} =  Split to Lines  ${CDUUID}
     ${CDUUID} =  Set Variable  @{CDUUID}[0]
     Set Suite Variable  ${CDUUID}
     [Return]  ${CDUUID}



Setup Interface
     [Documentation]  Configuring network intarface
     ${interface}=  Get Network Interface
     ${mac} =  Get MAC Address
     ${usbdev} =  Get USB Device
     ${USBUUID} =  Get USB UUID
     ${cd_dev} =  Get CD Device
     ${CDUUID} =  Get CDUUID
     Write  echo "auto ${interface}" > /etc/network/interfaces
     Write  echo "iface ${interface} inet static" >> /etc/network/interfaces
     Run keyword if  '${ip}'=='${Empty}'
     ...  Get Value From User    type system ip address
     Set Suite Variable  ${ip}
     Write  echo "address ${ip}" >> /etc/network/interfaces
     Run keyword if  '${net}'=='${Empty}'
     ...  Get Value From User      type System netmask
     Set Suite Variable  ${net}
     Write  echo "netmask ${net}" >> /etc/network/interfaces
     Run keyword if  '${gateway}'=='${Empty}'
     ...  Get Value From User      type system gateway
     Set Suite Variable  ${gateway}
     Write  echo "gateway ${gateway}" >> /etc/network/interfaces
     Write  route add default gw ${gateway}
     Run keyword if  '${dns}'=='${Empty}'
     ...  Get Value From User      type dns
     Set Suite Variable  ${dns}
     Write  echo "nameserver ${dns}" >> /etc/resolv.conf
     Write  ifdown ${interface}
     Write  ifup ${interface}
     Run keyword if  '${hostname}'=='${Empty}'
     ...  Get Value From User  type System hostname
     Set Suite variable  ${hostname}
     Log To Console  \nSetting up the installation for: \nNetwork= ${interface} \nip= ${ip} \nmac= ${mac} \ngateway= ${gateway} \nnetmask= ${net} \nhostname= ${hostname} \ndns= ${dns} \nUSB on= ${usbdev}\nUSB UUID= ${USBUUID}

Select Media
     ${type} =  Get Selection From User  Choose Installation Media  USB  FTP  DVD
     ${opt1} =  Run Keyword If  '${type}'=='USB'  USB Install
     ...  ELSE IF  '${type}' == 'FTP'  Request ftp3 credendtials
     ...  ELSE IF  '${type}' == 'DVD'
     ...  ELSE  FAIL

USB Install
     Write  kexec -l /var/petitboot/mnt/dev/${usbdev}/ppc/ppc64/vmlinuz --initrd /var/petitboot/mnt/dev/${usbdev}/ppc/ppc64/initrd.img --append="ro inst.stage2=hd:UUID=${USBUUID} rd.dm=0 rd.md=0 nodmraid console=hvc0 ifname=net0:${mac} ip=${ip}::${gateway}:${net}:${hostname}:net0:off nameserver=${dns} inst.ks=ubi0:/home/root/wsp/ks.cfg"

DVD Install
     Write  kexec -l /var/petitboot/mnt/dev/${cd_dev}/ppc/ppc64/vmlinuz --initrd /var/petitboot/mnt/dev/${cd_dev}/ppc/ppc64/initrd.img --append="ro inst.stage2=hd:UUID=${CDUUID} rd.dm=0 rd.md=0 nodmraid console=hvc0 ifname=net0:${mac} ip=${ip}::${gateway}:${net}:${hostname}:net0:off nameserver=${dns}"


Request ftp3 credendtials
     ${USER} =  Get Value From User  type ftp3 user ID
     ${PASSWD} =  Get Value From User  type your ftp3 password  hidden=yes
     ${MyRepo} =  Set variable  ftp://${USER}:${PASSWD}@${ftp}/redhat/release_cds/RHEL-ALT-7.4-GA/Server/ppc64le/os/
     Set Client configuration  prompt=#
     Write  wget ${MyRepo}/ppc/ppc64/vmlinuz
     ${ro1} =  read  delay=1s
     Write  wget ${MyRepo}/ppc/ppc64/initrd.img
     ${ro2} =  read  delay=2s
     Write  echo ks.cfg | cpio -c -o >> initrd.img
     Write  kexec -l vmlinuz --initrd initrd.img --append="root=live:${MyRepo}/LiveOS/squashfs.img repo=${MyRepo} rd.dm=0 rd.md=0 nodmraid console=hvc0 ifname=net0:${mac} ip=${ip}::${gateway}:${net}:${hostname}:net0:none nameserver=${dns} inst.ks=hd"
     ${ro3} =  read until prompt

Begin Installation
     Write  kexec -e
