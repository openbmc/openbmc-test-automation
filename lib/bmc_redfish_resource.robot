*** Settings ***
Documentation   BMC redfish resource keyword.

Resource        resource.txt
Resource        rest_response_code.robot
Library         bmc_redfish.py
...             ${OPENBMC_HOST}  ${OPENBMC_USERNAME}  ${OPENBMC_PASSWORD}
...             WITH NAME  redfish
Library         disable_warning_urllib.py

*** Keywords ***
