#!/usr/bin/wish

# This file provides many valuable validation procedures such as valid_value,
# valid_integer, etc.

my_source [list print.tcl call_stack.tcl]


proc valid_value { var_name { invalid_values {}} { valid_values {}} } {

  # If the value of the variable named in var_name is not valid, print an
  # error message and exit the program with a non-zero return code.

  # Description of arguments:
  # var_name                        The name of the variable whose value is to
  #                                 be validated.
  # invalid_values                  A list of invalid values.  If the variable
  #                                 value is equal to any value in the
  #                                 invalid_values list, it is deemed to be
  #                                 invalid.  Note that if you specify
  #                                 anything for invalid_values (below), the
  #                                 valid_values list is not even processed.
  #                                 In other words, specify either
  #                                 invalid_values or valid_values but not
  #                                 both.  If no value is specified for either
  #                                 invalid_values or valid_values,
  #                                 invalid_values will default to a list with
  #                                 one blank entry.  This is useful if you
  #                                 simply want to ensure that your variable
  #                                 is non blank.
  # valid_values                    A list of invalid values.  The variable
  #                                 value must be equal to one of the values
  #                                 in this list to be considered valid.

  # Call get_stack_var_level to relieve the caller of the need for declaring
  # the variable as global.
  set stack_level [get_stack_var_level $var_name]
  # Access the variable value.
  upvar $stack_level $var_name var_value

  set len_invalid_values [llength $invalid_values]
  set len_valid_values [llength $valid_values]

  if { $len_valid_values > 0 &&  $len_invalid_values > 0 } {
    append error_message "Programmer error - You must provide either an"
    append error_message " invalid_values list or a valid_values"
    append error_message " list but NOT both.\n"
    append error_message [sprint_list invalid_values "" "" 1]
    append error_message [sprint_list valid_values "" "" 1]
    print_error_report $error_message
    exit 1
  }

  if { $len_valid_values > 0 } {
    # Processing the valid_values list.
    if { [lsearch -exact $valid_values "${var_value}"] != -1 } { return }
    append error_message "The following variable has an invalid value:\n"
    append error_message [sprint_varx $var_name $var_value "" "" 1]
    append error_message "\nIt must be one of the following values:\n"
    append error_message [sprint_list valid_values "" "" 1]
    print_error_report $error_message
    exit 1
  }

  if { $len_invalid_values == 0 } {
    # Assign default value.
    set invalid_values [list ""]
  }

  # Assertion: We have an invalid_values list.  Processing it now.
  if { [lsearch -exact $invalid_values "${var_value}"] == -1 } { return }

  if { [lsearch -exact $valid_values "${var_value}"] != -1 } { return }
  append error_message "The following variable has an invalid value:\n"
  append error_message [sprint_varx $var_name $var_value "" "" 1]
  append error_message "\nIt must NOT be one of the following values:\n"
  append error_message [sprint_list invalid_values "" "" 1]
  print_error_report $error_message
  exit 1

}


proc valid_integer { var_name } {

  # If the value of the variable named in var_name is not a valid integer,
  # print an error message and exit the program with a non-zero return code.

  # Description of arguments:
  # var_name                        The name of the variable whose value is to
  #                                 be validated.

  # Call get_stack_var_level to relieve the caller of the need for declaring
  # the variable as global.
  set stack_level [get_stack_var_level $var_name]
  # Access the variable value.
  upvar $stack_level $var_name var_value

  if { [catch {format "0x%08x" "$var_value"} result] } {
    append error_message "Invalid integer value:\n"
    append error_message [sprint_varx $var_name $var_value]
    print_error_report $error_message
    exit 1
  }

}


proc valid_dir_path { var_name { add_slash 1 } } {

  # If the value of the variable named in var_name is not a valid directory
  # path, print an error message and exit the program with a non-zero return
  # code.

  # Description of arguments:
  # var_name                        The name of the variable whose value is to
  #                                 be validated.
  # add_slash                       If set to 1, this procedure will add a
  #                                 trailing slash to the directory path value.

  # Call get_stack_var_level to relieve the caller of the need for declaring
  # the variable as global.
  set stack_level [get_stack_var_level $var_name]
  # Access the variable value.
  upvar $stack_level $var_name var_value

  expand_shell_string var_value

  if { ![file isdirectory $var_value] } {
    append error_message "The following directory does not exist:\n"
    append error_message [sprint_varx $var_name $var_value "" "" 1]
    print_error_report $error_message
    exit 1
  }

  if { $add_slash } { add_trailing_string var_value / }

}


proc valid_file_path { var_name } {

  # If the value of the variable named in var_name is not a valid file path,
  # print an error message and exit the program with a non-zero return code.

  # Description of arguments:
  # var_name                        The name of the variable whose value is to
  #                                 be validated.

  # Call get_stack_var_level to relieve the caller of the need for declaring
  # the variable as global.
  set stack_level [get_stack_var_level $var_name]
  # Access the variable value.
  upvar $stack_level $var_name var_value

  expand_shell_string var_value

  if { ![file isfile $var_value] } {
    append error_message "The following file does not exist:\n"
    append error_message [sprint_varx $var_name $var_value "" "" 1]
    print_error_report $error_message
    exit 1
  }

}
