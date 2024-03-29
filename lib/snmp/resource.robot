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

# Valid and invalid IP and ports. Valid port range is 0-65535.
# Default port is 162.
${SNMP_DEFAULT_PORT}  ${162}
${NON_DEFAULT_PORT1}  ${186}
${NON_DEFAULT_PORT2}  ${196}
${out_of_range_port}  ${65536}
# non numeric value
${alpha_port}         ab
${negative_port}      ${-12}
${empty_port}         ${EMPTY}
${alphanumeric_port}  abc123

# User Name Password
${SNMP_MGR1_USERNAME}    ${EMPTY}
${SNMP_MGR1_PASSWORD}    ${EMPTY}

# SNMP Command
${SNMP_TRAPD_CMD}       snmptrapd -f -c
...                     /usr/local/etc/snmp/snmptrapd.conf -Lo
${SNMP_TRAP_BMC_ERROR}  example.xyz.openbmc_project.Example.Elog.AutoTestSimple
