*** Settings ***
Documentation   BMC redfish resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         redfish_plus.py  https://${OPENBMC_HOST}  ${OPENBMC_USERNAME}
...             ${OPENBMC_PASSWORD}  WITH NAME  Redfish
Library         bmc_redfish_utils.py  WITH NAME  redfish_utils
Library         disable_warning_urllib.py

*** Keywords ***
