#!/usr/bin/wish

# This file provides many valuable data processing functions like
# lappend_unique, get_var, etc.


proc lappend_unique { args } {

  # Add the each entry to a list if and only if they do not already exist in
  # the list.

  # Description of argument(s):
  # args                            The first argument should be the list
  #                                 name.  All other arguments are items to be
  #                                 added to the list.

  set list_name [lindex $args 0]
  # Remove first entry from args list.
  set args [lreplace $args 0 0]

  upvar 1 $list_name list

  if { ! [info exists list] } { set list {} }

  foreach arg $args {
    if { [lsearch -exact $list "${arg}"] != -1 } { continue }
    lappend list $arg
  }

}


proc lsubtract {main_list_name removal_list} {
  upvar $main_list_name ref_main_list

  # Remove any entry from the main list that is contained in removal list.

  # Description of argument(s):
  # main_list_name                  The name of your master list.
  # removal_list                    The list of items to be removed from
  #                                 master list.

  # For each element in the removal list, find the corresponding entry in the
  # master list and remove it.
  for {set removal_ix 0} {$removal_ix < [llength $removal_list ]}\
      {incr removal_ix} {
    set value [lindex $removal_list $removal_ix]
    set master_ix [lsearch $ref_main_list $value]
    set ref_main_list [lreplace $ref_main_list $master_ix $master_ix]
  }

}


proc list_map { list expression } {

  # Create and return a new list where each element of the new list is a
  # result of running the given expression on the corresponding entry from the
  # original list.

  # Description of argument(s):
  # list                            A list to be operated on.
  # expression                      A command expression to be run on each
  #                                 element in the list (e.g. '[string range
  #                                 $x 1 end]').

  foreach x $list {
    set cmd_buf "lappend new_list ${expression}"
    eval $cmd_buf
  }

  return $new_list

}


proc list_filter { list expression } {

  # Create and return a new list consisting of all elements of the original
  # list that do NOT pass the expression.

  # Description of argument(s):
  # list                            A list to be operated on.
  # expression                      A command expression to be run on each
  #                                 element in the list (e.g. 'regexp
  #                                 -expanded {^[[:blank:]]*\#|^[[:blank:]]*$}
  #                                 $x', 'string equal $x ""', etc.).

  set new_list {}

  foreach x $list {
    set cmd_buf "set result \[${expression}\]"
    eval $cmd_buf
    if { ! $result } { lappend new_list $x }
  }

  return $new_list

}


