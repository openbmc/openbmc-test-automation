from setuptools import setup
setup(
    name='ffdc',
    version='0.1',
    description=("A standalone script to collect logs from a given system."),
    py_modules=['install'],
    install_requires=[
        'click',
        'PyYAML',
        'paramiko',
        'redfishtool'
    ],
    entry_points={
        'console_scripts': ['collectFFDC=commands.install_cmd:main']
    }
)
