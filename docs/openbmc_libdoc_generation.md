## Documentaion of libdoc generation ##


## Usage of command ##

```
python -m robot.libdoc [options] library_or_resource output_file
python -m robot.libdoc [options] library_or_resource list|show|version [names]
```

Example:
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
Example:
```
python -m robot.libdoc path/filename.robot list
python -m robot.libdoc filenamr.robot version
python -m robot.libdoc filenamr.robot show intro
```

## Arguments to pass in python code ##
```
python libdoc_gen.py sourcefilepath destinationfilepath
```

## Reference ##

Refer to latest Robot Framework documention [Robot Framework Doc](https://robotframework.org/robotframework/)
Under Built-in tools
click on Libdoc "View"