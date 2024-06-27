*** Settings ***
Documentation       Cyber Power Distribution Unit (PDU) library

Resource            ../../lib/pdu/pdu.robot
Library             Telnet
Library             SSHLibrary


*** Keywords ***
Login To Cyber PDU Via SSH
    [Documentation]    Open PDU connection and login via SSH.

    Validate Prereq
    SSHLibrary.Open Connection    ${PDU_IP}
    ${connection_status}=    Run Keyword And Return Status
    ...    SSHLibrary.Login    ${PDU_USERNAME}    ${PDU_PASSWORD}
    RETURN    ${connection_status}

Login To Cyber PDU Via Telnet
    [Documentation]    Open PDU connection and login via telnet.

    # CyberPowerSystems Inc., Command Shell v1.0
    # Login Name: cyber
    # Login_Pass: cyber

    Validate Prereq
    Telnet.Open Connection    ${PDU_IP}    timeout=5
    Set Telnetlib Log Level    TRACE
    Telnet.Set Newline    \r
    Telnet.Write    \n
    Telnet.Write    ${PDU_USERNAME}

    Telnet.Read Until    Login_Pass:
    Telnet.Write    ${PDU_PASSWORD}

Power Cycle
    [Documentation]    Perform PDU power cycle.

    ${connection_status}=    Login To Cyber PDU Via SSH

    IF    '${connection_status}' == '${False}'
        Set Test Variable    ${lib_name}    Telnet
        Login To Cyber PDU Via Telnet
    ELSE
        Set Test Variable    ${lib_name}    SSHLibrary
    END

    # Sample output from cyber PDU console

    # CyberPower System    ePDU Firmware Version    2.210
    # (c) Copyright 2010 All Rights Reserved    PDU30SWHVT16FNET
    # +------- Information -------------------------------------------------------+
    # Name    : PDU30SWHVT16FNET    Date : 07/05/2022
    # Contact    : Administrator    Time : 22:01:49
    # Location : Server Room    User : Admin
    # Up Time    : 178 days 22 hours 29 mins 11 secs.
    # +------- Console -----------------------------------------------------------+

    #    1- Device Manager
    #    2- Network Settings
    #    3- System
    #    4- Logout

    #    <ESC>- Back, <ENTER>- Select&Reflash
    # > 1

    # +------- PDU30SWHVT16FNET --------------------------------------------------+

    #    EPDU Information
    #    -----------------------------------------------------------------------
    #    Meter or Switch    : Switched    Model Enclosure    : 2U
    #    EPDU Orientation : Horizontal    Circuit Breaker    : Yes
    #    Bank Number    : 2    Outlet Number    : 16
    #    -----------------------------------------------------------------------

    #    1- Load Manager
    #    2- Outlet Control
    #    3- Outlet Configuration
    #    4- Outlet User Management
    #    5- See Schedule

    #    <ESC>- Back, <ENTER>- Select&Reflash
    # > 2

    # +------- Outlet Control ----------------------------------------------------+

    #    Outlet Status:
    #    ---------------------------------------------------------------------
    #    Outlet Number    :    1    2    3    4    5    6    7    8    9    10    11    12
    #    Current State    :    ON    ON    ON    ON    ON    ON    ON    ON    ON    ON    ON    ON
    #    ---------------------------------------------------------------------
    #    Outlet Number    :    13    14    15    16    17    18    19    20    21    22    23    24
    #    Current State    :    ON    ON    ON    ON

    #    1- Start a Control Command

    #    <ESC>- Back, <ENTER>- Select&Reflash
    # > 1

    # +------- Command Information: Step 1 ---------------------------------------+

    #    Step1. Input a Single outlet or outlet list with outlet index #.
    #    Note. Separate by symbol ','.

    #    <ESC>- Cancel
    # > 13, 14

    # +------- Command Information: Step 2 ---------------------------------------+

    #    Selected Outlet:
    #    16

    #    Step2. Select command to execute
    #    Selection:
    #    1- Turn On Immediate
    #    2- Turn Off Immediate
    #    3- Reboot Immediate
    #    4- Turn On Delay
    #    5- Turn Off Delay
    #    6- Reboot Delay
    #    7- Cancel Pending Command

    #    <ESC>- Cancel
    # >

    # +------- Command Information: Step 3 ---------------------------------------+

    #    Selected Outlet:
    #    16

    #    with Command:
    #    Cancel Pending Command

    #    Step3. Confirm your command.
    #    Note. Input 'yes' to Execute.

    #    <ESC>- Cancel
    # > yes

    # Select 1- Device Manager
    Run Keyword    ${lib_name}.Read
    Run Keyword    ${lib_name}.Write    1

    # Select 2- Outlet Control
    Run Keyword    ${lib_name}.Read
    Run Keyword    ${lib_name}.Write    2

    @{outlets}=    Split String    ${PDU_SLOT_NO}    separator=,
    FOR    ${outlet}    IN    @{outlets}
        # Select 1- Start a Control Command
        Run Keyword    ${lib_name}.Read
        Run Keyword    ${lib_name}.Write    1

        # Input a Single outlet or outlet list with outlet index #
        Run Keyword    ${lib_name}.Read
        Run Keyword    ${lib_name}.Write    ${outlet}

        # Select command to execute 3- Reboot Immediate
        Run Keyword    ${lib_name}.Read
        Run Keyword    ${lib_name}.Write    3

        # Input 'yes' to Execute
        Run Keyword    ${lib_name}.Read
        Run Keyword    ${lib_name}.Write    yes
        Run Keyword    ${lib_name}.Read
    END

    # Send ESC over telnet console and Select 4- Logout
    ${esc}=    Evaluate    chr(int(27))
    Set Test Variable    ${retry_count}    ${10}
    FOR    ${try}    IN RANGE    ${retry_count}
        Run Keyword    ${lib_name}.Write Bare    ${esc}
        ${cmd_out}=    Run Keyword    ${lib_name}.Read
        ${check}=    Run Keyword And Return Status    Should Contain    ${cmd_out}    4- Logout
        IF    ${check}==${FALSE}    CONTINUE
        IF    ${check}==${TRUE}
            Run Keyword    ${lib_name}.Write    4
            Run Keyword    ${lib_name}.Read
            ${lib_name}.Close All Connections
            BREAK
        END
    END
    [Teardown]    Run Keyword    ${lib_name}.Close All Connections
