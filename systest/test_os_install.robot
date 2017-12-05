*** Settings ***
Documentation  Pegas OS Installation through a USB, DVD or an FTP server.

Library        SSHLibrary
Library        Dialogs
Library        String
Resource       ../lib/resource.txt

Suite Teardown  Run Keyword If All Tests Passed  Begin Installation

*** Variables ***
${NET_IFACE}        ${EMPTY}
${OS_IP}            ${EMPTY}
${NETMASK}          ${EMPTY}
${GATEWAY}          ${EMPTY}
${DNS}              ${EMPTY}
${MAC_ADDRESS}      ${EMPTY}
${USB_DEVICE}       ${EMPTY}
${FTP_IP}           ${EMPTY}

*** Test Cases ***
FTP Install
     [Documentation]  Do OS installation through FTP server.
     Do connection
     Get Network Interface
     Get MAC Address
     Setup Interface
     Request FTP Credendtials
     Begin Installation

USB Install
     [Documentation]  Do OS installation through USB device.
     Do connection
     Get Network Interface
     Get MAC Address
     Setup Interface
     Get USB Device
     Get USB UUID
     USB Install
     Begin Installation

DVD Install
     [Documentation]  Do OS installation through DMD media.
     Do connection
     Get Network Interface
     Get MAC Address
     Setup Interface
     Get CD Device
     Get CD UUID
     CD Install
     Begin Installation

*** Keywords ***
Do connection
     [Documentation]  Generic user and password.
     open Connection  ${OPENBMC_HOST}  port=${PORT}
     Login  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
     Write  clear

Get Network Interface
     Write  ip link | grep "ST,UP" | cut -d ":" -f 2 | cut -d " " -f 2
     ${NET_IFACE}=  Read  delay=1s
     ${NET_IFACE}=  Split to lines  ${NET_IFACE}
     ${NET_IFACE}=  Set Variable  @{NET_IFACE}[0]
     Set Suite Variable  ${NET_IFACE}
     [Return]  ${NET_IFACE}

Get MAC Address
     Write  ip link sh ${NET_IFACE} | tail -1 | tr -s ' ' | cut -d" " -f 3
     ${MAC_ADDRESS}=  Read  delay=1s
     ${MAC_ADDRESS}=  Split to lines  ${MAC_ADDRESS}
     ${MAC_ADDRESS}=  Set Variable  @{mac}[0]
     Set Suite Variable  ${MAC_ADDRESS}
     [Return]  ${MAC_ADDRESS}

Get USB Device
     [Documentation]  Searching for an available USB for installation.
     Write  ls -l /dev/disk/by-id/ |grep USB | egrep -v part |
     ... tr -s " " | cut -d" " -f 11 | tr -d "./"
     ${USB_DEVICE}=  Read  delay=1s
     ${USB_DEVICE}=  Split to lines  ${USB_DEVICE}
     ${USB_DEVICE}=  Set Variable  @{usbdev}[1]
     Set Suite Variable  ${USB_DEVICE}
     [Return]  ${USB_DEVICE}

Get USB UUID
     [Documentation]  Getting UUID for USB.
     Write  ls -la /dev/disk/by-id/ | grep ${USB_DEVICE}-origin | tr -s " " |
     ... cut -d" " -f 11 | head -1 | tr -d "./"
     ${link}=  Read  delay=1s
     ${link}=  Split to Lines  ${link}
     ${link}=  Set Variable  @{link}[1]
     Write  ls -la /dev/disk/by-uuid | grep ${link} | tr -s " " |
     ... cut -d" " -f 9
     ${USBUUID}=  Read  delay=1s
     ${USBUUID}=  Split to Lines  ${USBUUID}
     ${USBUUID}=  Set Variable  @{USBUUID}[0]
     Set Suite Variable  ${USBUUID}
     [Return]  ${USBUUID}

Get CD Device
     [Documentation]  Searching for an available CD for installation.
     Write  ls -l /dev/disk/by-id/ |grep DVD | egrep -v part | tr -s " " |
     ... cut -d" " -f 11 | tr -d "./"
     ${CD_DEV}=  Read  delay=1s
     ${CD_DEV}=  Split to lines  ${CD_DEV}
     ${CD_DEV}=  Set Variable  @{CD_DEV}[1]
     Set Suite Variable  ${CD_DEV}
     [Return]  ${CD_DEV}

Get CD UUID
     [Documentation]  Getting UUID for CD.
     Write  ls -la /dev/disk/by-id/ | grep ${CD_DEV} | tr -s " " |
     ... cut -d" " -f 11 | head -1 | tr -d "./"
     ${link}=  Read  delay=1s
     ${link}=  Split to Lines  ${link}
     ${link}=  Set Variable  @{link}[1]
     Write  ls -la /dev/disk/by-uuid | grep ${link} | tr -s " " |
     ... cut -d" " -f 9
     ${CDUUID}=  Read  delay=1s
     ${CDUUID}=  Split to Lines  ${CDUUID}
     ${CDUUID}=  Set Variable  @{CDUUID}[0]
     Set Suite Variable  ${CDUUID}
     [Return]  ${CDUUID}

