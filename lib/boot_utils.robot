*** Settings ***
Documentation  This module provides one wrapper function for each kind of boot
...            test supported by obmc_boot_test.

Resource  ../extended/obmc_boot_test_resource.robot

*** Keywords ***
###############################################################################
REST Power On
    [Documentation]  Do "REST Power On" boot test.

    Run Key U  OBMC Boot Test \ REST Power On


###############################################################################
IPMI Power On
    [Documentation]  Do "IPMI Power On" boot test.

    Run Key U  OBMC Boot Test \ IPMI Power On


###############################################################################
REST Power Off
    [Documentation]  Do "REST Power Off" boot test.

    Run Key U  OBMC Boot Test \ REST Power Off


###############################################################################
IPMI Power Off
    [Documentation]  Do "IPMI Power Off" boot test.

    Run Key U  OBMC Boot Test \ IPMI Power Off


###############################################################################
IPMI Power Soft
    [Documentation]  Do "IPMI Power Soft" boot test.

    Run Key U  OBMC Boot Test \ IPMI Power Soft


###############################################################################
Host Power Off
    [Documentation]  Do "Host Power Off" boot test.

    Run Key U  OBMC Boot Test \ Host Power Off


###############################################################################
APOR
    [Documentation]  Do "APOR" boot test.

    Run Key U  OBMC Boot Test \ APOR


###############################################################################
OBMC Reboot (run)
    [Documentation]  Do "OBMC Reboot (run)" boot test.

    Run Key U  OBMC Boot Test \ OBMC Reboot (run)


###############################################################################
OBMC Reboot (off)
    [Documentation]  Do "OBMC Reboot (off)" boot test.

    Run Key U  OBMC Boot Test \ OBMC Reboot (off)


###############################################################################
PDU AC Cycle (run)
    [Documentation]  Do "PDU AC Cycle (run)" boot test.

    Run Key U  OBMC Boot Test \ PDU AC Cycle (run)


###############################################################################
PDU AC Cycle (off)
    [Documentation]  Do "PDU AC Cycle (off)" boot test.

    Run Key U  OBMC Boot Test \ PDU AC Cycle (off)


###############################################################################
IPMI MC Reset Warm (run)
    [Documentation]  Do "IPMI MC Reset Warm (run)" boot test.

    Run Key U  OBMC Boot Test \ IPMI MC Reset Warm (run)


###############################################################################
IPMI MC Reset Warm (off)
    [Documentation]  Do "IPMI MC Reset Warm (off)" boot test.

    Run Key U  OBMC Boot Test \ IPMI MC Reset Warm (off)


###############################################################################
IPMI Power Cycle
    [Documentation]  Do "IPMI Power Cycle" boot test.

    Run Key U  OBMC Boot Test \ IPMI Power Cycle


###############################################################################
IPMI Power Reset
    [Documentation]  Do "IPMI Power Reset" boot test.

    Run Key U  OBMC Boot Test \ IPMI Power Reset


###############################################################################
Auto Reboot
    [Documentation]  Do "Auto Reboot" boot test.

    Run Key U  OBMC Boot Test \ Auto Reboot


###############################################################################
Host Reboot
    [Documentation]  Do "Host Reboot" boot test.

    Run Key U  OBMC Boot Test \ Host Reboot


