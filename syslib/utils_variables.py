#!/usr/bin/python

# Contains variables used by the systest python code


# Success return code
I_FILES_MATCH = 0

# Failure return codes
I_FILES_DO_NOT_MATCH = 2
I_INPUT_FILE_DOES_NOT_EXIST = 3
I_IO_EXCEPTION_READING_FILE = 4
I_IO_EXCEPTION_WRITING_FILE = 5


# Dictionary which defines what lshw inventory items to ignore if there are differences
# in inventory runs.
# Add items to this dictionary if there are inventory items that shoulc be ignored
# whenever a comparison between lshw inventory files is done.
# For example, assigned processor speed routinely varies depending upon the needs of
# OCC/tmgt/ondemand govenor.   Back-to-back inventory runs will show processor
# speed differences, even if nothing else was run between them.
#
# Each dictionary item is of the form
# category:fieldname
# where category is a hardware subsystem name
# and fieldname is a leaf node (atribute)  within that category.
# For example   'cpu':'size'
# So if the size field (that is, processor speed) is different in the cpu
# category between two inventory runs, and there are no other differences,
# the inventory files will be considered as matching.
# Other entries you might have are  'pci':'resources'  or 'display':'vendor'
I_FILE_IGNORE_DICT = {'cpu': 'size'}
