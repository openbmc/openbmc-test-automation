#!/bin/bash
#\
exec expect "$0" -- ${1+"$@"}

# This file contains utilities for working with Serial over Lan (SOL)
# Required Parameters:
#   openbmc_host                The BMC host name or IP address.
#   openbmc_password            The BMC password.
#   openbmc_username            The BMC user name.
#   os_host                     The OS host name or IP address.
#   os_username                 The OS Host user name.
#   os_password                 The OS Host password.
#   requested_proc              The procedure you want to run

# Example use case:
# tclsh sol_utils.tcl --os_host=ip --os_password=password --os_username=username
# --openbmc_host=ip --openbmc_password=password --openbmc_username=username
# --requested_proc=boot_until_petitboot

source [exec bash -c "which source.tcl"]
my_source [list print.tcl opt.tcl valid.tcl]

longoptions openbmc_host: openbmc_username: openbmc_password: os_host: \
os_username: os_password: \
requested_proc:=boot_until_petitboot test_mode:=0 quiet:=0
pos_parms


# Create help dictionary for call to gen_print_help.
set help_dict [dict create\
  ${program_name} [list "${program_name} will..."]\
  openbmc_host [list "The OpenBMC host name or IP address."]\
  openbmc_username [list "The OpenBMC username." "username"]\
  openbmc_password [list "The OpenBMC password." "password"]\
  os_host [list "The OS host name or IP address."]\
  os_username [list "The OS username." "username"]\
  os_password [list "The OS password." "password"]\
  requested_proc [list "The requested_proc you'd like to run."]\
]

proc help {} {

  gen_print_help

}


proc exit_proc { {ret_code 0} } {

  # Execute whenever the program ends normally or with the signals that we catch
  #  (i.e. TERM, INT).

  dprint_executing
  dprint_var ret_code

  # Your code here.

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
  valid_value requested_proc

}


################################################################################
proc handle_timeout { callers_timeout message } {

  # This function is a global timeout handler.

  # Force a match to print the output using the following command:
  set timeout 0
  expect -re .+
  if { [info exists expect_out(buffer) ] } {
    set returned_data $expect_out(buffer)
  } else {
    set returned_data ""
  }

  puts stderr ""
  print_error "Did not get ${message} after $callers_timeout seconds.\n"
  puts "The data returned by the spawned process is:\n$returned_data"
  exit 1

}
################################################################################



################################################################################
proc handle_eof { message } {

  # This function is a global end of file handler.

  # I use uplevel to be able to access expect_out(buffer).
  uplevel {
    print_error "Reached end of file before getting $message.\n"
    puts "The data returned by the spawned process is:\n$expect_out(buffer)"
    exit 1
  }

}
################################################################################
proc sol_login {openbmc_host openbmc_username openbmc_password os_username \
  os_password} {

  # Login to the SOL console.

  global spawn_id
  global pre_os
  global os_login
  global os_prompt

  set cmd_buf "spawn -nottycopy ssh -p 2200 $openbmc_username@$openbmc_host"
  print_issuing
  eval $cmd_buf
  set message "an SOL login prompt"

  expect {
   -re "ssh: Could not resolve hostname ${openbmc_host}: Name or service not \
        known" {
      print_error "Invalid openbmc_host value.\n"
      exit 1
    }
    -re $pre_os {
      send -- "$openbmc_password\n"
      sleep 3
      send -- "\n"
    }
    timeout {
      handle_timeout "$timeout" "$message"
    }
    eof {
      handle_eof "$message"
    }
  }

  # Login to BMC on port 2200, use SOL state to determined how to login
  set timeout 5
  expect {
    -re "Permission denied, please try again.\n" {
      print_error "Invalid username or password.\n"
      exit 1
    }
    -re $os_login {
      send -- "$os_username\n"
      expect -re "Password:"
      send -- "$os_password\n"
    }
    -re $os_prompt {
      print_timen "Logged into SOL."
    }
    timeout {
      handle_timeout "$timeout" "$message"
    }
    eof {
      handle_eof "$message"
    }
  }
}


proc get_sol_state {} {
  # Get and return the SOL console's state.
  # There are 4 possible states,
  # 1	Pre OS: The bmc login prompt.
  # 2   OS Login: The prompt to enter the os login information.
  # 3   OS Prompt: The prompt once login to SOL is successful.
  # 4	Pettiboot: The petitboot menu.


  global spawn_id
  global pre_os
  global os_login
  global os_prompt
  global petitboot
  set val -1

  send "\n"
  expect {
    -re $pre_os {
      set val 1
    }
    -re $os_login {
      set val 2
    }
    -re $os_prompt {
      set val 3
    }
    -re $petitboot {
      set val 4
    }
  }
  if {$val == -1} {
    sprint_error "SOL in unknown state"
  }
  return $val
}


proc sol_logoff {openbmc_host} {
  global spawn_id
  send -- "~.\n"
  expect -ex "Connection to $openbmc_host closed"
  print_timen "Logged off SOL."
}


proc boot_until_petitboot {openbmc_host openbmc_password openbmc_username \
  os_password os_username} {
  global spawn_id
  global petitboot

  # Login to SOL, turn of autoboot then boot until
  # petitboot.

  sol_login $openbmc_host $openbmc_password $openbmc_username $os_password \
  $os_username
  set state [get_sol_state]
  send -- "nvram --update-config auto-boot?=false\n"
  expect -re "]#"
  send "nvram --print-config\n"
  expect -re "auto-boot?=false"

  # Reboot the system.
  send "reboot\n"
  set timeout -1
  expect $petitboot
  expect -re "Exit to shell"
  return
}


# Main

# Global variables for current prompts of the SOL console
global [set pre_os ".* password:"]
global [set os_login "login:"]
global [set os_prompt "~\]#"]
global [set petitboot "Petitboot"]

gen_get_options $argv

validate_parms
qprint_pgm_header

switch $requested_proc {
  "sol_login" -
  "boot_until_petitboot" {
    $requested_proc $openbmc_host $openbmc_username $openbmc_password \
    $os_username $os_password
  }
  "install_os" {
    set os_script_location [lindex $argv 6]
    $requested_proc $openbmc_host $openbmc_password $openbmc_username $os_host \
    $os_password $os_username $os_script_location
  }
  default {
    send "no match for procedure $requested_proc\n"
  }
 }

exit_proc
