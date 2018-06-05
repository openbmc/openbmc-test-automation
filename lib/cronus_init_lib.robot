*** Settings ***
Documentation   Cronus setup utils keywords.

Resource     resource.txt

*** Keywords ***

Cronus Setup Variables
     [Documentation]  System environment variables required for cronus setup.

     Set Environment Variable  TARGET_IP  ${OPENBMC_HOST}
     Set Environment Variable  TARGET_USERNAME  ${OPENBMC_USERNAME}
     Set Environment Variable  TARGET_PASSWORD  ${OPENBMC_PASSWORD}
     Set Environment Variable  SYSTEM_TYPE  ${OPENBMC_MODEL}
