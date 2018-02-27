#!/usr/bin/wish

# This file provides many valuable parm and argument processing procedures
# such as longoptions, pos_parms, gen_get_options, etc.

my_source [list escape.tcl data_proc.tcl print.tcl]


proc get_arg_req { opt_name } {

  # Determine whether the given opt_name is "optional", "required" or
  # "not_allowed" and return that result.

  # Note:  This procedure assumes that global list longoptions has been
  # initialized via a call to the longoptions procedure.

  # Description of argument(s):
  # opt_name                        The name of the option including its
  #                                 requirement indicator as accepted by the
  #                                 bash getopt longoptions parameter: No
  #                                 colon means the option takes no argument,
  #                                 one colon means the option requires an
  #                                 argument and two colons indicate that an
  #                                 argument is optional (the value of the
  #                                 option will be 1 if no argument is
  #                                 specified.

  global longoptions

  if { [lsearch -exact $longoptions "${opt_name}::"] != -1 } {
    return optional
  }
  if { [lsearch -exact $longoptions "${opt_name}:"] != -1 } {
    return required
  }
  return not_allowed

}


proc longoptions { args } {

  # Populate the global longoptions list and set global option variable
  # defaults.

  # Description of argument(s):
  # args                            Each arg is comprised of 1) the name of
  #                                 the option 2) zero, one or 2 colons to
  #                                 indicate whether the corresponding
  #                                 argument value is a) not required, b)
  #                                 required or c) optional 3) Optionally, an
  #                                 equal sign followed by a default value for
  #                                 the parameter.

  # Example usage:
  # longoptions parm1 parm2: parm3:: test_mode:=0 quiet:=0

  global longoptions

  # Note: Because this procedure manipulates global variables, we use the
  # "_opt_<varname>_" format to minimize the possibility of naming collisions.
  set _opt_debug_ 0
  foreach _opt_arg_ $args {
    # Create an option record which is a 2-element list consisting of the
    # option specification and a possible default value.  Example:;
    # opt_rec:
    #   opt_rec[0]:      test_mode:
    #   opt_rec[1]:      0
    set _opt_rec_ [split $_opt_arg_ =]
    # opt_spec will include any colons that may have been specified.
    set _opt_spec_ [lindex $_opt_rec_ 0]
    # Add the option spec to the global longoptions list.
    lappend_unique longoptions $_opt_spec_
    # Strip the colons to get the option name.
    set _opt_name_ [string trimright $_opt_spec_ ":"]
    # Get the option's default value, if any.
    set _opt_default_value_ [lindex $_opt_rec_ 1]
    set _opt_arg_req_ [get_arg_req $_opt_name_]
    if { $_opt_arg_req_ == "not_allowed" && $_opt_default_value_ == "" } {
      # If this parm takes no arg and no default was specified by the user,
      # we will set the default to 0.
      set _opt_default_value_ 0
    }
    # Set a global variable whose name is identical to the option name.  Set
    # the default value if there is one.
    set _opt_cmd_buf_ "global ${_opt_name_}"
    if { $_opt_debug_ } { print_issuing $_opt_cmd_buf_ }
    eval $_opt_cmd_buf_
    set _opt_cmd_buf_ "set ${_opt_name_} {${_opt_default_value_}}"
    if { $_opt_debug_ } { print_issuing $_opt_cmd_buf_ }
    eval $_opt_cmd_buf_
  }

}


proc pos_parms { args } {

  # Populate the global pos_parms list and set global option variable defaults.

  # Description of argument(s):
  # args                            Each arg is comprised of the name of a
  #                                 positional parm and a possible initial
  #                                 value.

  # Example usage:
  # pos_parms user_name=mike

  global pos_parms

  set pos_parms [list]
  # Note: Because this procedure manipulates global variables, we use the
  # "_opt_<varname>_" format to minimize the possibility of naming collisions.
  set _opt_debug_ 0
  foreach _opt_arg_ $args {
    if { $_opt_debug_ } { print_var _opt_arg_ }
    # Create an option record which is a 2-element list consisting of the
    # option specification and a possible default value.  Example:;
    # opt_rec:
    #   opt_rec[0]:      test_mode:
    #   opt_rec[1]:      0
    set _opt_parm_rec_ [split $_opt_arg_ =]
    if { $_opt_debug_ } { print_list _opt_parm_rec_ }
    # parm_spec will include any colons that may have been specified.
    set _opt_parm_name_ [lindex $_opt_parm_rec_ 0]
    if { $_opt_debug_ } { print_var _opt_parm_name_ }
    # Add the option spec to the global pos_parms list.
    lappend pos_parms $_opt_parm_name_
    # Get the option's default value, if any.
    set _opt_parm_default_value_ [lindex $_opt_parm_rec_ 1]
    if { $_opt_debug_ } { print_var _opt_parm_default_value_ }
    # Set a global variable whose name is identical to the option name.  Set
    # the default value if there is one.
    set _opt_cmd_buf_ "global ${_opt_parm_name_} ; set ${_opt_parm_name_}"
    append _opt_cmd_buf_ " {${_opt_parm_default_value_}}"
    if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
    eval $_opt_cmd_buf_
  }

}


