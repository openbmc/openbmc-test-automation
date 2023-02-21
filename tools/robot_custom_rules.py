#!/usr/bin/env python3
r"""
Custom rules file for robotframework-lint.
Installation : pip3 install --upgrade robotframework-lint
Example usage:
    python3 -m rflint -rA robot_standards -R robot_custom_rules.py .
"""

import re

from rflint.common import ERROR, SuiteRule


class ExtendInvalidTable(SuiteRule):
    r"""
    Extend robotframework-lint SuiteRule function for InvalidTable to allow a
    table section if it is a section of comments.
    e.g "*** Comments ***"
    """
    severity = ERROR

    def apply(self, suite):
        r"""
        Walk through the code and report.
        """
        for table in suite.tables:
            if not re.match(
                r"^(settings?|metadata|(test )?cases?|(user"
                r" )?keywords?|variables?|comments?)$",
                table.name,
                re.IGNORECASE,
            ):
                self.report(
                    suite,
                    table.name,
                    table.linenumber,
                )
