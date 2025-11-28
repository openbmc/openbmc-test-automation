# check_robot_tags.awk
# Author: Generic Ratslaugh
#
# For robot framework test suite files:
# check to see if the test case/task and the tag correspond.
# When the two are not equivalent, the script prints the filename,
# the test name, and the tag.
# 
# Consider the following 7-line file named hello_world.robot:
## *** Settings ***
## Documentation     A hello world
##
## *** Test Cases ***
## Hello World Test Case
##     [Tags]  Hello_World_Tests_Case
##     Log To Console            Hello Robot World!
#
# Run the awk script on the robot file as follows:
## $ awk -f check_robot_tags.awk hello_world.robot 
#
## The output of the above run will be as follows:
##  --- hello_world.robot:
## Hello World Test Case
## Hello_World_Tests_Case
#
# Run it over all \*.robot test suite files in the current directory tree as follows:
## $ find | grep '\.robot$' | xargs awk -f check_robot_tags.awk


BEGIN {
  in_tests = 0  # in test or task section
  new_test = 0  # in testcase declaration, but before tag processed
}

{
  if (index($0, "*") == 1) {
    # Sections header must start with one asterisk; words are case insensitive
    if (index(tolower($0), "test case") > 0) {
      #print "Test Cases found"
      in_tests = 1
    }
    if (index(tolower($0), "task") > 0) {
      #print "Tasks found"
      in_tests = 1
    }
    if (index(tolower($0), "keyword") > 0) {
      #print "Keywords found"
      in_tests = 0
    }
  } else if (in_tests == 1) {
    if ((length($1) > 0) && (index($0, $1) == 1)) {
      new_test = 1
      test_name = $0
      #print "New test: " test_name
    }
    if (new_test == 1) {
      if (index($0, " ") == 1) {
        if ($1 == "[Tags]") {
          tag = $2
          new_test = 0
          # compare test_name and tag:
          mod_test_name = test_name
          gsub(/ /, "_", mod_test_name)
          if (mod_test_name != tag) {
            print " --- " FILENAME ":"
            print test_name
            print tag
            print " "
          }
        }
      }
    }
  }
}

END {
}
