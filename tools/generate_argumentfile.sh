#!/bin/bash

echo "--variable OPENBMC_HOST:$OPENBMC_HOST" > $ARG_FILE
echo "--variable OPENBMC_MODEL:$OPENBMC_MODEL" >> $ARG_FILE
echo "--variable OPENBMC_USERNAME:$OPENBMC_USERNAME" >> $ARG_FILE
echo "--variable OPENBMC_PASSWORD:$OPENBMC_PASSWORD" >> $ARG_FILE
echo "--variable OPENBMC_SYSTEMMODEL:$OPENBMC_SYSTEMMODEL" >> $ARG_FILE
echo "--variable GUI_BROWSER:$GUI_BROSWER" >> $ARG_FILE
echo "--variable GUI_MODE:$GUI_MODE" >> $ARG_FILE
echo "--variable PDU_TYPE:$PDU_TYPE" >> $ARG_FILE
echo "--variable PDU_IP:$PDU_IP" >> $ARG_FILE
echo "--variable PDU_USERNAME:$PDU_USERNAME" >> $ARG_FILE
echo "--variable PDU_PASSWORD:$PDU_PASSWORD" >> $ARG_FILE
echo "--variable PDU_SLOT_NO:$PDU_SLOT_NO" >> $ARG_FILE
echo "--variable SYSLOG_IP_ADDRESS:$SYSLOG_IP_ADDRESS" >> $ARG_FILE
echo "--variable SYSLOG_PORT:$SYSLOG_PORT" >> $ARG_FILE
echo "--variable SSH_PORT:$SSH_PORT" >> $ARG_FILE
echo "--variable HTTPS_PORT:$HTTPS_PORT" >> $ARG_FILE
echo "--variable PNOR_IMAGE_PATH:$PNOR_IMAGE_PATH" >> $ARG_FILE
echo "--variable IPMI_COMMAND:$IPMI_COMMAND" >> $ARG_FILE
echo "--variable IPMI_CIPHER_LEVEL:$IPMI_CIPHER_LEVEL" >> $ARG_FILE
echo "--variable ITERATION:$ITERATION" >> $ARG_FILE
echo "--variable LOOP_TEST_COMMAND:$LOOP_TEST_COMMAND" >> $ARG_FILE
echo "--variable OS_HOST:$OS_HOST" >> $ARG_FILE
echo "--variable OS_USERNAME:$OS_USERNAME" >> $ARG_FILE
echo "--variable OS_PASSWORD:$OS_PASSWORD" >> $ARG_FILE
echo "--variable DEBUG_TARBALL_PATH:$DEBUG_TARBALL_PATH" >> $ARG_FILE
echo "--variable TFTP_SERVER:$TFTP_SERVER" >> $ARG_FILE
echo "--variable PNOR_TFTP_FILE_NAME:$PNOR_TFTP_FILE_NAME" >> $ARG_FILE
echo "--variable BMC_TFTP_FILE_NAME:$BMC_TFTP_FILE_NAME" >> $ARG_FILE
echo "--variable IMAGE_FILE_PATH:$IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable ALTERNATE_IMAGE_FILE_PATH:$ALTERNATE_IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable PNOR_IMAGE_FILE_PATH:$PNOR_IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable BMC_IMAGE_FILE_PATH:$BMC_IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable BAD_IMAGES_DIR_PATH:$BAD_IMAGES_DIR_PATH" >> $ARG_FILE
echo "--variable N_MINUS_ONE_IMAGE_FILE_PATH:$N_MINUS_ONE_IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable N_PLUS_ONE_IMAGE_FILE_PATH:$N_PLUS_ONE_IMAGE_FILE_PATH" >> $ARG_FILE
echo "--variable SKIP_UPDATE_IF_ACTIVE:$SKIP_UPDATE_IF_ACTIVE" >> $ARG_FILE
echo "--variable DELETE_OLD_PNOR_IMAGES:$DELETE_OLD_PNOR_IMAGES" >> $ARG_FILE
echo "--variable DELETE_OLD_GUARD_FILE:$DELETE_OLD_GUARD_FILE" >> $ARG_FILE
echo "--variable LAST_KNOWN_GOOD_VERSION:$LAST_KNOWN_GOOD_VERSION" >> $ARG_FILE
echo "--variable LDAP_BASE_DN:$LDAP_BASE_DN" >> $ARG_FILE
echo "--variable LDAP_BIND_DN:$LDAP_BIND_DN" >> $ARG_FILE
echo "--variable LDAP_SERVER_URI:$LDAP_SERVER_URI" >> $ARG_FILE
echo "--variable LDAP_BIND_DN_PASSWORD:$LDAP_BIND_DN_PASSWORD" >> $ARG_FILE
echo "--variable LDAP_SEARCH_SCOPE:$LDAP_SEARCH_SCOPE" >> $ARG_FILE
echo "--variable LDAP_TYPE:$LDAP_TYPE" >> $ARG_FILE
echo "--variable LDAP_USER:$LDAP_USER" >> $ARG_FILE
echo "--variable LDAP_USER_PASSWORD:$LDAP_USER_PASSWORD" >> $ARG_FILE
echo "--variable GROUP_NAME:$GROUP_NAME" >> $ARG_FILE
echo "--variable GROUP_PRIVILEGE:$GROUP_PRIVILEGE" >> $ARG_FILE