*** Settings ***
Documentation   BMC redfish resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
...             WITH NAME  redfish
Library         bmc_redfish_utils.py  WITH NAME  redfish_utils
Library         disable_warning_urllib.py

*** Keywords ***

