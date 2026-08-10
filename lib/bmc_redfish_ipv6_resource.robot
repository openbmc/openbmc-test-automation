*** Settings ***
Documentation   BMC redfish IPv6 resource keyword.

Resource        resource.robot
Resource        rest_response_code.robot
Library         bmc_redfish.py  https://[${OPENBMC_HOST_IPv6}]:${HTTPS_PORT}  ${OPENBMC_USERNAME}
...             ${OPENBMC_PASSWORD}  AS  RedfishIPv6
Library         bmc_redfish_utils.py  AS  redfish_utils
Library         disable_warning_urllib.py


*** Keywords ***

Connect BMC Using IPv6 Address
    [Documentation]  Import bmc_redfish library with IPv6 configuration.
    [Arguments]  ${OPENBMC_HOST_IPv6}

    # Description of argument(s):
    # OPENBMC_HOST_IPv6  IPv6 address of the BMC.

    Import Library  ${CURDIR}/bmc_redfish.py  https://[${OPENBMC_HOST_IPv6}]:${HTTPS_PORT}
    ...             ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}  AS  RedfishIPv6
