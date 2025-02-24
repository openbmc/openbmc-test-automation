*** Settings ***
Library           Collections
Library           String
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../data/variables.py

*** Variables ***

# By default power, support x86 as well.
${PLATFORM_ARCH_TYPE}             power

# FFDC Redfish OEM path /<oem>/v1/
${OEM_REDFISH_PATH}               ${EMPTY}

${REDFISH_SUPPORT_TRANS_STATE}    ${1}

# By default Delete all Redfish session per boot run.
${REDFISH_DELETE_SESSIONS}        ${1}

${OPENBMC_MODEL}           ${EMPTY}
${OPENBMC_HOST}            ${EMPTY}
${DBUS_PREFIX}             ${EMPTY}
${PORT}                    ${EMPTY}

# BMC ethernet eth0 and eth1 for multiple interfaces.
# By default eth0 is assigned with OPENBMC_HOST
${OPENBMC_HOST_ETH0}       ${OPENBMC_HOST}
${OPENBMC_HOST_ETH1}       ${EMPTY}


# AUTH_SUFFIX here is derived from variables.py
${AUTH_URI}                https://${OPENBMC_HOST}${AUTH_SUFFIX}
${OPENBMC_USERNAME}        root
${OPENBMC_PASSWORD}        ${EMPTY}
${OPENBMC_ADMIN_USERNAME}  admin
${OPENBMC_ADMIN_PASSWORD}  ${EMPTY}

# For users privilege admin or sudo.
${USER_TYPE}               ${EMPTY}

${MANAGER_ID}              bmc
${CHASSIS_ID}              chassis
${SYSTEM_ID}               system

# MTLS_ENABLED indicates whether mTLS is enabled.
${MTLS_ENABLED}            False
# Valid mTLS certificate for authentication.
${VALID_CERT}              ${EMPTY}
# Path of mTLS certificates directory.
${CERT_DIR_PATH}           ${EMPTY}

${IPMI_USERNAME}           root
# Assign BMC password as default. User can input using -v option to key in
# IPMI password if different.
${IPMI_PASSWORD}           ${OPENBMC_PASSWORD}

${OPENBMC_REBOOT_TIMEOUT}   ${10}

# IPMI_COMMAND here is set to "External" by default. User
# can override to "Dbus" from command line.
${IPMI_COMMAND}        External

# IPMI chipher default.
${IPMI_CIPHER_LEVEL}   ${17}

# IPMI timeout default.
${IPMI_TIMEOUT}        ${3}
${GEN_ID_BYTE_1}       ${20}
${GEN_ID_BYTE_2}       ${00}

# Log default path for IPMI SOL.
${IPMI_SOL_LOG_FILE}    ${EXECDIR}${/}logs${/}sol_${OPENBMC_HOST}

# IPMI SOL console output types/parameters to verify.
${SOL_BIOS_OUTPUT}          ${EMPTY}
${SOL_LOGIN_OUTPUT}         ${EMPTY}

# PDU related parameters
${PDU_TYPE}         ${EMPTY}
${PDU_IP}           ${EMPTY}
${PDU_USERNAME}     ${EMPTY}
${PDU_PASSWORD}     ${EMPTY}
${PDU_SLOT_NO}      ${EMPTY}

# User define input SSH and HTTPS related parameters
${SSH_PORT}         22
${HTTPS_PORT}       443
${IPMI_PORT}        623
${HOST_SOL_PORT}    2200
${OPENBMC_SERIAL_HOST}      ${EMPTY}
${OPENBMC_SERIAL_PORT}      ${EMPTY}
${OPENBMC_CONSOLE_CLIENT}   ${EMPTY}

# OS related parameters.
${OS_HOST}          ${EMPTY}
${OS_USERNAME}      ${EMPTY}
${OS_PASSWORD}      ${EMPTY}
${OS_WAIT_TIMEOUT}  ${15*60}

