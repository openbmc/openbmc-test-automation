### Plugin

Plugin feature for the log collector is to load a user python functions at runtime by the engine and execute it.

The design infrastructure allows user to extend or call their existing python scripts without needing to expose
the implementation.  This enriches the log collection and mechanize the work flow as per user driven as per
their requirement,

### Understanding Plugin
The plugin works like any stand-alone piece of python script or library function.  There are two main components
in plugin infrastructure such as

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

plugins/foo_func.py
```
# Sample for documentation plugin

def print_vars(var):
    print(var)

def return_vars():
    return 1
```

You can add your own plugin modules to extend further.

Test your plugin:
```
python3 plugins/foo_func.py
```

### YAML Syntax

```
    - plugin:
        - plugin_name: plugin.foo_func.print_vars
        - plugin_args:
               - "Hello plugin"
    - plugin:
        -plugin_name:  return_value = plugin.foo_func.return_vars
        - plugin_args:
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
