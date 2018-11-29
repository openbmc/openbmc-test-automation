*** Settings ***
Documentation   BMC redfish resource keyword.

Library         ../lib/bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}

*** Keywords ***

Initialize OpenBMC Redfish
    [Documentation]  Establish redfish login connection session.

    Login  ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
