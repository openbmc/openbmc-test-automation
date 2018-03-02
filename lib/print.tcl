#!/usr/bin/wish

# This file provides many valuable print procedures such as sprint_var,
# sprint_time, sprint_error, etc.

my_source [list data_proc.tcl call_stack.tcl]

# Need "Expect" package for trap procedure.
package require Expect


# Setting the following variables for use both inside this file and by
# programs sourcing this file.
set program_path $argv0
set program_dir_path "[file dirname $argv0]/"
set program_name "[file tail $argv0]"
# Some procedures (e.g. sprint_pgm_header) need a program name value that
# looks more like a valid variable name.  Therefore, we'll swap out odd
# characters (like ".") for underscores.
regsub {\.} $program_name "_" pgm_name_var_name

# Initialize some time variables used in procedures in this file.
set start_time [clock microseconds]


proc calc_wrap_stack_ix_adjust {} {

  # Calculate and return a number which can be used as an offset into the
  # call stack for wrapper procedures.

  # NOTE: This procedure is designed expressly to work with this file's print
  # procedures scheme (i.e. print_x is a wrapper for sprint_x, etc.).  In
  # other words, this procedure may not be well-suited for general use.

  # Get a list of the procedures in the call stack beginning with our
  # immediate caller on up to the top-level caller.
  set call_stack [get_call_stack -2]

  # The first stack entry is our immediate caller.
  set caller [lindex $call_stack 0]
  # Remove first entry from stack.
  set call_stack [lreplace $call_stack 0 0]
  # Strip any leading "s" to arrive at base_caller name (e.g. the
  # corresponding base name for "sprint_var" would be "print_var").
  set base_caller [string trimleft $caller s]
  # Account for alias print procedures which have "p" vs "print_" (e.g. pvar
  # vs print_var).
  regsub "print_" $base_caller "p" alias_base_caller

  # Initialize the stack_ix_adjust value.
  set stack_ix_adjust 0
  # Note: print_vars|pvars is a special case so we add it explicitly to the
  # regex below.
  set regex ".*(${base_caller}|${alias_base_caller}|print_vars|pvars)$"
  foreach proc_name $call_stack {
    # For every remaining stack item that looks like a wrapper (i.e. matches
    # our regex), we increment the stack_ix_adjust.
    if { [regexp -expanded $regex $proc_name]} {
      incr stack_ix_adjust
      continue
    }
    # If there is no match, then we are done.
    break
  }

  return $stack_ix_adjust

}


# hidden_text is a list of passwords which are to be replaced with asterisks
# by print procedures defined in this file.
set hidden_text [list]
# password_regex is created from the contents of the hidden_text list above.
set password_regex ""

proc register_passwords {args} {

  # Register one or more passwords which are to be hidden in output produced
  # by the print procedures in this file.

  # Note: Blank password values are NOT registered.  They are simply ignored.

  # Description of argument(s):
  # args                            One or more password values.  If a given
  #                                 password value is already registered, this
  #                                 procedure will simply ignore it, i.e.
  #                                 there will be no duplicate values in the
  #                                 hidden_text list.

  global hidden_text
  global password_regex

  foreach password $args {
    # Skip blank passwords.
    if { $password == "" } { continue }
    # Skip already-registered passwords.
    if { [lsearch -exact $hidden_text $password] != -1 } { continue }
    # Put the password into the global hidden_text list.
    lappend hidden_text $password
  }

  # TODO: Excape metachars in the password_regex.
  set password_regex [join $hidden_text |]

}


proc replace_passwords {buffer} {

  # Replace all registered password found in buffer with a string of
  # asterisks and return the result.

  # Description of argument(s):
  # buffer                          The string to be altered and returned.

  # Note:  If environment variable GEN_PRINT_DEBUG is set, this procedure
  # will do nothing.

  global env
  if { [get_var ::env(GEN_PRINT_DEBUG) 0] } { return $buffer }
  if { [get_var ::env(DEBUG_SHOW_PASSWORDS) 0] } { return $buffer }

  global password_regex

  # No passwords to replace?
  if { $password_regex == "" } { return $buffer }

  regsub -all "${password_regex}" $buffer {********} buffer
  return $buffer

}


