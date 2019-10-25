#!/bin/bash

# Universal bash program setup functions.

# Example usage:

# Source files to get required functions.
# source_files="gen_setup.sh"
# source_file_paths=$(type -p ${source_files})
# for file_path in ${source_file_paths} ; do source ${file_path} ; done

# Turn on extended globbing.
shopt -s extglob


function get_pgm_path_info {
  local program_path_var="${1:-program_path}" ; shift
  local program_name_var="${1:-program_name}" ; shift
  local program_dir_path_var="${1:-program_dir_path}" ; shift
  local follow_links="${1:-0}" ; shift

  # Determine the program path, name and dir path and assign them to the variables indicated by the caller.

  # Description of argument(s):
  # program_path_var                The name of the variable to receive the program path.
  # program_name_var                The name of the variable to receive the program name.
  # program_dir_path_var            The name of the variable to receive the program dir path.
  # follow_links                    If the program running is actually a link to another file, use that file
  #                                 when calculating the above values.

  local _spn_loc_program_path_="${0}"

  # The program name is the program path minus all characters up to and including the first slash.
  local _spn_loc_program_name_=${_spn_loc_program_path_##*/}
  # The program dir path is the program path minus everything from the last slash to the end of the string.
  local _spn_loc_program_dir_path_=${_spn_loc_program_path_%${_spn_loc_program_name_}}

  # If program dir path does not start with a slash then it is relative.  Convert it to absolute.
  if [ "${_spn_loc_program_dir_path_:0:1}" != "/" ] ; then
    _spn_loc_program_dir_path_="$(readlink -f ${_spn_loc_program_dir_path_})/"
    # Re-assemble the parts into program path variable.
    _spn_loc_program_path_="${_spn_loc_program_dir_path_}${_spn_loc_program_name_}"
  fi

  if (( follow_links )) ; then
    _spn_loc_program_path_=$(readlink -f ${_spn_loc_program_path_})
    # Re-calculate program_name in case it is different now.
    _spn_loc_program_name_=${_spn_loc_program_path_##*/}
  fi

  # Set caller's variables.
  cmd_buf="${program_path_var}=\"\${_spn_loc_program_path_}\" ; ${program_name_var}=\"\${_spn_loc_program_name_}\" ; ${program_dir_path_var}=\"\${_spn_loc_program_dir_path_}\""
  eval "${cmd_buf}"

}
