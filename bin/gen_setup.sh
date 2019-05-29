#!/bin/bash

# Universal bash program setup functions.

# Turn on extended globbing.
shopt -s extglob


function set_pgm_name {

  # Determine program path name, name, etc. and set the following global
  # values:
  # program_path
  # program_name
  # program_dir_path

  program_path="${0}"
  [ "${program_path#/}" == "${program_path}" ] && program_path=$(readlink -f ${program_path})
  program_name=${program_path##*\/}
  program_dir_path=${program_path%${program_name}}

}