proc my_time { cmd_buf { iterations 100 } } {

  # Run the "time" function on the given command string and print the results.

  # The main benefit of running this vs just doing the "time" command directly:
  # - This will print the results.

  # Description of argument(s):
  # cmd_buf                         The command string to be run.
  # iterations                      The number of times to run the command
  #                                 string.  Typically, more iterations yields
  #                                 more accurate results.

  print_issuing $cmd_buf
  set result [time {uplevel 1 $cmd_buf} $iterations]

  set raw_microseconds [lindex [split [lindex $result 0] .] 0]
  set seconds [expr $raw_microseconds / 1000000]
  set raw_microseconds [expr $raw_microseconds % 1000000]

  set seconds_per_iteration [format "%i.%06i" ${seconds}\
        ${raw_microseconds}]

  print_var seconds_per_iteration

}


# If environment variable "GEN_PRINT_DEBUG" is set, this module will output
# debug data.  This is primarily intended for the developer of this module.
set GEN_PRINT_DEBUG [get_var ::env(GEN_PRINT_DEBUG) 0]

# The user can set the following environment variables to influence the
# output from print_time and print_var procedures.  See the prologs of those
# procedures for details.
set NANOSECONDS [get_var ::env(NANOSECONDS) 0]
set SHOW_ELAPSED_TIME [get_var ::env(SHOW_ELAPSED_TIME) 0]

# _gtp_default_print_var_width_ is adjusted based on NANOSECONDS and
# SHOW_ELAPSED_TIME.
if { $NANOSECONDS } {
  set _gtp_default_print_var_width_ 36
  set width_incr 14
} else {
  set _gtp_default_print_var_width_ 29
  set width_incr 7
}
if { $SHOW_ELAPSED_TIME } {
  incr _gtp_default_print_var_width_ $width_incr
  # Initializing _sprint_time_last_seconds_ which is a global value to
  # remember the clock seconds from the last time sprint_time was called.
  set _gtp_sprint_time_last_micro_seconds_ [clock microseconds]
}
# tcl_precision is a built-in Tcl variable that specifies the number of
# digits to generate when converting floating-point values to strings.
set tcl_precision 17


proc sprint { { buffer {} } } {

  # Simply return the user's buffer.
  # This procedure is used by the qprint and dprint functions defined
  # dynamically below, i.e. it would not normally be called for general use.

  # Description of arguments.
  # buffer                          This will be returned to the caller.

  return $buffer

}


proc sprintn { { buffer {} } } {

  # Simply return the user's buffer plus a trailing line feed..
  # This procedure is used by the qprintn and dprintn functions defined
  # dynamically below, i.e. it would not normally be called for general use.

  # Description of arguments.
  # buffer                          This will be returned to the caller.

  return ${buffer}\n

}


