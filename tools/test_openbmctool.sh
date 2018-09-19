#!/bin/bash

# Test functionality of openbmctool


HOST=$1   # BMC network name or IPAddress
USER=$2   # Userid to login to the BMC with
PWD=$3    # Password for USER
# Note to self: Also add parameter of which test(s) to run.


# This command is used in all tests.
TOOL_CMD="python openbmctool.py -H $HOST -U $USER -P $PWD"

# Constants.
PASS="...  PASS"
FAIL="...  ====== FAIL ====="


## fru tests.

# fru status.
test_fru_status()
{
    echo "Running $1"
    NUM_LINES=`$TOOL_CMD fru status  |  wc -l`
    # There should be at least 30 sensors reporting.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi
}

# fru print.
test_fru_print()
{
    echo "Running $1"
    # check "fru print"
    NUM_LINES=`$TOOL_CMD fru print  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi
}

# fru list.
test_fru_list()
{
    # Currently, fru list returns identical results as fru print.
    echo "Running $1"
    NUM_LINES=`$TOOL_CMD fru list  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi
}

# fru list of a single fru.
test_fru_list_with_fru()
{
    echo "Running $1"
    # Get the name of one fru, in this case the first fan listed.
    FRU=`$TOOL_CMD  fru status  | grep fan | head -1 | cut -c1-5`
    if  [[ ! -z $FRU ]] ; then
      # FRU is not null.  Do fru list specifying the fru.
      NUM_LINES=`$TOOL_CMD fru list $FRU  | grep xyz | wc -l`
      # Should be just a few lines describing the fru.
      if  (( $NUM_LINES > 30 )) || (( $NUM_LINES < 3 )) ;  then
        echo  $FAIL
      else
        echo  $PASS
      fi
    else
      # No fru.
      echo $FAIL
    fi
}



## sensors tests.

# sensors print.
test_sensors_print()
{
    echo "Running $1"
    NUM_LINES=`$TOOL_CMD sensors print | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi
}

# sensors list.
test_sensors_list()
{
    echo "Running $1"
    NUM_LINES=`$TOOL_CMD sensors list | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi
}


# sensors list of a single sensor.
test_sensors_list_with_sensor()
{
    echo "Running $1"
    SENSOR="ambient"
    NUM_LINES=`$TOOL_CMD sensors list $SENSOR  | wc -l`
    # Should be just a few lines describing the item.
    if  (( $NUM_LINES > 20 )) || (( $NUM_LINES < 3 )) ;  then
       echo  $FAIL
    else
       echo $PASS
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

# note to self:
# add:
#  Check that python is version 3 (required by openbmctool.py).
#  Check that openbmctool is in PATH.
#  Add parameters for BMC, USER, PW  and which test(s) to run.

Test_List="test_fru_status \
           test_fru_print \
           test_fru_list \
           test_fru_list_with_fru \
           test_sensors_list \
           test_sensors_print \
           test_sensors_list_with_sensor"
#Test_List="test_sensors_list"


ping -w 5 $HOST 1>/dev/null 2>&1
if (( $? != 0 )) ;  then
    echo Exiting.  Cannot contact host $HOST.
    exit 2
fi

echo Test_List=$Test_List
echo

counter=0
for Testcase in $Test_List ; do
(( counter = counter + 1))
echo "$counter  Running $Testcase"
$Testcase $Testcase
done
