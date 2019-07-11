## Documentaion of libdoc generation ##


## Usage of command ##

```
    python -m robot.libdoc [options] library_or_resource output_file
    python -m robot.libdoc [options] library_or_resource list|show|version [names]
```

_Example:_
```
    python -m robot.libdoc path/filename.py path/filename.html
    python -m robot.libdoc -f html -F robot path/filename.robot path/filename.html
```



## Alternate way to generate libdoc ##

Alternate way to generate libdoc by using script as mention below.
```
    python path/robot/libdoc.py [options] arguments
```

## Viewing information on console ##
_Example:_
```
    python -m robot.libdoc path/filename.robot list
    python -m robot.libdoc filenamr.robot version
    python -m robot.libdoc filenamr.robot show intro
```

## python Code ##

```

#Import Modules

import os
import platform
import subprocess
import sys


# Global Constant

python= "python "
file_name="libdoc.py"


def locate_libdoc():
    """
    Function Description  : Run a command using subprocess and
                            return output
    Arguments             : No arguments
    Return Value          : Return command output
    """

    process = subprocess.Popen('locate libdoc.py', stdout=subprocess.PIPE, shell=True)
    output = process.communicate()[0].decode('utf-8')
    return output


def get_python_version():
    """
    Function Description  : Get current version of python
    Arguments             : No arguments
    Return Value          : Return current python version
    """

    python_version = platform.python_version()
    python_version = '.'.join(python_version.split('.')[0:2])
    return python_version


def generate_libdoc(*args):
    """
    Function Description  : Generate the keyword documentation for
                            test libraries and resource files
    Arguments             : source_filename,
                            destination_filename
    Return Value          : Return no value
    """

    source_filename = args[0][0]
    destination_filename = args[0][1]
    libdoc_path = locate_libdoc()
    get_py_ver = get_python_version()
    for item in libdoc_path.split('\n'):
        if  get_py_ver in item and file_name in item:
            gen_cmd = python + item + " " + source_filename + " "  + destination_filename
            os.system(gen_cmd)


if __name__ == "__main__":

    params = sys.argv[1:]
    generate_libdoc(params)

        
```
## Arguments to pass in python code ##
```
python filename.py sourcefilepath destinationfilepath
```

## Reference ##

Refer to latest Robot Framework documention [Robot Framework Doc](https://robotframework.org/robotframework/)
Under Built-in tools
click on Libdoc "View"