proc sprint_time { { buffer {} } } {

  # Return the time in a formatted manner as described below.

  # Example:

  # The following tcl code...

  # puts -nonewline [sprint_time()]
  # puts -nonewline ["Hi.\n"]

  # Will result in the following type of output:

  # #(CDT) 2016/07/08 15:25:35 - Hi.

  # Example:

  # The following tcl code...

  # puts -nonewline [sprint_time("Hi.\n")]

  # Will result in the following type of output:

  # #(CDT) 2016/08/03 17:12:05 - Hi.

  # The following environment variables will affect the formatting as
  # described:
  # NANOSECONDS                     This will cause the time stamps to be
  #                                 precise to the microsecond (Yes, it
  #                                 probably should have been named
  #                                 MICROSECONDS but the convention was set
  #                                 long ago so we're sticking with it).
  #                                 Example of the output when environment
  #                                 variable NANOSECONDS=1.

  # #(CDT) 2016/08/03 17:16:25.510469 - Hi.

  # SHOW_ELAPSED_TIME               This will cause the elapsed time to be
  #                                 included in the output.  This is the
  #                                 amount of time that has elapsed since the
  #                                 last time this procedure was called.  The
  #                                 precision of the elapsed time field is
  #                                 also affected by the value of the
  #                                 NANOSECONDS environment variable.  Example
  #                                 of the output when environment variable
  #                                 NANOSECONDS=0 and SHOW_ELAPSED_TIME=1.

  # #(CDT) 2016/08/03 17:17:40 -    0 - Hi.

  # Example of the output when environment variable NANOSECONDS=1 and
  # SHOW_ELAPSED_TIME=1.

  # #(CDT) 2016/08/03 17:18:47.317339 -    0.000046 - Hi.

  # Description of argument(s).
  # buffer                          A string string whhich is to be appended
  #                                 to the formatted time string and returned.

  global NANOSECONDS
  global _gtp_sprint_time_last_micro_seconds_
  global SHOW_ELAPSED_TIME

  # Get micro seconds since the epoch.
  set epoch_micro [clock microseconds]
  # Break the left and right of the decimal point.
  set epoch_seconds [expr $epoch_micro / 1000000]
  set epoch_decimal_micro [expr $epoch_micro % 1000000]

  set format_string "#(%Z) %Y/%m/%d %H:%M:%S"
  set return_string [clock format $epoch_seconds -format\
    "#(%Z) %Y/%m/%d %H:%M:%S"]

  if { $NANOSECONDS } {
    append return_string ".[format "%06i" ${epoch_decimal_micro}]"
  }

  if { $SHOW_ELAPSED_TIME } {
    set return_string "${return_string} - "

    set elapsed_micro [expr $epoch_micro - \
      $_gtp_sprint_time_last_micro_seconds_]
    set elapsed_seconds [expr $elapsed_micro / 1000000]

    if { $NANOSECONDS } {
      set elapsed_decimal_micro [expr $elapsed_micro % 1000000]
      set elapsed_float [format "%i.%06i" ${elapsed_seconds}\
        ${elapsed_decimal_micro}]
      set elapsed_time_buffer "[format "%11.6f" ${elapsed_float}]"
    } else {
      set elapsed_time_buffer "[format "%4i" $elapsed_seconds]"
    }
    set return_string "${return_string}${elapsed_time_buffer}"
  }

  set return_string "${return_string} - ${buffer}"

  set _gtp_sprint_time_last_micro_seconds_ $epoch_micro

  return $return_string

}


proc sprint_timen { args } {

  # Return the value of sprint_time + a line feed.

  # Description of argument(s):
  # args                            All args are passed directly to
  #                                 subordinate function, sprint_time.  See
  #                                 that function's prolog for details.

  return [sprint_time {*}$args]\n

}


proc sprint_error { { buffer {} } } {

  # Return a standardized error string which includes the callers buffer text.

  # Description of argument(s):
  # buffer                          Text to be returned as part of the error
  #                                 message.

  return [sprint_time "**ERROR** $buffer"]

}


proc sprint_varx { var_name var_value { indent 0 } { width {} } { hex 0 } } {

  # Return the name and value of the variable named in var_name in a
  # formatted way.

  # This procedure will visually align the output to look good next to
  # print_time output.

  # Example:

  # Given the following code:

  # print_timen "Initializing variables."
  # set first_name "Joe"
  # set last_name "Montana"
  # set age 50
  # print_varx last_name $last_name
  # print_varx first_name $first_name 2
  # print_varx age $age 2

  # With environment variables NANOSECONDS and SHOW_ELAPSED_TIME both set,
  # the following output is produced:

  # #(CST) 2017/12/14 16:38:28.259480 -    0.000651 - Initializing variables.
  # last_name:                                        Montana
  #   first_name:                                     Joe
  #   age:                                            50

  # Description of argument(s):
  # var_name                        The name of the variable whose name and
  #                                 value are to be printed.
  # var_value                       The value to be printed.
  # indent                          The number of spaces to indent each line
  #                                 of output.
  # width                           The width of the column containing the
  #                                 variable name.  By default this will align
  #                                 with the print_time text (see example
  #                                 above).
  # hex                             Indicates that the variable value is to be
  #                                 printed in hexedecimal format.  This is
  #                                 only valid if the variable value is an
  #                                 integer.  If the variable is NOT an
  #                                 integer and is blank, this will be
  #                                 interpreted to mean "print the string
  #                                 '<blank>', rather than an actual blank
  #                                 value".

  # Note: This procedure relies on global var _gtp_default_print_var_width_

  set_var_default indent 0

  global _gtp_default_print_var_width_
  set_var_default width $_gtp_default_print_var_width_

  if { $indent > 0 } {
    set width [expr $width - $indent]
  }

  if { $hex } {
    if { [catch {format "0x%08x" "$var_value"} result] } {
      if { $var_value == "" } { set var_value "<blank>" }
      set hex 0
    }
  }

  if { $hex } {
    append buffer "[format "%-${indent}s%-${width}s0x%08x" "" "$var_name:" \
      "$var_value"]"
  } else {
    append buffer "[format "%-${indent}s%-${width}s%s" "" "$var_name:" \
      "$var_value"]"
  }

  return $buffer\n

}


