*** Settings ***
Documentation  This module provides one wrapper keyword for each kind of boot
...            test supported by obmc_boot_test.py.

Resource  ../extended/obmc_boot_test_resource.robot

*** Keywords ***
REST Power On
    [Documentation]  Do "REST Power On" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=REST Power On
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Power On
    [Documentation]  Do "IPMI Power On" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=IPMI Power On
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


REST Power Off
    [Documentation]  Do "REST Power Off" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=REST Power Off
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


REST Hard Power Off
    [Documentation]  Do "REST Hard Power Off" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=REST Hard Power Off
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Power Off
    [Documentation]  Do "IPMI Power Off" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=IPMI Power Off
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Power Soft
    [Documentation]  Do "IPMI Power Soft" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=IPMI Power Soft
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


Host Power Off
    [Documentation]  Do "Host Power Off" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=Host Power Off
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


APOR
    [Documentation]  Do "APOR" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=APOR
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


OBMC Reboot (run)
    [Documentation]  Do "OBMC Reboot (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=OBMC Reboot (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


REST OBMC Reboot (run)
    [Documentation]  Do "REST OBMC Reboot (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=REST OBMC Reboot (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


OBMC Reboot (off)
    [Documentation]  Do "OBMC Reboot (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=OBMC Reboot (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


REST OBMC Reboot (off)
    [Documentation]  Do "REST OBMC Reboot (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=REST OBMC Reboot (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


PDU AC Cycle (run)
    [Documentation]  Do "PDU AC Cycle (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=PDU AC Cycle (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


PDU AC Cycle (off)
    [Documentation]  Do "PDU AC Cycle (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=PDU AC Cycle (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI MC Reset Warm (run)
    [Documentation]  Do "IPMI MC Reset Warm (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI MC Reset Warm (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI MC Reset Warm (off)
    [Documentation]  Do "IPMI MC Reset Warm (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI MC Reset Warm (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI MC Reset Cold (run)
    [Documentation]  Do "IPMI MC Reset Cold (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI MC Reset Cold (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI MC Reset Cold (off)
    [Documentation]  Do "IPMI MC Reset Cold (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI MC Reset Cold (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Std MC Reset Warm (run)
    [Documentation]  Do "IPMI Std MC Reset Warm (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI Std MC Reset Warm (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Std MC Reset Warm (off)
    [Documentation]  Do "IPMI Std MC Reset Warm (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI Std MC Reset Warm (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Std MC Reset Cold (run)
    [Documentation]  Do "IPMI Std MC Reset Cold (run)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI Std MC Reset Cold (run)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Std MC Reset Cold (off)
    [Documentation]  Do "IPMI Std MC Reset Cold (off)" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test
    ...  \ loc_boot_stack=IPMI Std MC Reset Cold (off)
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Power Cycle
    [Documentation]  Do "IPMI Power Cycle" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=IPMI Power Cycle
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


IPMI Power Reset
    [Documentation]  Do "IPMI Power Reset" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=IPMI Power Reset
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


Auto Reboot
    [Documentation]  Do "Auto Reboot" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=Auto Reboot
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


Host Reboot
    [Documentation]  Do "Host Reboot" boot test.
    [Arguments]  ${stack_mode}=${stack_mode}  ${quiet}=${quiet}

    # Description of argument(s):
    # stack_mode                    If stack_mode is set to "skip", each test
    #                               specified in the boot_stack is only
    #                               performed if the machine is not already in
    #                               the state that would normally result from
    #                               running the given boot test.  Otherwise,
    #                               the test is skipped.  If stack_mode is set
    #                               to "normal", all tests from the boot_stack
    #                               are performed.  "skip" mode is useful when
    #                               you simply want the machine in a desired
    #                               state.  The default value is the global
    #                               value of "${stack_mode}"
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"

    ${cmd_buf}  Catenate  OBMC Boot Test \ loc_boot_stack=Host Reboot
    ...  \ loc_stack_mode=${stack_mode} \ loc_quiet=${quiet}
    Run Key U  ${cmd_buf}


Smart Power Off
    [Documentation]  Do a smart power off.
    [Arguments]  ${quiet}=${QUIET}

    # A 'Smart Power Off' consists of a 'REST Power Off' with recovery.
    # Namely, if the 'REST Power Off' fails, a 'REST Hard Power Off' will
    # be attempted.

    # Description of argument(s):
    # quiet                         If this parameter is set to ${1}, this
    #                               keyword will print only essential
    #                               information.  The default value is the
    #                               global value of "${quiet}"


    # OBMC Boot Test will restore global quiet to initial global value.
    # Unfortunately, that restore affects our local quiet so we must
    # preserve it.
    ${loc_quiet}=  Set Variable  ${quiet}
    ${cmd_buf}=  Catenate  REST Power Off \ stack_mode=skip
    ...  \ \ quiet=${loc_quiet}
    ${status}  ${ret_values}=  Run Key U  ${cmd_buf}  ignore=${1}
    ...  quiet=${loc_quiet}

    Run Keyword If  '${status}' == 'PASS'  Return From Keyword

    ${cmd_buf}=  Catenate  REST Hard Power Off \ stack_mode=skip
    ...  \ \ quiet=${loc_quiet}
    Run Key U  ${cmd_buf}  quiet=${loc_quiet}

