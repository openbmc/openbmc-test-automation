#!/usr/bin/python

# Contains variables used by the systest python code


# Inventory: success return code
FILES_MATCH = 0

# Inventory: Failure return codes
FILES_DO_NOT_MATCH = 2
INPUT_FILE_DOES_NOT_EXIST = 3
IO_EXCEPTION_READING_FILE = 4
IO_EXCEPTION_WRITING_FILE = 5


# Inventory: hardware categories which are reported in the JSON inventory files
hardware_categories = ['\"processor\":', '\"memory\":', '\"disk\":',
                       '\"I/O\":', '\"display\":', '\"generic\":',
                       '\"network\":', '\"communication\":', '\"printer\":',
                       '\"input\":', '\"multimedia\":', '\"tape\":']


# Inventory: Dictionary which defines what inventory items to ignore if there
# are differences in inventory files -- some differences are expected or
# immaterial.
# Add items to this dictionary if there are inventory items that should be
# ignored whenever a comparison between inventory files is done.
# For example, assigned processor speed routinely varies depending upon the
# needs of OCC/tmgt/ondemand governor.   Back-to-back inventory runs will show
# processor speed differences, even if nothing else was run between them.
#
# Each dictionary entry is of the form
# category:leafname
# where category is a JSON hardware category such as processor, memory,
# disk, I/O, display, generic, network, etc.
# and leafname is a leaf node (atribute value) within that category.
# For example   'processor':'size'
# So if the size field (that is, processor speed) is different
# between two inventory runs, and there are no other differences,
# the inventory files will be considered as matching.
JFILE_SKIP_DICTIONARY = {'processor':'size'}
