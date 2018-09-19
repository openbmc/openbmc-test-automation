#!/bin/bash

# Test functionality of openbmctool.

HOST=$1   # BMC network name or IPAddress.
USER=$2   # Userid to login to the BMC with.
PWD=$3    # Password for USER.
TESTS=$4  # Name of test(s) to run. If omitted, all test
          # will be run.
# Example call:
# test_openbmctool.sh  mybmc.mydomain.com  adminuser passwd "test_fru_status test_sensors_list"


# This command is used in all tests.
TOOL_CMD="python openbmctool.py -H $HOST -U $USER -P $PWD"

# Variables
Num_failed=0
Num_passed=0

# Constants.
PASS="...  |PASS|"
FAIL="...  ====== |FAIL| ====="
All_tests="test_fru_status \
           test_fru_print \
           test_fru_list \
           test_fru_list_with_fru \
           test_sensors_list \
           test_sensors_print \
           test_sensors_list_with_sensor"

HOST=$1   # BMC network name or IPAddress.dd
USER=$2   # Userid to login to the BMC with.
PWD=$3    # Password for USER.
TESTS=$4  # Name of test(s) to run. If omitted, all test

# Utility subroutines.
usage()
{
echo "NAME"
echo "  test_openbmctool.sh -  test the functionality of openbmctool.py"
echo ""
echo "SYNOPSIS"
echo "   test_openbmctool.sh  Host UserID Pawssword [Name of test(s)]"
echo "     where"
echo "      host            is the netowrk name of IPAddress of a BMC."
echo "      userId          is the user-ID to login to the BMC with."
echo "      password        is the password for userID."
echo "      name of tests  Name of test(s) to run. If omitted, all tests "
echo "                      will be run."
echo "EXAMPLE"
echo " test_openbmctool.sh  mybmc.mydomain  myuser passwd \"test_fru_status test_sensors_list\""
echo ""
echo "TESTS AVAILABLE:"
echo " The list of available tests is:"
for Testcase in $All_tests ; do
echo "  $Testcase"
done
}


passed()
{
    (( Num_passed = Num_passed + 1 ))
    echo $PASS
}

failed()
{
    (( Num_failed = Num_failed + 1 ))
    echo $FAIL
}


## fru tests.

# fru status.
test_fru_status()
{
    NUM_LINES=`$TOOL_CMD fru status  |  wc -l`
    # There should be at least 30 sensors reporting.
    if  (( $NUM_LINES < 30 ));  then
       failed
    else 
       passed
    fi
}

# fru print.
test_fru_print()
{
    # check "fru print"
    NUM_LINES=`$TOOL_CMD fru print  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
       failed
    else
       passed
    fi
}

# fru list.
test_fru_list()
{
    # Currently, fru list returns identical results as fru print.
    NUM_LINES=`$TOOL_CMD fru list  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
       failed
    else
       passed
    fi
}

# fru list of a single fru.
test_fru_list_with_fru()
{
    # Get the name of one fru, in this case the first fan listed.
    FRU=`$TOOL_CMD  fru status  | grep fan | head -1 | cut -c1-5`
    if  [[ ! -z $FRU ]] ; then
      # FRU is not null.  Do fru list specifying the fru.
      NUM_LINES=`$TOOL_CMD fru list $FRU  | grep xyz | wc -l`
      # Should be just a few lines describing the fru.
      if  (( $NUM_LINES > 30 )) || (( $NUM_LINES < 3 )) ;  then
        failed
      else
        passed
      fi
    else
      # No fru.
      failed
    fi
}


## sensors tests.

# sensors print.
test_sensors_print()
{
    NUM_LINES=`$TOOL_CMD sensors print | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
       failed
    else
       passed
    fi
}

# sensors list.
test_sensors_list()
{
    NUM_LINES=`$TOOL_CMD sensors list | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
       failed
    else
       passed
    fi
}

# sensors list of a single sensor.
test_sensors_list_with_sensor()
{
    SENSOR="ambient"
    NUM_LINES=`$TOOL_CMD sensors list $SENSOR  | wc -l`
    # Should be just a few lines describing the item.
    if  (( $NUM_LINES > 20 )) || (( $NUM_LINES < 3 )) ;  then
       failed
    else
       passed
    fi
}

##--TODO---
## chassis tests
## sel tests
## collect service data  tests
## health check
## dump
## bmc (same as mc)
## gardclear
## firmware


############### the main program starts here ##############################

# Todo:
#  Check that python is version 3 (required by openbmctool.py).
#  Check that openbmctool is in PATH.

#All_tests="test_sensors_list"

if [[ -z $2 ]] ; then
  usage
  exit 2
fi

# Check that specified HOST is reachable.
ping -w 5 $HOST 1>/dev/null 2>&1
if (( $? != 0 )) ;  then
    echo Exiting.  Cannot contact host $HOST.
    exit 2
fi



# Set which test to run.
if [[ ! -z $TESTS ]] ; then
  Test_List=$TESTS
else
  Test_List=$All_tests
fi

echo HOST=$HOST
echo Test_List=$Test_List
echo

counter=0
for Testcase in $Test_List ; do
(( counter = counter + 1))
echo "$counter  Running $Testcase"
$Testcase $Testcase
done
echo  Out of $counter tests,  $Num_passed passed and $Num_failed failed.
