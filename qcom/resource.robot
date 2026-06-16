*** Settings ***
Documentation    Common resource file for Qualcomm inband test suite.
...
...    Provides shared variables for EVB+RPI test environment.
...    BMC credentials reuse the standard framework variables:
...      ${OPENBMC_HOST}      - BMC IP address (passed at runtime via --variable)
...      ${OPENBMC_USERNAME}  - BMC SSH/Redfish username (default: root)
...      ${OPENBMC_PASSWORD}  - BMC SSH/Redfish password (default: 0penBmc)
...    Redfish URI variables (${REDFISH_BASE_URI}, ${REDFISH_MANAGERS_URI},
...    ${REDFISH_ACCOUNTS_URI}, etc.) are inherited from bmc_redfish_resource.robot.

Library          SSHLibrary
Library          Collections
Library          String
Library          OperatingSystem
Library          RequestsLibrary
Library          JSONLibrary
Library          Process
Library          DateTime

*** Variables ***
# RPI / SoC Host connection
${HOST_IP}                raspberrypi-4f8b
${HOST_USERNAME}          qualcomm
${HOST_PASSWORD}          qualcomm

*** Keywords ***
