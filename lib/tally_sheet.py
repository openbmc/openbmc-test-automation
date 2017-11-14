#!/usr/bin/env python

r"""
Define the tally_sheet class.
"""

import sys
import collections
import copy
import re

try:
    from robot.utils import DotDict
except ImportError:
    pass

import gen_print as gp


class tally_sheet:

    r"""
    This class is the implementation of a tally sheet.  The sheet can be
    viewed as rows and columns.  Each row has a unique key field.

    This class provides methods to tally the results (totals, etc.).

    Example code:

    # Create an ordered dict to represent your field names/initial values.
    try:
        boot_results_fields = collections.OrderedDict([('total', 0), ('pass',
        0), ('fail', 0)])
    except AttributeError:
        boot_results_fields = DotDict([('total', 0), ('pass', 0), ('fail', 0)])
    # Create the tally sheet.
    boot_test_results = tally_sheet('boot type', boot_results_fields,
    'boot_test_results')
    # Set your sum fields (fields which are to be totalled).
    boot_test_results.set_sum_fields(['total', 'pass', 'fail'])
    # Set calc fields (within a row, a certain field can be derived from
    # other fields in the row.
    boot_test_results.set_calc_fields(['total=pass+fail'])

    # Create some records.
    boot_test_results.add_row('BMC Power On')
    boot_test_results.add_row('BMC Power Off')

    # Increment field values.
    boot_test_results.inc_row_field('BMC Power On', 'pass')
    boot_test_results.inc_row_field('BMC Power Off', 'pass')
    boot_test_results.inc_row_field('BMC Power On', 'fail')
    # Have the results tallied...
    boot_test_results.calc()
    # And printed...
    boot_test_results.print_report()

    Example result:

    Boot Type                      Total Pass Fail
    ------------------------------ ----- ---- ----
    BMC Power On                       2    1    1
    BMC Power Off                      1    1    0
    ==============================================
    Totals                             3    2    1

    """

    def __init__(self,
                 row_key_field_name='Description',
                 init_fields_dict=dict(),
                 obj_name='tally_sheet'):

        r"""
        Create a tally sheet object.

        Description of arguments:
        row_key_field_name          The name of the row key field (e.g.
                                    boot_type, team_name, etc.)
        init_fields_dict            A dictionary which contains field
                                    names/initial values.
        obj_name                    The name of the tally sheet.
        """

        self.__obj_name = obj_name
        # The row key field uniquely identifies the row.
        self.__row_key_field_name = row_key_field_name
        # Create a "table" which is an ordered dictionary.
        # If we're running python 2.7 or later, collections has an
        # OrderedDict we can use.  Otherwise, we'll try to use the DotDict (a
        # robot library).  If neither of those are available, we fail.
        try:
            self.__table = collections.OrderedDict()
        except AttributeError:
            self.__table = DotDict()
        # Save the initial fields dictionary.
        self.__init_fields_dict = init_fields_dict
        self.__totals_line = init_fields_dict
        self.__sum_fields = []
        self.__calc_fields = []

    def init(self,
             row_key_field_name,
             init_fields_dict,
             obj_name='tally_sheet'):
        self.__init__(row_key_field_name,
                      init_fields_dict,
                      obj_name='tally_sheet')

    def set_sum_fields(self, sum_fields):

        r"""
        Set the sum fields, i.e. create a list of field names which are to be
        summed and included on the totals line of reports.

        Description of arguments:
        sum_fields                  A list of field names.
        """

        self.__sum_fields = sum_fields

    def set_calc_fields(self, calc_fields):

        r"""
        Set the calc fields, i.e. create a list of field names within a given
        row which are to be calculated for the user.

        Description of arguments:
        calc_fields                 A string expression such as
                                    'total=pass+fail' which shows which field
                                    on a given row is derived from other
                                    fields in the same row.
        """

        self.__calc_fields = calc_fields

    def add_row(self, row_key, init_fields_dict=None):

        r"""
        Add a row to the tally sheet.

        Description of arguments:
        row_key                     A unique key value.
        init_fields_dict            A dictionary of field names/initial
                                    values.  The number of fields in this
                                    dictionary must be the same as what was
                                    specified when the tally sheet was
                                    created.  If no value is passed, the value
                                    used to create the tally sheet will be
                                    used.
        """

        if init_fields_dict is None:
            init_fields_dict = self.__init_fields_dict
        try:
            self.__table[row_key] = collections.OrderedDict(init_fields_dict)
        except AttributeError:
            self.__table[row_key] = DotDict(init_fields_dict)

    def update_row_field(self, row_key, field_key, value):

        r"""
        Update a field in a row with the specified value.

        Description of arguments:
        row_key                     A unique key value that identifies the row
                                    to be updated.
        field_key                   The key that identifies which field in the
                                    row that is to be updated.
        value                       The value to set into the specified
                                    row/field.
        """

        self.__table[row_key][field_key] = value

    def inc_row_field(self, row_key, field_key):

        r"""
        Increment the value of the specified field in the specified row.  The
        value of the field must be numeric.

        Description of arguments:
        row_key                     A unique key value that identifies the row
                                    to be updated.
        field_key                   The key that identifies which field in the
                                    row that is to be updated.
        """

        self.__table[row_key][field_key] += 1

    def dec_row_field(self, row_key, field_key):

        r"""
        Decrement the value of the specified field in the specified row.  The
        value of the field must be numeric.

        Description of arguments:
        row_key                     A unique key value that identifies the row
                                    to be updated.
        field_key                   The key that identifies which field in the
                                    row that is to be updated.
        """

        self.__table[row_key][field_key] -= 1

    def calc(self):

        r"""
        Calculate totals and row calc fields.  Also, return totals_line
        dictionary.
        """

        self.__totals_line = copy.deepcopy(self.__init_fields_dict)
        # Walk through the rows of the table.
        for row_key, value in self.__table.items():
            # Walk through the calc fields and process them.
            for calc_field in self.__calc_fields:
                tokens = [i for i in re.split(r'(\d+|\W+)', calc_field) if i]
                cmd_buf = ""
                for token in tokens:
                    if token in ("=", "+", "-", "*", "/"):
                        cmd_buf += token + " "
                    else:
                        # Note: Using "mangled" name for the sake of the exec
                        # statement (below).
                        cmd_buf += "self._" + self.__class__.__name__ +\
                                   "__table['" + row_key + "']['" +\
                                   token + "'] "
                exec(cmd_buf)

            for field_key, sub_value in value.items():
                if field_key in self.__sum_fields:
                    self.__totals_line[field_key] += sub_value

        return self.__totals_line

    def sprint_obj(self):

        r"""
        sprint the fields of this object.  This would normally be for debug
        purposes.
        """

        buffer = ""

        buffer += "class name: " + self.__class__.__name__ + "\n"
        buffer += gp.sprint_var(self.__obj_name)
        buffer += gp.sprint_var(self.__row_key_field_name)
        buffer += gp.sprint_var(self.__table)
        buffer += gp.sprint_var(self.__init_fields_dict)
        buffer += gp.sprint_var(self.__sum_fields)
        buffer += gp.sprint_var(self.__totals_line)
        buffer += gp.sprint_var(self.__calc_fields)
        buffer += gp.sprint_var(self.__table)

        return buffer

    def print_obj(self):

        r"""
        print the fields of this object to stdout.  This would normally be for
        debug purposes.
        """

        sys.stdout.write(self.sprint_obj())

    def sprint_report(self):

        r"""
        sprint the tally sheet in a formatted way.
        """

        buffer = ""
        # Build format strings.
        col_names = [self.__row_key_field_name.title()]
        report_width = 30
        key_width = 30
        format_string = '{0:<' + str(key_width) + '}'
        dash_format_string = '{0:-<' + str(key_width) + '}'
        field_num = 0

        first_rec = next(iter(self.__table.items()))
        for row_key, value in first_rec[1].items():
            field_num += 1
            if type(value) is int:
                align = ':>'
            else:
                align = ':<'
            format_string += ' {' + str(field_num) + align +\
                             str(len(row_key)) + '}'
            dash_format_string += ' {' + str(field_num) + ':->' +\
                                  str(len(row_key)) + '}'
            report_width += 1 + len(row_key)
            col_names.append(row_key.title())
        num_fields = field_num + 1
        totals_line_fmt = '{0:=<' + str(report_width) + '}'

        buffer += format_string.format(*col_names) + "\n"
        buffer += dash_format_string.format(*([''] * num_fields)) + "\n"
        for row_key, value in self.__table.items():
            buffer += format_string.format(row_key, *value.values()) + "\n"

        buffer += totals_line_fmt.format('') + "\n"
        buffer += format_string.format('Totals',
                                       *self.__totals_line.values()) + "\n"

        return buffer

    def print_report(self):

        r"""
        print the tally sheet in a formatted way.
        """

        sys.stdout.write(self.sprint_report())
