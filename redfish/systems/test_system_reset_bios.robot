
*** Settings ***
Resource         ../../lib/resource.robot
Resource         ../../lib/bmc_redfish_resource.robot
Resource         ../../lib/common_utils.robot
Resource         ../../lib/openbmc_ffdc.robot
Resource         ../../lib/ipmi_client.robot
Resource        ../../lib/bmc_redfish_utils.robot

*** Variables ***




*** Test Cases **

System Reset Bios via Redfish
         Redfish System Reset Bios Operation


