*** Settings ***

Documentation          Keywords for KCS and Lanplus interface command.

Resource               ../lib/ipmi_client.robot
Resource               ../lib/state_manager.robot
Resource               ../lib/common_utils.robot
Variables              ../data/ipmi_raw_cmd_table.py
Library                ../lib/ipmi_utils.py


*** Keywords ***

Verify KCS Interface Commands
    [Documentation]  Execute set of IPMI raw KCS interface commands and verify it is
    ...  executable from os host. Set of IPMI raw commands includes system interface
    ...  command.

    #### raw cmd for get device ID.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    #### Raw cmd for cold reset.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational
    ## Waiting time to get KCS interface enabled.
    Wait Until Keyword Succeeds  3 min  10 sec
    ...  Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    #### raw cmd for get device GUID.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['Device GUID']['Get'][0]}

    #### raw cmd for get IP addr.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_ip'][0]}

    #### raw cmd for get IP addr src.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_ip_src'][0]}

    #### raw cmd for get Dot1Q details.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_dot1q'][0]}

    #### raw cmd for get SDR Info.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['SDR_Info']['get'][0]}

    #### raw cmd for get Chassis status.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['Chassis_status']['get'][0]}

    #### raw cmd for get SEL INFO.
    Run Inband IPMI Raw Command  ${IPMI_RAW_CMD['SEL_Info']['get'][0]}

Verify Lanplus Interface Commands
    [Documentation]  Execute set of IPMI raw Command via lanplus interface and
    ...  verify it is executable from remote server. Set of IPMI raw commands
    ...  includes system interface command which should not execute via lanplus
    ...  interface.

    #### raw cmd for get device ID.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    #### Raw cmd for cold reset.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Cold Reset']['reset'][0]}

    Wait Until Keyword Succeeds  2 min  10 sec  Is BMC Unpingable
    Wait Until Keyword Succeeds  3 min  10 sec  Is BMC Operational
    ## Waiting time to get Lanplus interface enabled.
    Wait Until Keyword Succeeds  3 min  10 sec
    ...  Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device ID']['Get'][0]}

    #### raw cmd for get device GUID.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Device GUID']['Get'][0]}

    #### raw cmd for get IP addr.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_ip'][0]}

    #### raw cmd for get IP addr src.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_ip_src'][0]}

    #### raw cmd for get Dot1Q details.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['lan_parameters']['get_dot1q'][0]}

    #### raw cmd for get SDR Info.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['SDR_Info']['get'][0]}

    #### raw cmd for get Chassis status.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['Chassis_status']['get'][0]}

    #### raw cmd for get SEL INFO.
    Run External IPMI Raw Command  ${IPMI_RAW_CMD['SEL_Info']['get'][0]}
