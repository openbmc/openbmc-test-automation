*** Settings ***
Documentation  Get system environment for test suite.

Resource         ../lib/common_utils.robot

Suite Setup      Get System Environment

*** Keyword ***

Get System Environment
    [Documentation]  System environment details.

    Run Keyword And Ignore Error  Get BMC PNOR Version
    # Run Keyword  Check BMC Performance
    Run Keyword And Ignore Error  Check BMC Performance
