#!/usr/bin/wish

# This file provides many valuable stack inquiry procedures like
# get_file_proc_names, get_stack_var, etc..

my_source [list print.tcl]


proc get_file_proc_names { file_path { name_regex "" } } {

  # Get all proc names from the file indicated by file_path and return them
  # as a list.

  # Description of argument(s):
  # file_path                       The path to the file whose proc names are
  #                                 to be retrieved.
  # name_regex                      A regular expression to be used to narrow
  #                                 the result to just the desired procs.

  # The first sed command serves to eliminate curly braces from the target
  # file.  They are a distraction to what we are trying to do.
  # TCL proc lines begin with...
  # - Zero or more spaces...
  # - The "proc" keyword...
  # - One or more spaces...
  set proc_regex "^\[ \]*proc\[ \]+"
  set cmd_buf "sed -re 's/\[\\\{\\\}]//g' $file_path | egrep"
  append cmd_buf " '${proc_regex}${name_regex}[ ]' | sed -re"
  append cmd_buf " 's/${proc_regex}(\[^ \]+).*/\\1/g'"
  return [split [eval exec bash -c {$cmd_buf}] "\n"]

}


proc get_stack_var { var_name { default {} } { init_stack_ix 1 } } {

  # Starting with the caller's stack level, search upward in the call stack,
  # for a variable named "${var_name}" and return its value.  If the variable
  # cannot be found, return ${default}.

  # Description of argument(s):
  # var_name                        The name of the variable be searched for.
  # default                         The value to return if the the variable
  #                                 cannot be found.

  for {set stack_ix $init_stack_ix} {$stack_ix <= [info level]} \
      {incr stack_ix} {
    upvar $stack_ix $var_name var_ref
    if { [info exists var_ref] } { return $var_ref }
  }

  return $default

}


proc get_stack_var_level { var_name { init_stack_ix 1 } { fail_on_err 1 } } {

  # Starting with the caller's stack level, search upward in the call stack,
  # for a variable named "${var_name}" and return its associated stack level.
  # If the variable cannot be found, return -1.

  # Description of argument(s):
  # var_name                        The name of the variable be searched for.
  # init_stack_ix                   The level of the stack where the search
  #                                 should start.  The default is 1 which is
  #                                 the caller's stack level.
  # fail_on_err                     Indicates that if the variable cannot be
  #                                 found on the stack, this proc should write
  #                                 to stderr and exit with a non-zero return
  #                                 code.

  for {set stack_ix $init_stack_ix} {$stack_ix <= [info level]} \
      {incr stack_ix} {
    upvar $stack_ix $var_name var_ref
    set stack_level [expr $stack_ix - $init_stack_ix]
    if { [info exists var_ref] } { return $stack_level }
  }

  if { $fail_on_err } {
    append message "Programmer error - Couldn't find variable \"${var_name}\""
    append message " on the stack."
    print_error_report $message
    exit 1
  }

  return -1

}


proc get_stack_proc_name { { level -1 } { include_args 0 } } {

  # Get the name of the procedure at the indicated call stack level and
  # return it.

  # Description of argument(s):
  # level                           The call stack level: 0 would mean this
  #                                 procedure's level (i.e.
  #                                 get_stack_proc_name's level), -1 would
  #                                 indicate the caller's level, etc.
  # include_args                    Indicates whether proc arg values should
  #                                 be included in the result.

  # Set default.
  set_var_default level -1

  if { $include_args } {
    set cmd_buf "set proc_name \[info level $level\]"
  } else {
    set cmd_buf "set proc_name \[lindex \[info level $level\] 0\]"
  }

  if { [ catch $cmd_buf result ] } {
    # The command failed most likely due to being called from "main".
    set proc_name "main"
  }

  return $proc_name

}


proc get_call_stack { { stack_top_ix -1 } { include_args 0 } } {

  # Return the call stack as a list of procedure names.

  # Example:
  # set call_stack [get_call_stack 0]
  # call_stack: get_call_stack calc_wrap_stack_ix_adjust sprint_var
  # sprint_vars print_vars

  # Description of argument(s):
  # stack_top_ix                    The index to the bottom of the stack to be
  #                                 returned.  0 means include the entire
  #                                 stack.  1 means include the entire stack
  #                                 with the exception of this procedure
  #                                 itself, etc.
  # include_args                    Indicates whether proc args should be
  #                                 included in the result.

  set_var_default stack_top_ix -1

  # Get the current stack size.
  set stack_size [info level]
  # Calculate stack_bottom_ix.  Example:  if stack_size is 5, stack_bottom_ix
  # is -4.
  set stack_bottom_ix [expr 1 - $stack_size]
  for {set stack_ix $stack_top_ix} {$stack_ix >= $stack_bottom_ix} \
      {incr stack_ix -1} {
    if { $include_args } {
      set proc_name [info level $stack_ix]
    } else {
      set proc_name [lindex [info level $stack_ix] 0]
    }
    lappend call_stack $proc_name
  }

  return $call_stack

}