proc gen_get_options { argv } {

  # Get the command line options/arguments and use them to set the
  # corresponding global option variable names.

  # Note:  This procedure assumes that global list longoptions has been
  # initialized via a call to the longoptions procedure and that global
  # pos_parms has been initialized via a call to the pos_parms procdure.
  # These data structures indicates what options and arguments are supported
  # by the calling program.

  # Note: If the last var_name in pos_parms ends in "_list", then the caller
  # can specify as many parms as they desire and they will all be appended to
  # the variable in question.

  # Description of argument(s):
  # argv                            The argv array that is set for this
  #                                 program.

  # Example call:
  # gen_get_options $argv

  global longoptions
  global pos_parms
  global program_name

  # Note: Because this procedure manipulates global variables, we use the
  # "_opt_<varname>_" format to minimize the possibility of naming collisions.
  set _opt_debug_ 0

  set _opt_len_pos_parms_ [llength $pos_parms]

  if { $_opt_debug_ } {
    print_list longoptions
    print_list pos_parms
    print_var _opt_len_pos_parms_
  }

  # Rather than write the algorithm from scratch, we will call upon the bash
  # getopt program to help us.  This program has several advantages:
  # - It will reject illegal options
  # - It supports different posix input styles (e.g. -option <arg> vs
  # --option=<arg>).
  # - It allows the program's caller to abbreviate option names provided that
  # there is no ambiguity.

  # Convert curly braces to single quotes.  This includes escaping existing
  # quotes in the argv string.  This will allow us to use the result in a bash
  # command string.  Example: {--parm3=Kathy's cat} will become
  # '--parm3=Kathy'\''s cat'.
  if { $_opt_debug_ } { print_var argv }
  set _opt_bash_args_ [curly_braces_to_quotes $argv]
  set _opt_cmd_buf_ "getopt --name=${program_name} -a --longoptions=\"help"
  append _opt_cmd_buf_ " ${longoptions}\" --options=\"-h\" --"
  append _opt_cmd_buf_ " ${_opt_bash_args_}"
  if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
  if { [ catch {set OPT_LIST [eval exec bash -c {$_opt_cmd_buf_}]} result ] } {
    puts stderr $result
    exit 1
  }

  set OPT_LIST [quotes_to_curly_braces $OPT_LIST]
  set _opt_cmd_buf_ "set opt_list \[list $OPT_LIST\]"
  if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
  eval $_opt_cmd_buf_

  if { $_opt_debug_ } { print_list opt_list }

  set _opt_longopt_regex_ {\-[-]?[^- ]+}
  global help
  global h
  set help 0
  set h 0
  if { $_opt_debug_ } { printn ; print_timen "Processing opt_list." }
  set _opt_pos_parm_ix_ 0
  set _opt_current_longopt_ {}
  foreach opt_list_entry $opt_list {
    if { $_opt_debug_ } { print_var opt_list_entry }
    if { $opt_list_entry == "--" } { break; }
    if { $_opt_current_longopt_ != "" } {
      if { $_opt_debug_ } { print_var _opt_current_longopt_ }
      set _opt_cmd_buf_ "global ${_opt_current_longopt_} ; set"
      append _opt_cmd_buf_ " ${_opt_current_longopt_} {${opt_list_entry}}"
      if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
      eval $_opt_cmd_buf_
      set _opt_current_longopt_ {}
      if { $_opt_debug_ } { printn }
      continue
    }
    set _opt_is_option_ [regexp -expanded $_opt_longopt_regex_\
      ${opt_list_entry}]
    if { $_opt_debug_ } { print_var _opt_is_option_ }
    if { $_opt_is_option_ } {
      regsub -all {^\-[-]?} $opt_list_entry {} opt_name
      if { $_opt_debug_ } { print_var opt_name }
      set _opt_arg_req_ [get_arg_req $opt_name]
      if { $_opt_debug_ } { print_var _opt_arg_req_ }
      if { $_opt_arg_req_ == "not_allowed" } {
        set _opt_cmd_buf_ "global ${opt_name} ; set ${opt_name} 1"
        if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
        eval $_opt_cmd_buf_
      } else {
        set _opt_current_longopt_ [string trimleft $opt_list_entry "-"]
      }
    } else {
      # Must be a positional parm.
      if { $_opt_pos_parm_ix_ >= $_opt_len_pos_parms_ } {
        set _opt_is_list_ [regexp -expanded "_list$" ${pos_parm_name}]
        if { $_opt_debug_ } { print_var _opt_is_list_ }
        if { $_opt_is_list_ } {
          set _opt_cmd_buf_ "lappend ${pos_parm_name} {${opt_list_entry}}"
          if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
          eval $_opt_cmd_buf_
          continue
        }
        append message "The caller has specified more positional parms than"
        append message " are allowed by the program.\n"
        append message [sprint_varx parm_value ${opt_list_entry} 2]
        append message [sprint_list pos_parms 2]
        print_error_report $message
        exit 1
      }
      set _opt_pos_parm_name_ [lindex $pos_parms $_opt_pos_parm_ix_]
      set _opt_cmd_buf_ "global ${_opt_pos_parm_name_} ; set"
      append _opt_cmd_buf_ " ${_opt_pos_parm_name_} {${opt_list_entry}}"
      if { $_opt_debug_ } { pissuing $_opt_cmd_buf_ }
      eval $_opt_cmd_buf_
      incr _opt_pos_parm_ix_
    }
    if { $_opt_debug_ } { printn }
  }

  if { $h || $help } {
    if { [info proc help] != "" } {
      help
    } else {
      puts "No help text defined for this program."
    }
    exit 0
  }

}


