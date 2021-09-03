#!/usr/bin/env python3
# Custom rules file for robotframework-lint.
# Example usage: python -m rflint -rA robot_standards -R robot_custom_rules.py .
import re
from rflint.common import SuiteRule, ERROR


class ExtendInvalidTable(SuiteRule):
    r'''
    Extend robotframework-lint SuiteRule function for InvalidTable to allow a table section if it is
    a section of comments. e.g "*** Comments ***"
    '''
    severity = ERROR

    def apply(self, suite):
        for table in suite.tables:
            if (not re.match(r'^(settings?|metadata|(test )?cases?|(user )?keywords?|variables?|comments?)$',
                             table.name, re.IGNORECASE)):
                self.report(suite, "Unknown table name '%s'" % table.name, table.linenumber)
