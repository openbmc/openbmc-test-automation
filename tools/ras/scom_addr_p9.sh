#!/bin/bash
# Refer to help text in the usage function for details.

function usage()
{
        echo
        echo "This script runs on HOST OS and gives translated SCOM address."
        echo "usage: $0: <scom_addr> <core_id>"
        echo
        echo "  <scom_addr>:"
        echo "     SCOM address that needs translation (e.g. '10010800')."
        echo "  <core_id>:"
        echo "     Core id as obtained from probe_cpu.sh."
        echo "     Should be between 0-23 (e.g. '0')."
        exit 1
}

[ $# -lt 2 ] && usage

SCOM_ADDR=$1
SCOM_ADDR=$(echo $SCOM_ADDR | sed 's/^0x//')
CORE_ID=$2
CORE_ID=$(echo $CORE_ID | sed 's/^0x//')

[ $CORE_ID -gt 23 ] && echo "<core-id> should be between 0-23" && exit

# per Chip level
perl -e '{printf("EQ[%2d]: 0x%x\n", ((('$CORE_ID' & 0x1c)) >> 2), 0x'$SCOM_ADDR' | ((('$CORE_ID' & 0x1c) + 0x40) << 22));}'
perl -e '{printf("EX[%2d]: 0x%x\n", ((('$CORE_ID')) >> 1), (0x'$SCOM_ADDR' | (('$CORE_ID' & 2) << 9 )) | ((('$CORE_ID' & 0x1c) + 0x40) << 22));}'
perl -e '{printf(" C[%2d]: 0x%x\n", '$CORE_ID', 0x'$SCOM_ADDR' | ((('$CORE_ID' & 0x1f) + 0x20) << 24));}'


