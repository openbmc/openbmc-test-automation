#!/usr/bin/env python3

r"""
This module is the python counterpart to pgm_template.py.
"""

import gen_print as gp
import gen_robot_valid as grv


def suite_setup():
    r"""
    Do test suite setup tasks.
    """

    gp.qprintn()

    validate_suite_parms()

    gp.qprint_pgm_header()


def test_setup():
    r"""
    Do test case setup tasks.
    """

    gp.qprintn()
    gp.qprint_executing()


def validate_suite_parms():
    r"""
    Validate suite parameters.
    """

    # Programmer must add these.
    grv.valid_value("OPENBMC_HOST")

    return


def suite_teardown():
    r"""
    Clean up after this program.
    """

    gp.qprint_pgm_footer()
