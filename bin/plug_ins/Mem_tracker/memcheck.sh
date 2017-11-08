#!/bin/bash

# This program will calculate memory usage for each process and generate a
# comma-separated value (CSV) output file named output.csv in the current
# directory.  The output will consist of 2 lines.  The first is a comma-
# separated list of process names.  The second is a list of comma-separated
# memory usage values (expressed in bytes). Here is an abbrieviated example of
# the output:
# python(9),/lib/systemd/systemd-journald,/usr/bin/python,/sbin/init,
# phosphor-hwmon-readd(4),ipmid,phosphor-ledcontroller(4)
# 57896960,11789312,4434944,2893824,1900544,1764352

program_name=${0##*/}
temp_file_path_1=/tmp/${program_name}_results_1
temp_file_path_2=/tmp/${program_name}_results_2
temp_file_path_3=/tmp/${program_name}_results_3

temp_file_list="${temp_file_path_1} ${temp_file_path_2} ${temp_file_path_3}"
csv_file_path="output.csv"

# Description of argument(s):
# pid  The pid for which you desire statistics. If this is not specified,
# statistics will be gathered for all active pids.

function get_parms {

  # Get program parms.

  pids="${1:-$(ls /proc | grep -v [A-Za-z])}" ; shift

  return 0

}


function exit_function {

  # Used to clean up tmp files.

  rm -f ${temp_file_list}
  return

}


function validate_parms {

  # Validate program parameters.

  # Making sure only root can run our script.
  if [ "${USER}" != "root" ] ; then
    echo "This script must be run as root" 1>&2
    return 1
  fi

  trap "exit_function $signal \$?" EXIT
  return 0

}


function get_process_mem {

  local pid="${1}" ; shift
  # Count memory statistic for passed pid.

  # Description of argument(s):
  # pid  The process ID for which you desire statistics.
  [ ! -f /proc/${pid}/status -o ! -f /proc/${pid}/smaps ] && return 0

  # pss_total      Total proportional set size of a process.
  # private_total  Total number of clean and dirty private pages in the
  #                mapping.
  # shared_total   The difference between pss_total and private_total.

  local pss_total private_total shared_total sum name
  pss_total=$(grep -e "^Pss:" /proc/${pid}/smaps | awk '{print $2}' | awk '{sum += $1} END {print sum}')
  private_total=$(grep -e "^Private" /proc/${pid}/smaps | awk '{print $2}' | awk '{sum += $1} END {print sum}')

  [ -z "${pss_total}" -o -z "${private_total}" ] && return 0
  (( shared_total=pss_total-private_total ))
  name=$(cut -d "" -f 1 /proc/${pid}/cmdline)
  (( sum=shared_total+private_total ))
  echo -e "${private_total} + ${shared_total} = ${sum} ${name}"

}


function mainf {

  get_parms "$@" || return 1

  validate_parms || return 1

  # To ensure temp files not exist.
  rm -f ${temp_file_list}

  for pid in ${pids} ; do
    get_process_mem ${pid} >> ${temp_file_path_1}
  done

  # This is used to sort results by memory usage.
  sort -gr -k 5 ${temp_file_path_1} > ${temp_file_path_2}

  # Find duplicates in the process list output and combine them.  In such
  # cases, adjust the process name by including a (<count>) suffix.  In the
  # following example of output, 4 instances of "phosphor-hwmon-readd" have
  # been combined.
  # 974848 + 925696 = 1900544       phosphor-hwmon-readd(4)
  for proc_name in $(awk '{print $6}' ${temp_file_path_2} | sort -u) ; do
    count=$(awk -v src=${proc_name} '{if ($6==src) {print $6}}' ${temp_file_path_2} | wc -l)
    [ "${count}" = "1" ] && count_string="" || count_string="(${count})"
    vmsize_in_kb=$(awk -v src=${proc_name} '{if ($6==src) {print $1}}' ${temp_file_path_2} | awk '{sum += $1} END {print sum}')
    vmrss_in_kb=$(awk -v src=${proc_name} '{if ($6==src) {print $3}}' ${temp_file_path_2} | awk '{sum += $1} END {print sum}')
    total=$(awk '{print $5}' ${temp_file_path_2} | awk '{sum += $1} END {print sum}')
    (( sum=vmrss_in_kb+vmsize_in_kb ))
    echo -e "${vmsize_in_kb}  + ${vmrss_in_kb} = ${sum} \t ${proc_name}${count_string}" >> ${temp_file_path_3}
  done

  # Sort once more.
  sort -gr -k 5 ${temp_file_path_3} > ${temp_file_path_1}

  # Read results from temp file and convert it to csv.
  csv_line1=""
  csv_line2=""
  while read line ; do
    while read private plus_operator shared equal_sign sum name ; do
      (( sum == 0 )) && continue
      csv_line1+=",${name}"
      csv_line2+=",${sum}"
    done<<<${line}
  done < ${temp_file_path_1}

  # Strip leading commas.
  csv_line1="${csv_line1#,}"
  csv_line2="${csv_line2#,}"
  { echo "${csv_line1}" ; echo "${csv_line2}" ; } >> ${csv_file_path}

  return 0

}

# Main

  mainf "${@}"
  rc="${?}"
  exit "${rc}"