proc sprint_var { var_name args } {

  # Return the name and value of the variable named in var_name in a
  # formatted way.

  # This procedure will visually align the output to look good next to
  # print_time output.

  # Note: This procedure is the equivalent of sprint_varx with one
  # difference:  This function will figure out the value of the named variable
  # whereas sprint_varx expects you to pass the value.  This procedure in fact
  # calls sprint_varx to do its work.

  # Note: This procedure will detect whether var_name is an array and print
  # it accordingly (see the second example below).

  # Example:

  # Given the following code:

  # print_timen "Initializing variables."
  # set first_name "Joe"
  # set last_name "Montana"
  # set age 50
  # print_var last_name
  # print_var first_name 2
  # print_var age 2

  # With environment variables NANOSECONDS and SHOW_ELAPSED_TIME both set,
  # the following output is produced:

  # #(CST) 2017/12/14 16:38:28.259480 -    0.000651 - Initializing variables.
  # last_name:                                        Montana
  #   first_name:                                     Joe
  #   age:                                            50

  # Example:
  # Given the following code:

  # set data(0) cow
  # set data(1) horse
  # print_var data

  # data:
  #   data(0):                                        cow
  #   data(1):                                        horse

  # Description of argument(s):
  # var_name                        The name of the variable whose name and
  #                                 value are to be printed.
  # args                            The args understood by sprint_varx (after
  #                                 var_name and var_value).  See
  #                                 sprint_varx's prolog for details.

  # Note: This procedure relies on global var _gtp_default_print_var_width_

  # Determine who our caller is and therefore what upvar_level to use to get
  # var_value.
  set stack_ix_adjust [calc_wrap_stack_ix_adjust]
  set upvar_level [expr $stack_ix_adjust + 1]
  upvar $upvar_level $var_name var_value

  # Special processing for arrays:
  if { [array exists var_value] } {
    set indent [lindex $args 0]
    set args [lrange $args 1 end]
    set_var_default indent 0

    append buffer [format "%-${indent}s%s\n" "" "$var_name:"]
    incr indent 2
    incr width -2

    set search_token [array startsearch var_value]
    while {[array anymore var_value $search_token]} {
      set key [array nextelement var_value $search_token]
      set arr_value $var_value($key)
      append buffer [sprint_varx "${var_name}(${key})" $arr_value $indent\
        {*}$args]
    }
    array donesearch var_value $search_token
    return $buffer
  }

  return [sprint_varx $var_name $var_value {*}$args]

}


proc sprint_list { var_name args } {

  # Return the name and value of the list variable named in var_name in a
  # formatted way.

  # This procedure is the equivalent of sprint_var but for lists.

  # Description of argument(s):
  # var_name                        The name of the variable whose name and
  #                                 value are to be printed.
  # args                            The args understood by sprint_varx (after
  #                                 var_name and var_value).  See
  #                                 sprint_varx's prolog for details.

  # Note: In TCL, there is no way to determine that a variable represents a
  # list vs a string, etc.  It is up to the programmer to decide how the data
  # is to be interpreted.  Thus the need for procedures such as this one.
  # Consider the following code:

  # set my_list {one two three}
  # print_var my_list
  # print_list my_list

  # Output from aforementioned code:
  # my_list:                                          one two three
  # my_list:
  #   my_list[0]:                                     one
  #   my_list[1]:                                     two
  #   my_list[2]:                                     three

  # As far as print_var is concerned, my_list is a string and is printed
  # accordingly.  By using print_list, the programmer is asking to have the
  # output shown as a list with list indices, etc.

  # Determine who our caller is and therefore what upvar_level to use.
  set stack_ix_adjust [calc_wrap_stack_ix_adjust]
  set upvar_level [expr $stack_ix_adjust + 1]
  upvar $upvar_level $var_name var_value

  set indent [lindex $args 0]
  set args [lrange $args 1 end]
  set_var_default indent 0

  append buffer [format "%-${indent}s%s\n" "" "$var_name:"]
  incr indent 2

  set index 0
  foreach element $var_value {
    append buffer [sprint_varx "${var_name}\[${index}\]" $element $indent\
      {*}$args]
    incr index
  }

  return $buffer

}


