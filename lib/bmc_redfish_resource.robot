*** Settings ***
Documentation   BMC redfish resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         bmc_redfish.py  https://${OPENBMC_HOST}:${HTTPS_PORT}  ${OPENBMC_USERNAME}
...             ${OPENBMC_PASSWORD}  AS  Redfish
Library         bmc_redfish_utils.py  AS  redfish_utils
Library         disable_warning_urllib.py


*** Keywords ***
