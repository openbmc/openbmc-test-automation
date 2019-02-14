*** Settings ***

Documentation  Verify if system is water cooled

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The userID for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
#

Resource         ../lib/fan_utils.robot

#Test Teardown    FFDC On Test Case Fail


*** Test Cases ***

 Verify System Is Water Cooled
    ${water_coooled}=  Is Water Cooled
    Run Keyword If  ${water_coooled}  Log To Console  System is Water Cooled.
    Should Be True  ${water_coooled}  msg=Expecting system to be water cooled.