Setup Interface
     [Documentation]  Configuring network intarface.
     ${NET_IFACE}=  Get Network Interface
     ${MAC_ADDRESS}=  Get MAC Address
     ${USB_DEVICE}=  Get USB Device
     ${USBUUID}=  Get USB UUID
     ${CD_DEV}=  Get CD Device
     ${CDUUID}=  Get CDUUID
     Write  echo "auto ${NET_IFACE}" > /etc/network/interfaces
     Write  echo "iface ${NET_IFACE} inet static" >> /etc/network/interfaces
     Run keyword if  '${OS_IP}'=='${EMPTY}'
     ...  Get Value From User  type system ip address
     Set Suite Variable  ${OS_IP}
     Write  echo "address ${OS_IP}" >> /etc/network/interfaces
     Run keyword if  '${NETMASK}'=='${EMPTY}'
     ...  Get Value From User  type System netmask
     Set Suite Variable  ${NETMASK}
     Write  echo "netmask ${NETMASK}" >> /etc/network/interfaces
     Run keyword if  '${GATEWAY}'=='${EMPTY}'
     ...  Get Value From User  type system gateway
     Set Suite Variable  ${GATEWAY}
     Write  echo "gateway ${GATEWAY}" >> /etc/network/interfaces
     Write  route add default gw ${GATEWAY}
     Run keyword if  '${DNS}'=='${EMPTY}'
     ...  Get Value From User  type dns
     Set Suite Variable  ${DNS}
     Write  echo "nameserver ${DNS}" >> /etc/resolv.conf
     Write  ifdown ${NET_IFACE}
     Write  ifup ${NET_IFACE}
     Run keyword if  '${OS_HOSTNAME}'=='${EMPTY}'
     ...  Get Value From User  type System hostname
     Set Suite variable  ${OS_HOSTNAME}
     Log To Console  \nSetting up installation for: \nNetwork= ${NET_IFACE}
     ... \nip= ${OS_IP} \nmac= ${MAC_ADDRESS} \ngateway= ${GATEWAY} \nnetmask= ${NETMASK}
     ... \nhostname= ${OS_HOSTNAME} \ndns= ${DNS} \nUSB on= ${USB_DEVICE}\nUSB
     ... UUID= ${USBUUID}

Select Media
     ${type}=  Get Selection From User  Choose Installation Media  USB  FTP  DVD
     ${opt1}=  Run Keyword If  '${type}'=='USB'  USB Install
     ...  ELSE IF  '${type}'=='FTP'  Request ftp3 credendtials
     ...  ELSE IF  '${type}'=='DVD'
     ...  ELSE  FAIL

USB Install
     Write  kexec -l /var/petitboot/mnt/dev/${USB_DEVICE}/ppc/ppc64/vmlinuz
     ... --initrd /var/petitboot/mnt/dev/${USB_DEVICE}/ppc/ppc64/initrd.img
     ... --append="ro inst.stage2=hd:UUID=${USBUUID} rd.dm=0 rd.md=0 nodmraid
     ... console=hvc0 ifname=net0:${MAC_ADDRESS} ip=${OS_IP}::${GATEWAY}:${NETMASK}:
     ... ${OS_HOSTNAME}:net0:off nameserver=${DNS} inst.ks=ubi0:/home/root/wsp/
     ... ks.cfg"

CD Install
     Write  kexec -l /var/petitboot/mnt/dev/${CD_DEV}/ppc/ppc64/vmlinuz
     ... --initrd /var/petitboot/mnt/dev/${CD_DEV}/ppc/ppc64/initrd.img
     ... --append="ro inst.stage2=hd:UUID=${CDUUID} rd.dm=0 rd.md=0 nodmraid
     ... console=hvc0 ifname=net0:${MAC_ADDRESS} ip=${OS_IP}::${GATEWAY}:${NETMASK}:
     ... ${OS_HOSTNAME}:net0:off nameserver=${DNS}"

Request FTP Credendtials
     ${FTP_USER}=  Get Value From User  type ftp3 user ID
     ${FTP_PASSWD}=  Get Value From User  type your ftp3 password  hidden=yes
     ${FTP_REPO}=  Set variable  ftp://${FTP_USER}:${FTP_PASSWD}@${FTP_IP}/redhat/
     ...  release_cds/RHEL-ALT-7.4-GA/Server/ppc64le/os/
     Set Client configuration  prompt=#
     Write  wget ${FTP_REPO}/ppc/ppc64/vmlinuz
     ${ro1}=  read  delay=1s
     Write  wget ${FTP_REPO}/ppc/ppc64/initrd.img
     ${ro2}=  read  delay=2s
     Write  echo ks.cfg | cpio -c -o >> initrd.img
     Write  kexec -l vmlinuz --initrd initrd.img --append="root=live:${FTP_REPO}
     ... /LiveOS/squashfs.img repo=${FTP_REPO} rd.dm=0 rd.md=0 nodmraid console=
     ... hvc0 ifname=net0:${MAC_ADDRESS} ip=${OS_IP}::${GATEWAY}:${NETMASK}:${OS_HOSTNAME}:net0:
     ... none nameserver=${DNS} inst.ks=hd"
     ${ro3}=  read until prompt

Begin Installation
     Write  kexec -e
