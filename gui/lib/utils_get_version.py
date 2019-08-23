from robot.libraries.BuiltIn import BuiltIn
import subprocess

class utils_get_version(object):
    r"""
    Main class to obtain version information of installed packages.
    """
    def __init__(self):
        pass

    def get_software_version(self):
        r"""
        Method to get version of installed softwares.
        """
        BuiltIn().log_to_console("*"*20 + "SOFTWARE VERSIONS" + "*"*20)
        BuiltIn().log_to_console("LANGUAGES")
        BuiltIn().log_to_console("="*9)

        subprocess.call("python --version", shell=True)
        subprocess.call("robot --version", shell=True)

        BuiltIn().log_to_console("\nGUI TESTING")
        BuiltIn().log_to_console("="*11)

        subprocess.call("firefox --version", shell=True)
        try:
            import Selenium2Library
            result = Selenium2Library.__version__
            BuiltIn().log_to_console("Selenium2Library %s" %(result))

        except ImportError:
            BuiltIn().log_to_console("Selenium2Library: Not Installed")
        BuiltIn().log_to_console("\n" + "*"*20 + "SOFTWARE VERSIONS" + "*"*20)

if __name__== "__main__":
    obj = utils_get_version()
    obj.get_software_version()

