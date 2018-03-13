*** Settings ***
Documentation       This suite is for doing basic IPL testing using ipmi.

Resource            ../../lib/ipmi_client.robot
Resource            ../../lib/openbmc_ffdc.robot
Resource            ../lib/boot_utils.robot
Library             ../../lib/ipmi_utils.py
Resource            ../../lib/bmc_network_utils.robot


*** Variables ***

