# This file is an aid in sourcing other tcl files.  It provides the following
# advantages:
# - It shortens the number of lines of code needed to intelligently source
# files.
# - Its my_source procedure provides several benefits (see my_source prolog
# below).

# By convention, this file, or a link to this file, must exist in one of the
# directories named in the PATH environment variable.

# Example use:
# source [exec bash -c "which source.tcl"]
# my_source [list print.tcl opt.tcl]

set path_list [split $::env(PATH) :]


proc tcl_which { file_name } {

  # Search the PATH environment variable for the first executable instance of
  # $file_name and return the full path.  On failure, return a blank string.

  # This procedure runs much faster than [exec bash -c "which $file_name"].

  # Description of argument(s):
  # file_name                       The name of the file to be found.

  global path_list

  foreach path $path_list {
    set file_path $path/$file_name
    if { [file executable $file_path] } { return $file_path }
  }

  return ""

}


if { ![info exists sourced_files] } {
  set sourced_files [list]
}

proc my_source { source_files } {

  # Source each file in the source_files list.

  # This procedure provides the following benefits verses just using the
  # source command directly.
  # - Use of PATH environment variable to locate files.
  # - Better error handling.
  # - Will only source each file once.
  # - If "filex" is not found, this procedure will try to find "filex.tcl".

  # Description of argument(s):
  # source_files                    A list of file names to be sourced.

  global sourced_files
  global env

  foreach file_name $source_files {

    set file_path [tcl_which $file_name]
    if { $file_path == "" } {
      # Does the user specify a ".tcl" extension for this file?
      set tcl_ext [regexp -expanded {\.tcl$} $file_name]
      if { $tcl_ext } {
        append message "**ERROR** Programmer error - Failed to find"
        append message " \"${file_name}\" source file:\n"
        append message $::env(PATH)
        puts stderr $message
        exit 1
      }

      set file_path [tcl_which ${file_name}.tcl]
      if { $file_path == "" } {
        append message "**ERROR** Programmer error - Failed to find either"
        append message " \"${file_name}\" or \"${file_name}.tcl\" source file:"
        append message $::env(PATH)
        puts stderr $message
        exit 1
      }
    }

    # Adjust name (in case we found the .tcl version of a file).
    set full_file_name "[file tail $file_path]"

    # Have we already attempted to source this file?
    if { [lsearch -exact $sourced_files $full_file_name] != -1 } { continue }
    # Add the file name to the list of sourced files.  It is important to add
    # this file to the list BEFORE we source the file.  Otherwise, if there is
    # a recursive source (a sources b, b sources c, c sources a), we will get
    # into an infinite loop.
    lappend sourced_files $full_file_name

    if { [catch { uplevel 1 source $file_path } result] } {
      append message "**ERROR** Programmer error - Failed to source"
      append message " \"${file_path}\":\n${result}"
      puts stderr $message

      exit 1
    }
  }

}