proc print_usage {} {

  # Print usage help text line.

  # Example:
  # usage: demo.tcl [OPTIONS] [USERID] [FILE_LIST]

  global program_name
  global longoptions
  global pos_parms

  append buffer "usage: $program_name"

  if { $longoptions != "" } {
    append buffer " \[OPTIONS\]"
  }

  foreach parm $pos_parms {
    set upper_parm [string toupper $parm]
    append buffer " \[$upper_parm\]"
  }

  puts $buffer

}


proc print_option_help { option help_text { data_desc {} } { print_default {}}\
  { width 30 } } {

  # Print help text for the given option.

  # Description of argument(s):
  # option                          The option for which help text should be
  #                                 printed.  This value should include a
  #                                 leading "--" to indicate that this is an
  #                                 optional rather than a positional parm.
  # data_desc                       A description of the data (e.g. "dir
  #                                 path", "1,0", etc.)0
  # print_default                   Indicates whether the current value of the
  #                                 global variable representing the option is
  #                                 to be printed as a default value.  For
  #                                 example, if the option value is "--parm1",
  #                                 global value parm1 is "no" and
  #                                 print_default is set, the following phrase
  #                                 will be appended to the help text: The
  #                                 default value is "no".
  # width                           The width of the arguments column.

  set indent 2

  # Get the actual opt_name by stripping leading dashes and trailing colons.
  regsub -all {^\-[-]?} $option {} opt_name
  regsub -all {:[:]?$} $opt_name {} opt_name

  # Set defaults for args to this procedure.
  set longopt_regex {\-[-]?[^- ]+}
  set is_option [regexp -expanded $longopt_regex ${option}]
  if { $is_option } {
    # It is an option (vs positional parm).
    # Does it take an argument?
    set arg_req [get_arg_req $opt_name]
    if { $arg_req == "not_allowed" } {
      set data_desc_default ""
    } else {
      set data_desc_default "{$opt_name}"
    }
  } else {
    # It's a positional parm.
    set opt_name [string tolower $opt_name]
    set data_desc_default ""
  }

  set_var_default data_desc $data_desc_default
  set_var_default print_default 1

  if { $print_default } {
    # Access the global variable that represents the value of the option.
    eval global $opt_name
    set cmd_buf "set opt_value \${${opt_name}}"
    eval $cmd_buf
    set default_string "  The default value is \"${opt_value}\"."
  } else {
    set default_string ""
  }

  if { $data_desc != "" } {
    # Remove any curly braces and put them back on.
    set data_desc "{[string trim $data_desc {{}}]}"
  }

  print_arg_desc "$option $data_desc" "${help_text}${default_string}" 2 $width

}


