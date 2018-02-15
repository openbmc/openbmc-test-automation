#!/bin/bash
#\
exec wish "$0" -- ${1+"$@"}

source [exec bash -c "which source.tcl"]
my_source [list print.tcl opt.tcl]

longoptions test_mode:=0 quiet:=0
pos_parms


# Create help dictionary for call to gen_print_help.
set help_dict [dict create\
  ${program_name} [list "${program_name} will..."]\
]


proc help {} {

  gen_print_help

}


proc exit_proc { {ret_code 0} } {

  # Execute whenever the program ends normally or with the signals that we
  # catch (i.e. TERM, INT).

  dprint_executing
  dprint_var ret_code

  # Your code here.

  qprint_pgm_footer

  exit $ret_code

}


proc validate_parms {} {

  trap { exit_proc } [list SIGTERM SIGINT]

  # Your code here.

}


# Main

  gen_get_options $argv

  validate_parms

  qprint_pgm_header

  exit_proc
