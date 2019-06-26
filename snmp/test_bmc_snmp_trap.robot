*** Settings ***
Documentation  This testing require special setup where SNMP trapd is
...            configured and installed. For download, installation and
...            configuration refer http://www.net-snmp.org/.

Resource      ../lib/snmp/resource.robot
Resource      ../lib/snmp/snmp_utils.robot
Resource      ../lib/openbmc_ffdc.robot

Suite Setup     Suite Setup Execution

Test Teardown   Test Teardown Execution


*** Test Cases ***

Send Trap From BMC And Verify
    [Documentation]  Send trap from BMC and verify.
    [Tags]  Send_Trap_From_BMC_And_Verify

    Configure SNMP Manager On BMC  ${SNMP_MGR1_IP}  ${SNMP_DEFAULT_PORT}  Valid

    Start SNMP Manager Listener

    BMC Execute Command  /tmp/tarball/bin/logging-test -c AutoTestSimple

    SSHLibrary.Switch Connection  snmp_server

    ${SNMP_LISTEN_OUT}=  Read  delay=1s

    SSHLibrary.Execute Command  sudo killall snmptrapd
    Should Contain  ${SNMP_LISTEN_OUT}  ${SNMP_TRAP_BMC_ERROR}