proc sprint_dict { var_name args } {

  # Return the name and value of the dictionary variable named in var_name in
  # a formatted way.

  # This procedure is the equivalent of sprint_var but for dictionaries.

  # Description of argument(s):
  # var_name                        The name of the variable whose name and
  #                                 value are to be printed.
  # args                            The args understood by sprint_varx (after
  #                                 var_name and var_value).  See
  #                                 sprint_varx's prolog for details.

  # Note: In TCL, there is no way to determine that a variable represents a
  # dictionary vs a string, etc.  It is up to the programmer to decide how the
  # data is to be interpreted.  Thus the need for procedures such as this one.
  # Consider the following code:

  # set my_dict [dict create first Joe last Montana age 50]
  # print_var my_dict
  # print_dict my_dict

  # Output from aforementioned code:
  # my_dict:                                         first Joe last Montana
  # age 50
  # my_dict:
  #  my_dict[first]:                                 Joe
  #  my_dict[last]:                                  Montana
  #  my_dict[age]:                                   50

  # As far as print_var is concerned, my_dict is a string and is printed
  # accordingly.  By using print_dict, the programmer is asking to have the
  # output shown as a dictionary with dictionary keys/values, etc.

  # Determine who our caller is and therefore what upvar_level to use.
  set stack_ix_adjust [calc_wrap_stack_ix_adjust]
  set upvar_level [expr $stack_ix_adjust + 1]
  upvar $upvar_level $var_name var_value

  set indent [lindex $args 0]
  set args [lrange $args 1 end]
  set_var_default indent 0

  append buffer [format "%-${indent}s%s\n" "" "$var_name:"]
  incr indent 2

  foreach {key value} $var_value {
    append buffer [sprint_varx "${var_name}\[${key}\]" $value $indent {*}$args]
    incr index
  }

  return $buffer

}


proc sprint_vars { args } {

  # Sprint the values of one or more variables.

  # Description of arg(s):
  # args:  A list of variable names to be printed.  The first argument in the
  # arg list found to be an integer (rather than a variable name) will be
  # interpreted to be first of several possible sprint_var arguments (e.g.
  # indent, width, hex).  See the prologue for sprint_var above for
  # descriptions of this variables.

  # Example usage:
  # set var1 "hello"
  # set var2 "there"
  # set indent 2
  # set buffer [sprint_vars var1 var2]
  # or...
  # set buffer [sprint_vars var1 var2 $indent]

  # Look for integer arguments.
  set first_int_ix [lsearch -regexp $args {^[0-9]+$}]
  if { $first_int_ix == -1 } {
    # If none are found, sub_args is set to empty.
    set sub_args {}
  } else {
    # Set sub_args to the portion of the arg list that are integers.
    set sub_args [lrange $args $first_int_ix end]
    # Re-set args to exclude the integer values.
    set args [lrange $args 0 [expr $first_int_ix - 1]]
  }

  foreach arg $args {
    append buffer [sprint_var $arg {*}$sub_args]
  }

  return $buffer

}


proc sprint_dashes { { indent 0 } { width 80 } { line_feed 1 } { char "-" } } {

  # Return a string of dashes to the caller.

  # Description of argument(s):
  # indent                          The number of characters to indent the
  #                                 output.
  # width                           The width of the string of dashes.
  # line_feed                       Indicates whether the output should end
  #                                 with a line feed.
  # char                            The character to be repeated in the output
  #                                 string.  In other words, you can call on
  #                                 this function to print a string of any
  #                                 character (e.g. "=", "_", etc.).

  set_var_default indent 0
  set_var_default width 80
  set_var_default line_feed 1

  append buffer [string repeat " " $indent][string repeat $char $width]
  append buffer [string repeat "\n" $line_feed]

  return $buffer

}


