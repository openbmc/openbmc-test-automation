*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/boot/boot_resource_master.robot
Resource            ../lib/openbmc_ffdc.robot
Test Teardown       Log FFDC

Force Tags  chassisboot

*** test cases ***

power on test
    [Documentation]    Power OFF and power ON
    [Tags]  power_on_test

    BMC Power Off
    BMC Power On
