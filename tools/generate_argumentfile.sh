#!/bin/bash

echo "--variable OPENBMC_HOST:$OPENBMC_HOST" > $ARG_FILE
echo "--variable OPENBMC_MODEL:$OPENBMC_MODEL" >> $ARG_FILE
echo "--variable OPENBMC_USERNAME:$OPENBMC_USERNAME" >> $ARG_FILE
echo "--variable OPENBMC_PASSWORD:$OPENBMC_PASSWORD" >> $ARG_FILE
echo "--variable OPENBMC_SYSTEMMODEL:$OPENBMC_SYSTEMMODEL" >> $ARG_FILE
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
echo "--variable ITERATION:$ITERATION" >> $ARG_FILE
echo "--variable LOOP_TEST_COMMAND:$LOOP_TEST_COMMAND" >> $ARG_FILE
echo "--variable OS_HOST:$OS_HOST" >> $ARG_FILE
echo "--variable OS_USERNAME:$OS_USERNAME" >> $ARG_FILE
echo "--variable OS_PASSWORD:$OS_PASSWORD" >> $ARG_FILE