proc sprint_executing {{ include_args 1 }} {

  # Return a string that looks something like this:
  # #(CST) 2017/11/28 15:08:03.261466 -    0.015214 - Executing: proc1 hi

  # Description of argument(s):
  # include_args                    Indicates whether proc args should be
  #                                 included in the result.

  set stack_ix_adjust [calc_wrap_stack_ix_adjust]
  set level [expr -(2 + $stack_ix_adjust)]
  return "[sprint_time]Executing: [get_stack_proc_name $level $include_args]\n"

}


proc sprint_issuing { { cmd_buf "" } { test_mode 0 } } {

  # Return a line indicating a command that the program is about to execute.

  # Sample output for a cmd_buf of "ls"

  # #(CDT) 2016/08/25 17:57:36 - Issuing: ls

  # Description of arg(s):
  # cmd_buf                         The command to be executed by caller.  If
  #                                 this is blank, this procedure will search
  #                                 up the stack for the first cmd_buf value
  #                                 to use.
  # test_mode                       With test_mode set, your output will look
  #                                 like this:

  # #(CDT) 2016/08/25 17:57:36 - (test_mode) Issuing: ls

  if { $cmd_buf == "" } {
    set cmd_buf [get_stack_var cmd_buf {} 2]
  }

  append buffer [sprint_time]
  if { $test_mode } {
    append buffer "(test_mode) "
  }
  append buffer "Issuing: ${cmd_buf}\n"

  return $buffer

}


proc sprint_call_stack { { indent 0 } } {

  # Return a call stack report for the given point in the program with line
  # numbers, procedure names and procedure parameters and arguments.

  # Sample output:

  # ---------------------------------------------------------------------------
  # TCL procedure call stack

  # Line # Procedure name and arguments
  # ------ --------------------------------------------------------------------
  #     21 print_call_stack
  #     32 proc1 257
  # ---------------------------------------------------------------------------

  # Description of arguments:
  # indent                          The number of characters to indent each
  #                                 line of output.

  append buffer "[sprint_dashes ${indent}]"
  append buffer "[string repeat " " $indent]TCL procedure call stack\n\n"
  append buffer "[string repeat " " $indent]"
  append buffer "Line # Procedure name and arguments\n"
  append buffer "[sprint_dashes $indent 6 0] [sprint_dashes 0 73]"

  for {set ix [expr [info level]-1]} {$ix > 0} {incr ix -1} {
    set frame_dict [info frame $ix]
    set line_num [dict get $frame_dict line]
    set proc_name_plus_args [dict get $frame_dict cmd]
    append buffer [format "%-${indent}s%6i %s\n" "" $line_num\
      $proc_name_plus_args]
  }
  append buffer "[sprint_dashes $indent]"

  return $buffer

}


proc sprint_tcl_version {} {

  # Return the name and value of tcl_version in a formatted way.

  global tcl_version

  return [sprint_var tcl_version]

}


proc sprint_error_report { { error_text "\n" } { indent 0 } } {

  # Return a string with a standardized report which includes the caller's
  # error text, the call stack and the program header.

  # Description of arg(s):
  # error_text                      The error text to be included in the
  #                                 report.  The caller should include any
  #                                 needed linefeeds.
  # indent                          The number of characters to indent each
  #                                 line of output.

  set width 120
  set char "="
  set line_feed 1
  append buffer [sprint_dashes $indent $width $line_feed $char]
  append buffer [string repeat " " $indent][sprint_error $error_text]
  append buffer "\n"
  append buffer [sprint_call_stack $indent]
  append buffer [sprint_pgm_header $indent]
  append buffer [sprint_dashes $indent $width $line_feed $char]

  return $buffer

}