# Networking related parameters
${NETWORK_PORT}            80
${PACKET_TYPE}             tcp
${ICMP_PACKETS}            icmp
${NETWORK_RETRY_TIME}      6
${NETWORK_TIMEOUT}         18
${ICMP_TIMESTAMP_REQUEST}  13
${ICMP_ECHO_REQUEST}       8
${CHANNEL_NUMBER}          1
${SECONDARY_CHANNEL_NUMBER}      2
${TCP_PACKETS}             tcp
${TCP_CONNECTION}          tcp-connect
${ICMP_NETMASK_REQUEST}    17
${REDFISH_INTERFACE}       443
${SYN_PACKETS}             SYN
${RESET_PACKETS}           RST
${FIN_PACKETS}             FIN
${SYN_ACK_RESET}           SAR
${ALL_FLAGS}               ALL

# Used to set BMC static IPv4 configuration.
${STATIC_IP}            10.10.10.10
${NETMASK}              255.255.255.0
${GATEWAY}              10.10.10.10

# BMC debug tarball parameter
${DEBUG_TARBALL_PATH}  ${EMPTY}

# Upload Image parameters
${TFTP_SERVER}                  ${EMPTY}
${PNOR_TFTP_FILE_NAME}          ${EMPTY}
${BMC_TFTP_FILE_NAME}           ${EMPTY}
${IMAGE_FILE_PATH}              ${EMPTY}
${ALTERNATE_IMAGE_FILE_PATH}    ${EMPTY}
${PNOR_IMAGE_FILE_PATH}         ${EMPTY}
${BMC_IMAGE_FILE_PATH}          ${EMPTY}
${BAD_IMAGES_DIR_PATH}          ${EMPTY}
${SKIP_UPDATE_IF_ACTIVE}        false

# Parameters for doing N-1 and N+1 code updates.
${N_MINUS_ONE_IMAGE_FILE_PATH}    ${EMPTY}
${N_PLUS_ONE_IMAGE_FILE_PATH}     ${EMPTY}

# The caller must set this to the string "true" in order to delete images. The
# code is picky.
${DELETE_OLD_PNOR_IMAGES}   false
${DELETE_OLD_GUARD_FILE}    false

# Caller can specify a value for LAST_KNOWN_GOOD_VERSION to indicate that if
# the machine already has that version on it, the update should be skipped.
${LAST_KNOWN_GOOD_VERSION}  ${EMPTY}

# By default field mode is disabled.
${FIELD_MODE}               ${False}

# LDAP related variables.
${LDAP_BASE_DN}             ${EMPTY}
${LDAP_BIND_DN}             ${EMPTY}
${LDAP_SERVER_HOST}         ${EMPTY}
${LDAP_SECURE_MODE}         ${EMPTY}
${LDAP_BIND_DN_PASSWORD}    ${EMPTY}
${LDAP_SEARCH_SCOPE}        ${EMPTY}
${LDAP_TYPE}                ${EMPTY}
${LDAP_USER}                ${EMPTY}
${LDAP_USER_PASSWORD}       ${EMPTY}
${GROUP_PRIVILEGE}          ${EMPTY}
${GROUP_NAME}               ${EMPTY}
${LDAP_SERVER_URI}          ldap://${LDAP_SERVER_HOST}

# General tool variables
# FFDC_DEFAULT == 1; use Default FFDC methods
${FFDC_DEFAULT}            ${1}

# NTP Server Address
# NTP Address needs to be given as an list.
# For example,
# 1 NTP Address - 14.139.60.103
# 2 NTP Address - 14.139.60.103  14.139.60.106
@{NTP_SERVER_ADDRESSES}    ${EMPTY}

# Client related parameters
${CLIENT_PASSWORD}         ${EMPTY}

# Task Service related variables.
${TASK_JSON_FILE_PATH}   data/task_state.json


*** Keywords ***

Get Inventory Schema
    [Documentation]  Get inventory schema.
    [Arguments]    ${machine}
    RETURN    &{INVENTORY}[${machine}]

Get Inventory Items Schema
    [Documentation]  Get inventory items schema.
    [Arguments]    ${machine}
    RETURN    &{INVENTORY_ITEMS}[${machine}]

Get Sensor Schema
    [Documentation]  Get sensors schema.
    [Arguments]    ${machine}
    RETURN    &{SENSORS}[${machine}]