# Create help text variables for stock parms like quiet, debug and test_mode.
set test_mode_help_text "This means that ${program_name} should go through"
append test_mode_help_text " all the motions but not actually do anything"
append test_mode_help_text " substantial. This is mainly to be used by the"
append test_mode_help_text " developer of ${program_name}."
set quiet_help_text "If this parameter is set to \"1\", ${program_name} will"
append quiet_help_text " print only essential information, i.e. it will not"
append quiet_help_text " echo parameters, echo commands, print the total run"
append quiet_help_text " time, etc."
set debug_help_text "If this parameter is set to \"1\", ${program_name} will"
append debug_help_text " print additional debug information. This is mainly to"
append debug_help_text " be used by the developer of ${program_name}."

proc gen_print_help { { width 30 } } {

  # Print general help text based on user's pos_parms and longoptions.

  # Note: To use this procedure, the user must create a global help_dict
  # containing entries for each of their options and one for the program as a
  # whole.  The keys of this dictionary are the option names and the values
  # are lists whose values map to arguments from the print_option_help
  # procedure:
  # - help_text
  # - data_desc (optional)
  # - print_default (1 or 0 - default is 1)

  #  Example:
  # set help_dict [dict create\
  #   ${program_name} [list "${program_name} will demonstrate..."]\
  #   userid [list "The userid of the caller."]\
  #   file_list [list "A list of files to be processed."]\
  #   flag [list "A flag to indicate that..."]\
  #   dir_path [list "The path to the directory containing the files."]\
  #   release [list "The code release."]\
  # ]

  global program_name
  global longoptions
  global pos_parms

  global help_dict
  global test_mode_help_text
  global quiet_help_text
  global debug_help_text

  # Add help text for stock options to global help_dict.
  dict set help_dict test_mode [list $test_mode_help_text "1,0"]
  dict set help_dict quiet [list $quiet_help_text "1,0"]
  dict set help_dict debug [list $debug_help_text "1,0"]

  puts ""
  print_usage

  # Retrieve the general program help text from the help_dict and print it.
  set help_entry [dict get $help_dict ${program_name}]
  puts ""

  append cmd_buf "echo '[escape_bash_quotes [lindex $help_entry 0]]' | fold"
  append cmd_buf " --spaces --width=80"
  set out_buf [eval exec bash -c {$cmd_buf}]

  puts "$out_buf"

  if { $pos_parms != "" } {
    puts ""
    puts "positional arguments:"
    foreach option $pos_parms {
      # Retrieve the print_option_help parm values from the help_dict and
      # call print_option_help.
      set help_entry [dict get $help_dict ${option}]
      set help_text [lindex $help_entry 0]
      set data_desc [lindex $help_entry 1]
      set print_default [lindex $help_entry 2]
      print_option_help [string toupper $option] $help_text $data_desc\
          $print_default $width
    }
  }

  if { $longoptions != "" } {
    puts ""
    puts "optional arguments:"
    foreach option $longoptions {
      set option [string trim $option ":"]
      # Retrieve the print_option_help parm values from the help_dict and
      # call print_option_help.
      set help_entry [dict get $help_dict ${option}]
      set help_text [lindex $help_entry 0]
      set data_desc [lindex $help_entry 1]
      set print_default [lindex $help_entry 2]
      print_option_help "--${option}" $help_text $data_desc $print_default\
        $width
    }
  }
  puts ""

}


proc return_program_options {} {

  # Return all the names of the global program options as a composite list.

  global longoptions pos_parms

  regsub -all {:} $longoptions {} program_options
  eval lappend program_options $pos_parms

  return $program_options

}


proc global_program_options {} {

  # Make all program option global variables available to the calling function.
  set program_options [return_program_options]
  uplevel eval global $program_options

}


proc gen_pre_validation {} {

  # Do generic post-validation processing.  By "post", we mean that this is
  # to be called from a validation function after the caller has done any
  # validation desired.  If the calling program passes exit_function and
  # signal_handler parms, this function will register them.  In other words,
  # it will make the signal_handler functions get called for SIGINT and
  # SIGTERM and will make the exit_function function run prior to the
  # termination of the program.

  # Make all program option global variables available to the calling function.
  uplevel global_program_options

}


proc gen_post_validation {} {

  # Do generic post-validation processing.  By "post", we mean that this is
  # to be called from a validation function after the caller has done any
  # validation desired.  If the calling program passes exit_function and
  # signal_handler parms, this function will register them.  In other words,
  # it will make the signal_handler functions get called for SIGINT and
  # SIGTERM and will make the exit_function function run prior to the
  # termination of the program.

  trap { exit_proc } [list SIGTERM SIGINT]

}
