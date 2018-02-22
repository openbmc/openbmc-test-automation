#!/bin/bash
#\
exec expect "$0" -- ${1+"$@"}

# This file contains utilities for working with Serial over Lan (SOL).
# Required Parameters:
#   openbmc_host                The BMC host name or IP address.
#   openbmc_password            The BMC password.
#   openbmc_username            The BMC user name.
#   os_host                     The OS host name or IP address.
#   os_username                 The OS Host user name.
#   os_password                 The OS Host password.
#   proc_name                   The procedure you want to run

# Example use case:
# sol_utils.tcl --os_host=ip --os_password=password --os_username=username
# --openbmc_host=ip --openbmc_password=password --openbmc_username=username
# --proc_name=boot_to_petitboot

source [exec bash -c "which source.tcl"]
my_source [list print.tcl opt.tcl valid.tcl call_stack.tcl tools.exp]

longoptions openbmc_host: openbmc_username:=root openbmc_password:=0penBmc\
  os_host: os_username:=root os_password: proc_name:=boot_to_petitboot\
  test_mode:=0 quiet:=0 debug:=0
pos_parms

set valid_proc_name [list os_login boot_to_petitboot]

# Create help dictionary for call to gen_print_help.
set help_dict [dict create\
  ${program_name} [list "${program_name} is an SOL utilities program that\
    will run the user's choice of utilities.  See the \"proc_name\" parm below\
    for details."]\
  openbmc_host [list "The OpenBMC host name or IP address." "host"]\
  openbmc_username [list "The OpenBMC username." "username"]\
  openbmc_password [list "The OpenBMC password." "password"]\
  os_host [list "The OS host name or IP address." "host"]\
  os_username [list "The OS username." "username"]\
  os_password [list "The OS password." "password"]\
  proc_name [list "The proc_name you'd like to run.  Valid values are as\
    follows: [regsub -all {\s+} $valid_proc_name {, }]."]\
]


# Setup state dictionary.
set state [dict create\
  ssh_logged_in 0\
  os_login_prompt 0\
  os_logged_in 0\
  petitboot_screen 0\
]


proc help {} {

  gen_print_help

}


proc exit_proc { {ret_code 0} } {

  # Execute whenever the program ends normally or with the signals that we
  # catch (i.e. TERM, INT).

  dprintn ; dprint_executing
  dprint_var ret_code

  set cmd_buf os_logoff
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  set cmd_buf sol_logoff
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  qprint_pgm_footer

  exit $ret_code

}


proc validate_parms {} {

  trap { exit_proc } [list SIGTERM SIGINT]

  valid_value openbmc_host
  valid_value openbmc_username
  valid_value openbmc_password
  valid_value os_host
  valid_value os_username
  valid_value os_password
  global valid_proc_name
  valid_value proc_name {} $valid_proc_name

}


proc sol_login {} {

  # Login to the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host openbmc_username openbmc_password
  global cr_lf_regex
  global ssh_password_prompt

  set cmd_buf "spawn -nottycopy ssh -p 2200 $openbmc_username@$openbmc_host"
  qprint_issuing
  eval $cmd_buf

  append bad_host_regex "ssh: Could not resolve hostname ${openbmc_host}:"
  append bad_host_regex " Name or service not known"
  set expect_result [expect_wrap\
    [list $bad_host_regex $ssh_password_prompt]\
    "an SOL password prompt" 5]

  if { $expect_result == 0 } {
    puts stderr ""
    print_error "Invalid openbmc_host value.\n"
    exit_proc 1
  }

  send_wrap "${openbmc_password}"

  append bad_user_pw_regex "Permission denied, please try again\."
  append bad_user_pw_regex "${cr_lf_regex}${ssh_password_prompt}"
  set expect_result [expect_wrap\
    [list $bad_user_pw_regex "sh: xauth: command not found"]\
    "an SOL prompt" 10]

  switch $expect_result {
    0 {
      puts stderr "" ; print_error "Invalid OpenBmc username or password.\n"
      exit_proc 1
    }
    1 {
      # Currently, this string always appears but that is not necessarily
      # guaranteed.
      dict set state ssh_logged_in 1
    }
  }

  if { [dict get $state ssh_logged_in] } {
    qprintn ; qprint_timen "Logged into SOL."
    dprintn ; dprint_dict state
    return
  }

  # If we didn't get a hit on the "sh: xauth: command not found", then we just
  # need to see a linefeed.
  set expect_result [expect_wrap [list ${cr_lf_regex}] "an SOL prompt" 5]

  dict set state ssh_logged_in 1
  qprintn ; qprint_timen "Logged into SOL."
  dprintn ; dprint_dict state

}