proc sprint_pgm_header { {indent 0} {linefeed 1} } {

  # Return a standardized header that programs should print at the beginning
  # of the run.  It includes useful information like command line, pid,
  # userid, program parameters, etc.

  # Description of arguments:
  # indent                          The number of characters to indent each
  #                                 line of output.
  # linefeed                        Indicates whether a line feed be included
  #                                 at the beginning and end of the report.

  global program_name
  global pgm_name_var_name
  global argv0
  global argv
  global env
  global _gtp_default_print_var_width_

  set_var_default indent 0

  set indent_str [string repeat " " $indent]
  set width [expr $_gtp_default_print_var_width_ + $indent]

  # Get variable values for output.
  set command_line "$argv0 $argv"
  set pid_var_name ${pgm_name_var_name}_pid
  set $pid_var_name [pid]
  set uid [get_var ::env(USER) 0]
  set host_name [get_var ::env(HOSTNAME) 0]
  set DISPLAY [get_var ::env(DISPLAY) 0]

  # Generate the report.
  if { $linefeed } { append buffer "\n" }
  append buffer ${indent_str}[sprint_timen "Running ${program_name}."]
  append buffer ${indent_str}[sprint_timen "Program parameter values, etc.:\n"]
  append buffer [sprint_var command_line $indent $width]
  append buffer [sprint_var $pid_var_name $indent $width]
  append buffer [sprint_var uid $indent $width]
  append buffer [sprint_var host_name $indent $width]
  append buffer [sprint_var DISPLAY $indent $width]

  # Print caller's parm names/values.
  global longoptions
  global pos_parms

  regsub -all ":" "${longoptions} ${pos_parms}" {} parm_names

  foreach parm_name $parm_names {
    set cmd_buf "global $parm_name ; append buffer"
    append cmd_buf " \[sprint_var $parm_name $indent $width\]"
    eval $cmd_buf
  }

  if { $linefeed } { append buffer "\n" }

  return $buffer

}


proc sprint_pgm_footer {} {

  # Return a standardized footer that programs should print at the end of the
  # program run.  It includes useful information like total run time, etc.

  global program_name
  global pgm_name_var_name
  global start_time

  # Calculate total runtime.
  set total_time_micro [expr [clock microseconds] - $start_time]
  # Break the left and right of the decimal point.
  set total_seconds [expr $total_time_micro / 1000000]
  set total_decimal_micro [expr $total_time_micro % 1000000]
  set total_time_float [format "%i.%06i" ${total_seconds}\
    ${total_decimal_micro}]
  set total_time_string [format "%0.6f" $total_time_float]
  set runtime_var_name ${pgm_name_var_name}_runtime
  set $runtime_var_name $total_time_string

  append buffer [sprint_timen "Finished running ${program_name}."]
  append buffer "\n"
  append buffer [sprint_var $runtime_var_name]
  append buffer "\n"

  return $buffer

}


proc sprint_arg_desc { arg_title arg_desc { indent 0 } { col1_width 25 }\
  { line_width 80 } } {

  # Return a formatted argument description.

  # Example:
  #
  # set desc "When in the Course of human events, it becomes necessary for
  # one people to dissolve the political bands which have connected them with
  # another, and to assume among the powers of the earth, the separate and
  # equal station to which the Laws of Nature and of Nature's God entitle
  # them, a decent respect to the opinions of mankind requires that they
  # should declare the causes which impel them to the separation."

  # set buffer [sprint_arg_desc "--declaration" $desc]
  # puts $buffer

  # Resulting output:
  # --declaration            When in the Course of human events, it becomes
  #                          necessary for one people to dissolve the
  #                          political bands which have connected them with
  #                          another, and to assume among the powers of the
  #                          earth, the separate and equal station to which
  #                          the Laws of Nature and of Nature's God entitle
  #                          them, a decent respect to the opinions of mankind
  #                          requires that they should declare the causes
  #                          which impel them to the separation.

  # Description of argument(s):
  # arg_title                       The content that you want to appear on the
  #                                 first line in column 1.
  # arg_desc                        The text that describes the argument.
  # indent                          The number of characters to indent.
  # col1_width                      The width of column 1, which is the column
  #                                 containing the arg_title.
  # line_width                      The total max width of each line of output.

  set fold_width [expr $line_width - $col1_width]
  set escaped_arg_desc [escape_bash_quotes "${arg_desc}"]

  set cmd_buf "echo '${escaped_arg_desc}' | fold --spaces --width="
  append cmd_buf "${fold_width} | sed -re 's/\[ \]+$//g'"
  set out_buf [eval exec bash -c {$cmd_buf}]

  set help_lines [split $out_buf "\n"]

  set buffer {}

  set line_num 1
  foreach help_line $help_lines {
    if { $line_num == 1 } {
      if { [string length $arg_title] > $col1_width } {
        # If the arg_title is already wider than column1, print it on its own
        # line.
        append buffer [format "%${indent}s%-${col1_width}s\n" ""\
          "$arg_title"]
        append buffer [format "%${indent}s%-${col1_width}s%s\n" "" ""\
          "${help_line}"]
      } else {
        append buffer [format "%${indent}s%-${col1_width}s%s\n" ""\
          "$arg_title" "${help_line}"]
      }
    } else {
      append buffer [format "%${indent}s%-${col1_width}s%s\n" "" ""\
        "${help_line}"]
    }
    incr line_num
  }

  return $buffer

}


