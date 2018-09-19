#!/bin/bash

# Test functionality test of openbmctool


# These will be parameters 
HOST=9.5.180.47
USER=root
PWD=0penBmc
# Note to self: Add parameter of which test(s) to run.


# This command is used in all tests.
OTOOL="python openbmctool.py -H $HOST -U $USER -P $PWD"

# Constants.
PASS="...  PASS"
FAIL="...  ====== FAIL ====="




## fru tests

# fru status
test_fru_status()
{
    echo "Running $1"
    NUM_LINES=`$OTOOL fru status  |  wc -l`
    # There should be at least 30 sensors reporting.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi 
}

# fru print
test_fru_print()
{
    echo "Running $1"
    # check "fru print"
    NUM_LINES=`$OTOOL fru print  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi 
}

# fru list
test_fru_list()
{
    # Currently, fru list returns identical results as fru print.
    echo "Running $1"
    NUM_LINES=`$OTOOL fru list  | grep xyz | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi 
}

# fru list of a single fru
test_fru_list_with_fru()
{
    echo "Running $1"
    # Get the name of one fru, in this case the first fan listed.
    FRU=`$OTOOL  fru status  | grep fan | head -1 | cut -c1-5`
    if  [[ ! -z $FRU ]] ; then
      # FRU is not null.  Do fru list specifying the fru.
      NUM_LINES=`$OTOOL fru list $FRU  | grep xyz | wc -l`
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



## sensors tests

# sensors print
test_sensors_print()
{
    echo "Running $1"
    NUM_LINES=`$OTOOL sensors print | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi 
}

# sensors list
test_sensors_list()
{
    echo "Running $1"
    NUM_LINES=`$OTOOL sensors list | wc -l`
    # There should be approximately 100 FRU items reported.
    if  (( $NUM_LINES < 30 ));  then
        echo $FAIL
    else
       echo $PASS
    fi 
}


# sensors list of a single sensor
test_sensors_list_with_sensor()
{
    echo "Running $1"
    SENSOR="ambient"
    NUM_LINES=`$OTOOL sensors list $SENSOR  | wc -l`
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

echo Test_List=$Test_List
echo

for Testcase in $Test_List ; do
$Testcase $Testcase
done