proc sol_logoff {} {

  # Logoff from the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host

  if { ! [dict get $state ssh_logged_in] } {
    qprintn ; qprint_timen "No SOL logoff required."
    return
  }

  send_wrap "~."

  set expect_result [expect_wrap\
    [list "Connection to $openbmc_host closed"]\
    "a connection closed message" 5]

  dict set state ssh_logged_in 0
  qprintn ; qprint_timen "Logged off SOL."
  dprintn ; dprint_dict state

}


proc get_post_ssh_login_state {} {

  # Get the initial state following sol_login.

  # The following state global dictionary variable is set by this procedure.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_login_prompt_regex
  global os_prompt_regex
  global petitboot_screen_regex

  if { ! [dict get $state ssh_logged_in] } {
    puts stderr ""
    append message "Programmer error - [get_stack_proc_name] must only be"
    append message " called after sol_login has been called."
    print_error_report $message
    exit_proc 1
  }
  
  # The first thing one must do after signing into ssh -p 2200 is hit enter to
  # see where things stand.
  send_wrap ""
  set expect_result [expect_wrap\
    [list $os_login_prompt_regex $os_prompt_regex $petitboot_screen_regex]\
    "any indication of status" 5]

  switch $expect_result {
    0 {
      dict set state os_login_prompt 1
    }
    1 {
      dict set state os_logged_in 1
    }
    2 {
      dict set state petitboot_screen 1
    }
  }

  dprintn ; dprint_dict state

}


proc os_login {} {

  # Login to the OS

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global openbmc_host os_username os_password
  global os_password_prompt
  global os_prompt_regex

  if { [dict get $state os_logged_in] } {
    printn ; print_timen "We are already logged in to the OS."
    return
  }

  send_wrap "${os_username}"

  append bad_host_regex "ssh: Could not resolve hostname ${openbmc_host}:"
  append bad_host_regex " Name or service not known"
  set expect_result [expect_wrap\
    [list $os_password_prompt]\
    "an OS password prompt" 5]

  send_wrap "${os_password}"
  set expect_result [expect_wrap\
    [list "Login incorrect" "$os_prompt_regex"]\
    "an OS prompt" 10]
  switch $expect_result {
    0 {
      puts stderr "" ; print_error "Invalid OS username or password.\n"
      exit_proc 1
    }
  }

  dict set state os_logged_in 1
  dict set state os_login_prompt 0
  qprintn ; qprint_timen "Logged into OS."
  dprintn ; dprint_dict state

}


proc os_logoff {} {

  # Logoff from the SOL console.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_login_prompt_regex

  if { ! [dict get $state os_logged_in] } {
    qprintn ; qprint_timen "No OS logoff required."
    return
  }

  send_wrap "exit"
  set expect_result [expect_wrap\
    [list $os_login_prompt_regex]\
    "an OS prompt" 5]

  dict set state os_logged_in 0
  qprintn ; qprint_timen "Logged off OS."
  dprintn ; dprint_dict state

}