proc list_filter_comments { list } {

  # Filter comments from list and return new_list as a result.

  # Description of argument(s):
  # list                            A list to be operated on.

  set comment_regexp {^[[:blank:]]*\#|^[[:blank:]]*$}

  set new_list [list_filter $list "regexp -expanded {$comment_regexp} \$x"]

  return $new_list

}


proc get_var { var_var { default ""} } {
  upvar 1 $var_var var_ref

  # Return the value of the variable expression or the value of default if
  # the variable is not defined.

  # Example use:
  # set PATH [get_var ::env(PATH) "/usr/bin"]

  # Description of argument(s):
  # var_var                         The name of a variable (e.g.
  #                                 "::env(NANOSECOND)" or "var1").
  # default                         The default value to return if the
  #                                 variable named in var_var does not exist.

  expr { [info exists var_ref] ? [return $var_ref] : [return $default] }

}


proc set_var_default { var_name { default ""} } {
  upvar 1 $var_name var_ref

  # If the variable named in var_name is either blank or non-existent, set
  # its value to the default.

  # Example use:
  # set_var_default indent 0

  # Description of argument(s):
  # var_name                        The name of a variable.
  # default                         The default value to assign to the
  #                                 variable if the variable named in var_name
  #                                 is blank or non-existent.

  if { ! ([info exists var_ref] && $var_ref != "") } {
    set var_ref $default
  }

}


proc split_path {path dir_path base_name} {
  upvar $dir_path ref_dir_path
  upvar $base_name ref_base_name

  # Split a path into it's dir_path and base_name.  The dir_path variable
  # will include a trailing slash.

  # Description of argument(s):
  # path                            The directory or file path.
  # dir_path                        The variable to contain the resulting
  #                                 directory path which will include a
  #                                 trailing slash.
  # base_name                       The variable to contain the resulting base
  #                                 directory or file name.

  set ref_dir_path "[file dirname ${path}]/"
  set ref_base_name "[file tail $path]"

}


proc read_properties_file {parm_file_path} {

  # Read properties files and return key/value pairs as a list.

  # Description of arguement(s):
  # parm_file_path                  The path to the properties file.

  # The properties file must have the following format:
  # var_name=var_value
  # Comment lines (those beginning with a "#") and blank lines are allowed
  # and will be ignored.  Leading and trailing single or double quotes will be
  # stripped from the value.  E.g.
  # var1="This one"
  # Quotes are stripped so the resulting value for var1 is:
  # This one

  # Suggestion: The caller can then process the result as an array or a
  # dictionary.

  # Example usage:

  # array set properties [read_properties_file $file_path]
  # print_var properties

  # With the following result...

  # properties:
  #   properties(command):  string

  # Or...

  # set properties [read_properties_file $file_path]
  # print_dict properties

  # With the following result...

  # properties:
  #   properties[command]:  string

  # Initialize properties array.

  set properties [list]

  # Read the entire file into a list, filtering comments out.
  set file_descriptor [open $parm_file_path r]
  set file_data [list_filter_comments [split [read $file_descriptor] "\n"]]
  close $file_descriptor

  foreach line $file_data {
    # Split <var_name>=<var_value> into component parts.
    set pair [split $line =]
    lappend properties [lindex ${pair} 0]
    lappend properties [string trim [lindex ${pair} 1] {"}]
  }

  return $properties

}


proc convert_array_keys {source_arr target_arr {convert_commands}\
  {prefix ""} } {
  upvar $source_arr source_arr_ref
  upvar $target_arr target_arr_ref

  # Convert the keys of source_arr according to the caller's convert_commands
  # and put the resulting array in target_arr. If this function fails for any
  # reason, it will return non-zero

  # Description of arguement(s):
  # source_arr                      The source array that is to be converted.
  # target_arr                      The target array that results from the
  #                                 conversion.
  # convert_commands                A list of custom commands that indicate
  #                                 the type of conversion(s) the caller
  #                                 wishes to see. Currently the accepted
  #                                 values are as follows:
  #   - upper         Convert key value to uppercase.
  #   - lower         Convert key value to lowercase.
  # - prefix        Prepend prefix to the key, provided that it does not
  # already exist. If upper or lower is included in convert_commands list, the
  # prefix will be converted to the specified case as well.
  #   - rm_prefix   Remove a prefix that is prepended, provided that it exists.
  # prefix                          The prefix to be used for "prefix" and
  #                                 "rm_prefix" commands (see convert_commands
  #                                 text above).

  # Validate arguments.
  if { [lsearch $convert_commands lower] != -1 } {
    if { [lsearch $convert_commands upper] != -1 } {
      return -code error "Cannot convert to both upper and lower cases."
    }
  }

  if { [lsearch $convert_commands rm_prefix] != -1} {
    if { [lsearch $convert_commands prefix] != -1} {
      return -code error "Cannot add and remove a prefix."
    }
  }

  if { [lsearch $convert_commands prefix] != -1 ||\
       [lsearch $convert_commands rm_prefix] != -1 } {
    if { [lsearch $convert_commands upper] != -1 } {
      set prefix [string toupper $prefix]
    } elseif { [lsearch $convert_commands lower] != -1 } {
      set prefix [string tolower $prefix]
    }
  }

  # Initialize targ array.
  array set target_arr_ref {}

  # Walk the source array doing the conversion specified in convert_commands.
  set search_token [array startsearch source_arr_ref]
  while {[array anymore source_arr_ref $search_token]} {
    set key [array nextelement source_arr_ref $search_token]
    set arr_value $source_arr_ref($key)
    set new_key "$key"

    foreach command $convert_commands {
      if { $command == "prefix" } {
        regsub -all "^$prefix" $new_key {} new_key
        set new_key "$prefix$new_key"
      } elseif { $command == "rm_prefix" } {
        regsub -all "^$prefix" $new_key {} new_key
        set new_key "$new_key"
      }
      if { $command == "upper" } {
        set new_key [string toupper $new_key]
      } elseif { $command == "lower" } {
        set new_key [string tolower $new_key]
      }
    }
    set cmd_buf "set target_arr_ref($new_key) $arr_value"
    eval $cmd_buf
  }
  array donesearch source_arr_ref $search_token

}


proc expand_shell_string {buffer} {
  upvar $buffer ref_buffer

  # Call upon the shell to expand the string in "buffer", i.e. the shell will
  # make substitutions for environment variables and glob expressions.

  # Description of arguement(s):
  # buffer                          The buffer to be expanded.

  # This is done to keep echo from interpreting all of the double quotes away.
  regsub -all {\"} $ref_buffer "\\\"" ref_buffer

  # Bash will compress extra space delimiters if you don't quote the string.
  # So, we quote the argument to echo.
  if {[catch {set ref_buffer [exec bash -c "echo \"$ref_buffer\""]} result]} {
    puts stderr $result
    exit 1
  }

}


proc add_trailing_string { buffer { add_string "/" } } {
  upvar $buffer ref_buffer

  # Add the add string to the end of the buffer if and only if it doesn't
  # already end with the add_string.

  # Description of arguement(s):
  # buffer                          The buffer to be modified.
  # add_string                      The string to conditionally append to the
  #                                 buffer.

  regsub -all "${add_string}$" $ref_buffer {} ref_buffer
  set ref_buffer "${ref_buffer}${add_string}"

}


