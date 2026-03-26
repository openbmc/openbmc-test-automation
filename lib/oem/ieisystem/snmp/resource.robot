*** Variables ***

# SNMP related parameters.

# 10.x.x.x series is a private IP address range and does not exist in
# our network, so this is chosen to avoid any adversary effect.
# It can be overridden by command line arguments.
${SNMP_MGR1_IP}       10.6.6.6
${SNMP_MGR2_IP}       10.6.6.7
${SNMP_MGR3_IP}       10.6.6.8
${out_of_range_ip}    10.6.6.256
${alpha_ip}           xx.xx.xx.xx
${less_octet_ip}      10.
${negative_ip}        -10.6.6.6
${empty_ip}           ${EMPTY}
${SNMP_DEFAULT_IP}    10.6.6.5
${snmp_manager_id}    ${0}
${snmp_manager_id_1}  ${1}
${snmp_manager_id_2}  ${2}
${subscription_uri}   /redfish/v1/Managers/1/SnmpService

# Valid and invalid IP and ports. Valid port range is 0-65535.
# Default port is 162.
${SNMP_DEFAULT_PORT}  ${162}
${NON_DEFAULT_PORT1}  ${1234}
${NON_DEFAULT_PORT2}  ${1235}
${out_of_range_port}  ${65536}
# non numeric value
${alpha_port}         ab
${negative_port}      ${-12}
${empty_port}         ${EMPTY}
${alphanumeric_port}  abc123

# User Name Password
${SNMP_MGR1_USERNAME}    admin
${SNMP_MGR1_PASSWORD}    admin

# SNMP Command
${SNMP_TRAPD_CMD}       sudo snmptrapd -f -c
...                     /etc/snmp/snmptrapd.conf -M /usr/share/snmp/mibs -m COMMER-MIB -Lo
${SNMP_TRAP_BMC_ERROR}  example.xyz.openbmc_project.Example.Elog.AutoTestSimple

# Generate BMC Error Command
${CMD_SEL_LOG_CLEAR}  busctl call xyz.openbmc_project.Logging /xyz/openbmc_project/logging/sel
...  xyz.openbmc_project.Logging.Create Create ssa{ss} xyz.openbmc_project.Common.Error.InternalFailure
...  xyz.openbmc_project.Logging.Entry.Level.Error 10 "ALERT_SRC" "" "APPEND_MSG" "" "DEVICE_SN" ""
...  "EVENT_DIR" "" "GENERATOR_ID" "32" "LOCATION_STR" "" "RECORD_TYPE" "1" "SENSOR_DATA"
...  "02FFFF" "SENSOR_PATH" "/com/otrd/state/SEL_Status" "_PID" "518"
${CMD_TEST_TRAP}  busctl call xyz.openbmc_project.Network.SNMP /xyz/openbmc_project/network/snmp/manager
...  com.otrd.Network.SNMPTrapTest.TrapTest traptest sq

# BMC Error Message
${SEL_LOG_CLEAR_EVENT}  "SEL_Status Log area reset/cleared${SPACE}${SPACE}"
${SNMP_TEST_TRAP_EVENT}  "SNMPTrap Test Event"
