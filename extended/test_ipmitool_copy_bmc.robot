*** Settings ***
Documentation   This testsuite updates the ipmitool on the bmc

Resource          ../lib/utils.robot
Resource          ../lib/connection_client.robot
Resource          ../lib/openbmc_ffdc.robot
Suite Teardown    Close All Connections

*** Variables ***

*** Test Cases ***
Copy IPMItool into BMC
      Should not be empty  ${IPMITOOL_HOST}
      Should not be empty  ${IPMITOOL_HOST_USERNAME}
      Should not be empty  ${IPMITOOL_HOST_PWD}
      Should not be empty  ${IPMITOOL_PATH}
      Copy IPMItool


