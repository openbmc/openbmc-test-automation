*** Settings ***
Documentation       This module will test basic power on use cases for CI

Resource            ../lib/boot/boot_resource_master.robot

Force Tags  chassisboot

*** test cases ***

power on test
    [Documentation]    Power OFF and power ON

    BMC Power Off
    BMC Power On