# Define the create_print_wrapper_procs to help us create print wrappers.
# First, create templates.
# Notes:
# - The resulting procedures will replace all registered passwords.
# - The resulting "quiet" and "debug" print procedures will search the stack
# for quiet and debug, respectively.  That means that the if a procedure calls
# qprint_var and the procedure has a local version of quiet set to 1, the
# print will not occur, even if there is a global version of quiet set to 0.
set print_proc_template "  puts -nonewline<output_stream> \[replace_passwords"
append print_proc_template " \[<base_proc_name> {*}\$args\]\]\n}\n"
set qprint_proc_template "  set quiet \[get_stack_var quiet 0\]\n  if {"
append qprint_proc_template " \$quiet } { return }\n${print_proc_template}"
set dprint_proc_template "  set debug \[get_stack_var debug 0\]\n  if { !"
append dprint_proc_template " \$debug } { return }\n${print_proc_template}"

# Put each template into the print_proc_templates array.
set print_proc_templates(p) $print_proc_template
set print_proc_templates(q) $qprint_proc_template
set print_proc_templates(d) $dprint_proc_template
proc create_print_wrapper_procs {proc_names {stderr_proc_names {}} } {

  # Generate code for print wrapper procs and return the generated code as a
  # string.

  # To illustrate, suppose there is a "print_foo_bar" proc in the proc_names
  # list.
  # This proc will...
  # - Expect that there is an sprint_foo_bar proc already in existence.
  # - Create a print_foo_bar proc which calls sprint_foo_bar and prints the
  # result.
  # - Create a qprint_foo_bar proc which calls upon sprint_foo_bar only if
  # global value quiet is 0.
  # - Create a dprint_foo_bar proc which calls upon sprint_foo_bar only if
  # global value debug is 1.

  # Also, code will be generated to define aliases for each proc as well.
  # Each alias will be created by replacing "print_" in the proc name with "p"
  # For example, the alias for print_foo_bar will be pfoo_bar.

  # Description of argument(s):
  # proc_names                      A list of procs for which print wrapper
  #                                 proc code is to be generated.
  # stderr_proc_names               A list of procs whose generated code
  #                                 should print to stderr rather than to
  #                                 stdout.

  global print_proc_template
  global print_proc_templates

  foreach proc_name $proc_names {

    if { [expr [lsearch $stderr_proc_names $proc_name] == -1] } {
      set replace_dict(output_stream) ""
    } else {
      set replace_dict(output_stream) " stderr"
    }

    set base_proc_name "s${proc_name}"
    set replace_dict(base_proc_name) $base_proc_name

    set wrap_proc_names(p) $proc_name
    set wrap_proc_names(q) q${proc_name}
    set wrap_proc_names(d) d${proc_name}

    foreach template_key [list p q d] {
      set wrap_proc_name $wrap_proc_names($template_key)
      set call_line "proc ${wrap_proc_name} \{args\} \{\n"
      set proc_body $print_proc_templates($template_key)
      set proc_def ${call_line}${proc_body}
      foreach {key value} [array get replace_dict] {
        regsub -all "<$key>" $proc_def $value proc_def
      }
      regsub "print_" $wrap_proc_name "p" alias_proc_name
      regsub "${wrap_proc_name}" $proc_def $alias_proc_name alias_def
      append buffer "${proc_def}${alias_def}"
    }
  }

  return $buffer

}


# Get this file's path.
set frame_dict [info frame 0]
set file_path [dict get $frame_dict file]
# Get a list of this file's sprint procs.
set sprint_procs [get_file_proc_names $file_path sprint]
# Create a corresponding list of print_procs.
set proc_names [list_map $sprint_procs {[string range $x 1 end]}]
# Sort them for ease of debugging.
set proc_names [lsort $proc_names]

set stderr_proc_names [list print_error print_error_report]

set proc_def [create_print_wrapper_procs $proc_names $stderr_proc_names]
if { $GEN_PRINT_DEBUG } { puts $proc_def }
eval "${proc_def}"
