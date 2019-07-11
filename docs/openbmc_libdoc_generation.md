## Generate robot keyword documentation  ##
This documents helps to generate the keyword documentation for libraries and resource file.

## Command for help section ##
```
python generate_repo_libdoc.py -h
```
## Usage of arguments ##

Below arguments required to generate keyword documentation.
* positional arguments are mandatory arguments.
* optional arguments must be passed with listed value, as mention in below section.

```
positional arguments:
  source                Path of source file
  destination           Path to generate the keyword documentation

optional arguments:
  -h, --help            show this help message and exit
  -f {HTML,XML,html,xml}, --format {HTML,XML,html,xml}
                        Set generated output file extension HTML | XML
                        (default: )
  -F {ROBOT,HTML,TEXT,REST,robot,html,text,rest}, --docformat {ROBOT,HTML,TEXT,REST,robot,html,text,rest}
                        Mention source file format ROBOT | HTML | TEXT | REST
                        (default: )
```
## Usage of command ##
```
$cd tools/

python generate_repo_libdoc.py /path/sourcefilename.robot /path/destinationfilename.html

python generate_repo_libdoc.py -f HTML -F robot /path/sourcefilename.robot /path/destinationfilename.html
```

## Reference ##

* Refer to latest Robot Framework documention 
  https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#libdoc
