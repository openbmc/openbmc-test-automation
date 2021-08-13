### Plugin

Plugin feature for the log collector is to load a user python functions at runtime by the engine and execute it.

The design infrastructure allows user to extend or call their existing python scripts without needing to expose
the implementation.  This enriches the log collection and mechanize the work flow as per user driven as per
their requirement,

### Understanding Plugin
The plugin works like any stand-alone piece of python script or library function.

The main components in plugin infrastructure are:

- plugin directory
- plugin directive in YAML
- plugin parser in the collector engine

### Plugin Directory
Python module script are added or copied to `plugins` directory and the log engine loads these plugins during
runtime and on demand from the YAML else they are not invoked automatically.

Example:
```
plugins/
├── foo_func.py
├── ssh_execution.py
└── telnet_execution.py

```

### Plugin Template Example

Stand-alone functions: plugins/foo_func.py
```
# Sample for documentation plugin

def print_vars(var):
    print(var)

def return_vars():
    return 1
```

Class function(s): plugins/plugin_class.py

Example:
```
class  plugin_class:

    def plugin_print_msg(msg):
        print(msg)
```

In YAML plugin, you will need to pass self object as part of the arguments.

Static Class function(s): plugins/plugin_class.py

Example:
```
class  plugin_class:

    @staticmethod
    def plugin_print_msg(msg):
        print(msg)
```

This is to avoid passing object self in plugin args YAML when calling the class function(s).
However python class static method has its own limitation, do not use unless needed.


You can add your own plugin modules to extend further.

Test your plugin:
```
python3 plugins/foo_func.py
```

### YAML Syntax

Plugin function without return statement.
```
    - plugin:
        - plugin_name: plugin.foo_func.print_vars
        - plugin_args:
            - "Hello plugin"
```

Plugin function with return statement.
```
    - plugin:
        - plugin_name: return_value = plugin.foo_func.return_vars
        - plugin_args:
```

when the return directive is used by implying "=" , the `return_value`
can be accessed within the same block by another following plugins
by using the variable name directly.

Example:
```
    - plugin:
        - plugin_name: plugin.foo_func.print_vars
        - plugin_args:
            - return_value
```

To accept multiple return values by using coma  "," separated statement
```
     - plugin_name:  return_value1,return_value2 = plugin.foo_func.print_vars
```

Accessing a class method:

The rule remains same as other functions, however for a class object plugin syntax

```
        - plugin_name: plugin.<file_name>.<class_object>.<class_method>
```

Example: (from the class example previously mentioned)
```
    - plugin:
        - plugin_name: plugin.plugin_class.plugin_class.plugin_print_msg
        - plugin_args:
            - self
            - "Hello Plugin call"
```

### Plugin execution output for sample


```
        [PLUGIN-START]
        Call func: plugin.foo_func.print_vars("Hello plugin")
        Hello plugin
        return: None
        [PLUGIN-END]

        [PLUGIN-START]
        Call func: plugin.foo_func.return_vars()
        return: 1
        [PLUGIN-END]
```

### Plugin FILES Direcive

Rules:

If in the YAML with Plugin module called and corresponding file order

plugin response if there is any will be written to named file, if

```
    FILES:
        -'name_file.txt'
```

Else, plugin response will be skipped and not written to any file.
```
    FILES:
        - None
```

### Plugin ERROR Direcive

Error directive on plugin supported
- exit_on_error       : If there was an error in a plugin stacked, the subsequent
                        plugin would not be executed if this is declared.
- continue_on_error   : If there was an error and user declare this directive,
                        then the plugin block will continue to execute.

Example:
```
    - plugin:
        - plugin_name: plugin.foo_func.print_vars
        - plugin_args:
            - return_value
        - plugin_error: exit_on_error
```

This error directive would come into force only if there is an error detected
by the plugin during execution and not the error response returned from the plugin
function in general.

To go further, there is another directive for plugin to check if the plugin function
returned a valid data or not.

The directive statement is
```
    - plugin_expects_return: <data type>
```

Example:
```
    - plugin:
    - plugin:
      - plugin_name: plugin.ssh_execution.ssh_execute_cmd
      - plugin_args:
        - ${hostname}
        - ${username}
        - ${password}
        - cat /etc/os-release
        - 3
      - plugin_expects_return: str
```

The above example states that, the plugin function is expecting a return data of type
string. If the plugin function does not return data or the returned data is not of type
string, then it would throw an error and sets the plugin_error flag exit_on_error as True.

This directive helps in validating plugin return data to handle different plugin blocks
stacked together which are depending on the success of the previous plugin execution to do
further processing correctly.
