*** Settings ***
Documentation       Schneider Power Distribution Unit (PDU) library

Library             Telnet
Library             SSHLibrary
Resource            ../../lib/pdu/pdu.robot


*** Keywords ***
Login To Schneider PDU Via SSH
    [Documentation]    Open PDU connection and login via SSH.

    Validate Prereq
    SSHLibrary.Open Connection    ${PDU_IP}    prompt=apc>
    ${connection_status}=    Run Keyword And Return Status
    ...    SSHLibrary.Login    ${PDU_USERNAME}    ${PDU_PASSWORD}
    RETURN    ${connection_status}

Login To Schneider PDU Via Telnet
    [Documentation]    Open PDU connection and login via telnet.

    Validate Prereq
    Telnet.Open Connection    ${PDU_IP}

    Telnet.Write    \n
    Telnet.Read Until    User Name :
    Telnet.Write    ${PDU_USERNAME}

    Telnet.Read Until    Password${SPACE}${SPACE}:
    Telnet.Write    ${PDU_PASSWORD}

    Set Prompt    apc>
    Telnet.Read Until Prompt
    Telnet.Write    ?
    Telnet.Read Until Prompt

Power Cycle
    [Documentation]    Perform PDU power cycle.

    # Sample output from schneider PDU console

    # Schneider Electric    Network Management Card AOS    v6.9.6
    # (c) Copyright 2020 All Rights Reserved    RPDU 2g APP    v6.9.6
    # -------------------------------------------------------------------------------
    # Name    : apc566BF4    Date : 07/07/2022
    # Contact    : Unknown    Time : 01:18:18
    # Location    : Unknown    User : Super User
    # Up Time    : 0 Days 12 Hours 17 Minutes    Stat : P+ N4+ N6+ A+
    # -------------------------------------------------------------------------------
    # IPv4    : Enabled    IPv6    : Enabled
    # Ping Response    : Enabled
    # -------------------------------------------------------------------------------
    # HTTP    : Disabled    HTTPS    : Enabled
    # FTP    : Disabled    Telnet    : Disabled
    # SSH/SCP    : Enabled    SNMPv1    : Disabled
    # SNMPv3    : Disabled
    # -------------------------------------------------------------------------------
    # Super User    : Enabled    RADIUS    : Disabled
    # Administrator    : Disabled    Device User    : Disabled
    # Read-Only User    : Disabled    Network-Only User    : Disabled

    # Type ? for command listing
    # Use tcpip command for IP address(-i), subnet(-s), and gateway(-g)

    # apc>?
    # System Commands:
    # ---------------------------------------------------------------------------
    # For command help: command ?

    # ?    about    alarmcount    boot    bye    cd
    # cipher    clrrst    console    date    delete    dir
    # dns    eapol    email    eventlog    exit    firewall
    # format    ftp    help    lang    lastrst    ledblink
    # logzip    netstat    ntp    ping    portspeed    prompt
    # pwd    quit    radius    reboot    resetToDef    session
    # smtp    snmp    snmptrap    snmpv3    system    tcpip
    # tcpip6    user    userdflt    web    whoami    xferINI
    # xferStatus

    # Device Commands:
    # ---------------------------------------------------------------------------
    # alarmList    bkLowLoad    bkNearOver    bkOverLoad    bkReading    bkPeakCurr
    # bkRestrictn devStartDly energyWise    olAssignUsr olCancelCmd olDlyOff
    # olDlyOn    olDlyReboot olGroups    olName    olOff    olOffDelay
    # olOn    olOnDelay    olRbootTime olReboot    olStatus    olUnasgnUsr
    # phLowLoad    phNearOver    phOverLoad    phReading    phPeakCurr    phRestrictn
    # prodInfo    userAdd    userDelete    userList    userPasswd

    # apc>olReboot 3,4,5,6,7,8
    # E000: Success

    # Enter command olOn <Outlet number> & verify success.

    ${connection_status}=    Login To Schneider PDU Via SSH

    IF    '${connection_status}' == '${False}'
        Set Suite Variable    ${lib_name}    Telnet
        Login To Schneider PDU Via Telnet
    ELSE
        Set Suite Variable    ${lib_name}    SSHLibrary
    END

    @{outlets}=    Split String    ${PDU_SLOT_NO}    separator=,
    FOR    ${outlet}    IN    @{outlets}
        Run Keyword    ${lib_name}.Write    olReboot ${outlet}
        ${output}=    Run Keyword    ${lib_name}.Read Until Prompt
        Should Contain    ${output}    Success    msg=Device Command Failed
    END
