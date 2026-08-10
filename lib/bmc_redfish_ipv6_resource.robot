*** Settings ***
Documentation   BMC redfish IPv6 resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         bmc_redfish.py  https://[${OPENBMC_HOST_IPv6}]:${HTTPS_PORT}  ${OPENBMC_USERNAME}
...             ${OPENBMC_PASSWORD}  AS  RedfishIPv6
Library         bmc_redfish_utils.py  AS  redfish_utils
Library         disable_warning_urllib.py


*** Keywords ***