proc os_command {command_string { quiet {} } { test_mode {} } \
  { show_err {} } { ignore_err {} } {trim_cr_lf 1}} {

  # Execute the command_string on the OS command line and return a list
  # consisting of 1) the return code of the command 2) the stdout/
  # stderr.

  # It is the caller's responsibility to make sure we are logged into the OS.

  # Description of argument(s):
  # command_string  The command string which is to be run on the OS (e.g.
  #                 "hostname" or "grep this that").
  # quiet           Indicates whether this procedure should run the
  #                 print_issuing() procedure which prints "Issuing:
  #                 <cmd string>" to stdout. The default value is 0.
  # test_mode       If test_mode is set, this procedure will not actually run
  #                 the command.  If print_output is set, it will print
  #                 "(test_mode) Issuing: <cmd string>" to stdout.  The default
  #                 value is 0.
  # show_err        If show_err is set, this procedure will print a
  #                 standardized error report if the shell command returns non-
  #                 zero.  The default value is 1.
  # ignore_err      If ignore_err is set, this procedure will not fail if the
  #                 shell command fails.  However, if ignore_err is not set,
  #                 this procedure will exit 1 if the shell command fails.  The
  #                 default value is 1.
  # trim_cr_lf      Trim any trailing carriage return or line feed from the
  #                 result.

  # Set defaults (this section allows users to pass blank values for certain
  # args)
  set_var_default quiet [get_stack_var quiet 0 2]
  set_var_default test_mode 0
  set_var_default show_err 1
  set_var_default ignore_err 0
  set_var_default acceptable_shell_rcs 0

  global spawn_id
  global expect_out
  global os_prompt_regex

  qprintn ; qprint_issuing ${command_string} ${test_mode}

  if { $test_mode } {
    return [list 0 ""]
  }

  send_wrap "${command_string}"

  set expect_result [expect_wrap\
    [list "-ex $command_string"]\
    "the echoed command" 5]
  set expect_result [expect_wrap\
    [list {[\n\r]{1,2}}]\
    "one or two line feeds" 5]
  # Note the non-greedy specification in the regex below (the "?").
  set expect_result [expect_wrap\
    [list "(.*?)$os_prompt_regex"]\
    "command output plus prompt" -1]

  # The command's stdout/stderr should be captured as match #1.
  set out_buf $expect_out(1,string)

  if { $trim_cr_lf } {
    set out_buf [ string trimright $out_buf "\r\n" ]
  }

  # Get rc via recursive call to this function.
  set rc 0
  set proc_name [get_stack_proc_name]
  set calling_proc_name [get_stack_proc_name -2]
  if { $calling_proc_name != $proc_name } {
    set sub_result [os_command {echo ${?}} 1]
    dprintn ; dprint_list sub_result
    set rc [lindex $sub_result 1]
  }

  if { $rc != 0 } {
    if { $show_err } {
      puts stderr "" ; print_error_report "The prior OS command failed.\n"
    }
    if { ! $ignore_err } {
      if { [info procs "exit_proc"] != "" } {
        exit_proc 1
      }
    }
  }

  return [list $rc $out_buf]

}


proc boot_to_petitboot {} {

  # Boot the machine until the petitboot screen is reached.

  dprintn ; dprint_executing

  global spawn_id
  global expect_out
  global state
  global os_prompt_regex
  global petitboot_screen_regex

  if { [dict get $state petitboot_screen] } {
    qprintn ; qprint_timen "We are already at petiboot."
    return
  }

  if { [dict get $state os_login_prompt] } {
    set cmd_buf os_login
    qprintn ; qprint_issuing
    eval ${cmd_buf}
  }

  # Turn off autoboot.
  set cmd_result [os_command "nvram --update-config auto-boot?=false"]
  set cmd_result [os_command\
    "nvram --print-config | egrep 'auto\\-boot\\?=false'"]

  # Reboot and wait for petitboot.
  send_wrap "reboot"

  # Once we've started a reboot, we are no longer logged into OS.
  dict set state os_logged_in 0
  dict set state os_login_prompt 0

  set expect_result [expect_wrap\
    [list $petitboot_screen_regex]\
    "the petitboot screen" 900]
  set expect_result [expect_wrap\
    [list "Exit to shell"]\
    "the 'Exit to shell' screen" 10]
  dict set state petitboot_screen 1

  qprintn ; qprint_timen "Arrived at petitboot screen."
  dprintn ; dprint_dict state

}


# Main

  gen_get_options $argv

  validate_parms

  qprint_pgm_header

  # Global variables for current prompts of the SOL console.
  set ssh_password_prompt ".* password: "
  set os_login_prompt_regex "login: "
  set os_password_prompt "Password: "
  set petitboot_screen_regex "Petitboot"
  set cr_lf_regex "\[\n\r\]"
  set os_prompt_regex "(\\\[${os_username}@\[^ \]+ ~\\\]# )"

  dprintn ; dprint_dict state

  set cmd_buf sol_login
  qprint_issuing
  eval ${cmd_buf}

  set cmd_buf get_post_ssh_login_state
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  set cmd_buf ${proc_name}
  qprintn ; qprint_issuing
  eval ${cmd_buf}

  exit_proc
