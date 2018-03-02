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


proc get_password { {password_var_name password} } {

  # Prompt user for password and return result.

  # On error, print to stderr and terminate the program with non-zero return
  # code.

  set prompt\
    [string trimright [sprint_varx "Please enter $password_var_name" ""] "\n"]
  puts -nonewline $prompt
  flush stdout
  stty -echo
  gets stdin password1
  stty echo
  puts ""

  set prompt [string\
    trimright [sprint_varx "Please re-enter $password_var_name" ""] "\n"]
  puts -nonewline $prompt
  flush stdout
  stty -echo
  gets stdin password2
  stty echo
  puts ""

  if { $password1 != $password2 } {
    print_error_report "Passwords do not match.\n"
    gen_exit_proc 1
  }

  if { $password1 == "" } {
    print_error_report "Need a non-blank value for $password_var_name.\n"
    gen_exit_proc 1
  }

  return $password1

}


proc valid_password { var_name { prompt_user 1 } } {

  # If the value of the variable named in var_name is not a valid password,
  # print an error message and exit the program with a non-zero return code.

  # Description of arguments:
  # var_name                        The name of the variable whose value is to
  #                                 be validated.
  # prompt_user                     If the variable has a blank value, prompt
  #                                 the user for a value.

  # Call get_stack_var_level to relieve the caller of the need for declaring
  # the variable as global.
  set stack_level [get_stack_var_level $var_name]
  # Access the variable value.
  upvar $stack_level $var_name var_value

  if { $var_value == "" && $prompt_user } {
    global $var_name
    set $var_name [get_password $var_name]
  }

  if { $var_value == "" } {
    print_error_report "Need a non-blank value for $var_name.\n"
    gen_exit_proc 1
  }

}


proc process_pw_file_path {pw_file_path_var_name} {

  # Process a password file path parameter.

  # This includes the following:
  # - Make sure the pw_file_path_var_name value ends in "pw_file_path".
  # - Create a global password variable that corresponds to the
  # pw_file_path_var_name value.
  # - If the password file exists, read its contents put the result into the
  # global variable constructed.
  # - Call valid_password which will prompt user if password has not been
  # obtained.

  # Description of argument(s):
  # pw_file_path_var_name           The name of a global variable that
  #                                 contains a file path which in turn
  #                                 contains a password value.

  # Verify that $pw_file_path_var_name ends with "pw_file_path".
  if { ! [regexp -expanded "pw_file_path$" $pw_file_path_var_name] } {
    append message "Programming error - Proc [get_stack_proc_name] its"
    append message " pw_file_path_var_name parameter to contain a value that"
    append message "ends in \"pw_file_path\" instead of the current value:\n"
    append message [sprint_var pw_file_path_var_name]
    print_error $message
    gen_exit_proc 1
  }

  global $pw_file_path_var_name
  expand_shell_string $pw_file_path_var_name

  # Get the prefix portion of pw_file_path_var_name which is obtained by
  # stripping "pw_file_path" from the end.
  regsub -expanded {pw_file_path$} $pw_file_path_var_name {} var_prefix

  # Create password_var_name.
  set password_var_name ${var_prefix}password
  global $password_var_name

  global longoptions pos_parms
  regsub -all ":" "${longoptions} ${pos_parms}" {} parm_names
  if { [lsearch -exact parm_names $password_var_name] == -1 } {
    valid_file_path $pw_file_path_var_name
  }

  # If the password file path is empty, return.
  if { [file isfile [set $pw_file_path_var_name]] } {
    # Read the entire password file into a list, filtering comments out.
    set file_descriptor [open [set $pw_file_path_var_name] r]
    set file_data [list_filter_comments [split [read $file_descriptor] "\n"]]
    close $file_descriptor

    # Assign the password value to the global password variable.
    set $password_var_name [lindex $file_data 0]
    # Register the password to prevent printing it.
    register_passwords [set $password_var_name]
  }

  valid_password $password_var_name

}


