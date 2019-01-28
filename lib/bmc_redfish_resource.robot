*** Settings ***
Documentation   BMC redfish resource keyword.

Library         bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
...             WITH NAME  bmcweb_redfish
Resource        rest_response_code.robot
Library         disable_warning_urllib.py

*** Keywords ***
