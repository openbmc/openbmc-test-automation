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


class VariablesShouldBeUpperCase(SuiteRule):
    r"""
    Verify that variable names defined in the *** Variables *** section
    use all upper case letters.
    e.g. "${my_var}" should be "${MY_VAR}"
    """

    severity = ERROR

    def apply(self, suite):
        r"""
        Walk through the variables table and report any variable names
        that are not all upper case.
        """
        for table in suite.tables:
            if re.match(r"^variables?$", table.name, re.IGNORECASE):
                for row in table.rows:
                    if not row.cells:
                        continue
                    name = row.cells[0]
                    match = re.match(r"^[\$@&%]\{(.+?)}\s*=?\s*$", name)
                    if match:
                        var_name = match.group(1)
                        if var_name != var_name.upper():
                            self.report(
                                suite,
                                name,
                                row.linenumber,
                            )
