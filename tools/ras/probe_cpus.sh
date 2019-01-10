#!/bin/bash
# Refer to help text in the usage function for details.

CPU_SYS_DIR=/sys/devices/system/cpu/
NR_CPUS=0
CPU=
SHOW_LAYOUT=0


function usage()
{
        echo "This script runs on HOST OS and gives core-id"
        echo "corresponding to the chip-id."
        echo "usage:"
        echo "        $0 [cpu] [-L]"
        echo
        echo "option:"
        echo "        [cpu]"
        echo "          Logical cpu id."
        echo "        -L"
        echo "          Show processor layout."
        echo "        -h"
        echo "          Show this help."
        exit 1
}

function parse_args()
{
        while getopts "hL" OPTION
        do
        case $OPTION in
                L)
                        SHOW_LAYOUT=1
                        ;;
                *)
                        usage
                        exit 1
                        ;;
        esac
        done

        CPU=${!OPTIND}
}

parse_args $*

[ "$1" == "-h" ] && usage

declare -a CPUS
declare -a CPU_FILE
declare -a CPU_PIR
declare -a CORE_ID
declare -a CHIP_ID

declare -a CHIP_EQ
declare -a CHIP_EX
declare -a CHIP_CORES

declare -A CORE_MATRIX

for cpu_file in $(find $CPU_SYS_DIR -name "cpu[0-9]*")
do
        cpu=$(basename $cpu_file | tr -dc '0-9')
        [ -n "$cpu" ] && NR_CPUS=$(expr $NR_CPUS + 1)

        CPU_VALID[$cpu]=0
        [ -n "$CPU" ] && [ $cpu != $CPU ] && continue
        [ ! -e $cpu_file/pir ] && continue

        CPU_VALID[$cpu]=1

        CPU_FILE[$cpu]=$cpu_file
        pir=$(cat $cpu_file/pir)
        CPU_PIR[$cpu]=$pir
        CORE_ID[$cpu]=$(perl -e '{ printf("%d", (0x'$pir' >> 2) & 0x3f); }')
        CHIP_ID[$cpu]=$(perl -e '{ printf("%x", (0x'$pir' >> 8) & 0x7f); }')
done

i=0
chip_id=-1
core_id=-1
prev_eq_id=-1
prev_ex_id=-1
num_threads=0
CPU_LIST=" "
while [ $i -lt $NR_CPUS ]
do
        [ ${CPU_VALID[$i]} -eq 0 ] && i=$(expr $i + 1) && continue

        [ "$chip_id" != "${CHIP_ID[$i]}" ] && core_id=-1 && prev_eq_id=-1 && prev_ex_id=-1
        chip_id=${CHIP_ID[$i]}
        if [ "$core_id" != ${CORE_ID[$i]} ]
        then
                if [ $num_threads -ne 0 ]; then
                        echo "THREADS: $num_threads CPUs: $CPU_LIST"
                        CPU_LIST=" "
                fi
                CPU_LIST="$CPU_LIST$i "
                echo -n "CHIP ID: ${CHIP_ID[$i]} "
                echo -n "CORE ID: ${CORE_ID[$i]} "
                CHIP_CORES[$chip_id]="${CHIP_CORES[$chip_id]},${CORE_ID[$i]}"
                CORE_MATRIX[$chip_id,${CORE_ID[$i]}]=1
                eq_id=$(perl -e '{ printf("%d", (('${CORE_ID[$i]}' & 0x1c) >> 2)); }')
                if [ $eq_id != $prev_eq_id ]
                then
                        CHIP_EQ[$chip_id]="${CHIP_EQ[$chip_id]},$eq_id"
                        prev_eq_id=$eq_id
                fi
                ex_id=$(perl -e '{ printf("%d", (('${CORE_ID[$i]}') >> 1)); }')
                if [ $ex_id != $prev_ex_id ]
                then
                        CHIP_EX[$chip_id]="${CHIP_EX[$chip_id]},$ex_id"
                        prev_ex_id=$ex_id
                fi
                num_threads=1
        else
                CPU_LIST="$CPU_LIST$i "
                num_threads=$(expr $num_threads + 1)
        fi
        core_id=${CORE_ID[$i]}

        i=$(expr $i + 1)
done
echo "THREADS: $num_threads CPUs: $CPU_LIST"

echo
echo "-----------------------------"
for chip_id in ${!CHIP_CORES[@]}
do
        echo "p[$chip_id]"
        CHIP_CORES[$chip_id]="$(echo ${CHIP_CORES[$chip_id]} | cut -c 2-)"
        CHIP_EQ[$chip_id]="$(echo ${CHIP_EQ[$chip_id]} | cut -c 2-)"
        CHIP_EX[$chip_id]="$(echo ${CHIP_EX[$chip_id]} | cut -c 2-)"
        echo "   eq[${CHIP_EQ[$chip_id]}]"
        echo "   ex[${CHIP_EX[$chip_id]}]"
        echo "    c[${CHIP_CORES[$chip_id]}]"
done
echo "-----------------------------"


[ $SHOW_LAYOUT -eq 0 ] && exit

# Print chip layout

function print_header()
{
        local _row_=$1

        for q in 0 2 4
        do
                quad=$(perl -e '{ printf("%02d", ('$q' + '$_row_')); }')
                echo -n "        +---EQ$quad----+ "
        done
        echo
}

function print_core_info()
{
        local _row_=$1
        local _cpos_=$2   # Core position

        for q in 0 2 4
        do
                quad=$(perl -e '{ printf("%02d", ('$q' + '$_row_')); }')
                core_id=$(perl -e '{ printf("%d", ('$_cpos_' + ('$quad' * 4))); }')
                core_id_str=$(perl -e '{ printf("%-2d", ('$_cpos_' + ('$quad' * 4))); }')
                ex=$(perl -e '{ printf("%-2d", ('$core_id' >> 1)); }')
                if [ -n "${CORE_MATRIX[$chip_id,$core_id]}" ]
                then
                        echo -n "        |EX-$ex   C$core_id_str|"
                else
                        echo -n "        |           |"
                fi
        done
        echo
        if [ $_cpos_ -eq 3 ]
        then
                echo "        +-----------+         +-----------+        +-----------+"
        else
                echo "        + - - - - - +        + - - - - - +        + - - - - - +"
        fi
}

echo
echo "----------Processor Layout-------------------"
for chip_id in ${!CHIP_CORES[@]}
do
        echo "p[$chip_id]"

        for row in 0 1
        do
                print_header $row
                for core_pos in 0 1 2 3
                do
                        print_core_info $row $core_pos
                done
                echo

        done
        echo

done
