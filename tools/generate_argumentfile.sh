#!/bin/bash

echo "--variable OPENBMC_HOST:$OPENBMC_HOST" > $ARG_FILE
echo "--variable OPENBMC_MODEL:$OPENBMC_MODEL" >> $ARG_FILE
echo "--variable OPENBMC_USERNAME:$OPENBMC_USERNAME" >> $ARG_FILE
echo "--variable OPENBMC_PASSWORD:$OPENBMC_PASSWORD" >> $ARG_FILE
echo "--variable PDU_TYPE:$PDU_TYPE" >> $ARG_FILE
echo "--variable PDU_IP:$PDU_IP" >> $ARG_FILE
echo "--variable PDU_USERNAME:$PDU_USERNAME" >> $ARG_FILE
echo "--variable PDU_PASSWORD:$PDU_PASSWORD" >> $ARG_FILE
echo "--variable PDU_SLOT_NO:$PDU_SLOT_NO" >> $ARG_FILE
echo "--variable SYSLOG_IP_ADDRESS:$SYSLOG_IP_ADDRESS" >> $ARG_FILE
echo "--variable SYSLOG_PORT:$SYSLOG_PORT" >> $ARG_FILE
