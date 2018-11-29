*** Settings ***
Documentation   BMC redfish resource keyword.

Library         ../lib/bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
...              WITH NAME    redfish

*** Keywords ***
