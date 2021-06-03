from setuptools import setup
setup(
    name='ffdc',
    version='0.1',
    description=("A standalone utility to generate and retrieves First failure data capture (FFDC)"),
    py_modules=['install'],
    install_requires=[
        'click',
        'PyYAML',
        'paramiko',
    ],
    entry_points={
        'console_scripts': ['collectFFDC=commands.install_cmd:main']
    }
)