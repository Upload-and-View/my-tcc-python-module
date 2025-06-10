# setup.py
import sys
from setuptools import setup, Extension
from Cython.Build import cythonize

# Determine the correct library name and path for different OS
# You might need to adjust these paths based on your TCC installation
# If libtcc is installed in a standard system path (e.g., /usr/local/lib),
# you might not need to specify library_dirs or include_dirs.
# However, it's safer to include them if you know the exact path.
if sys.platform == 'win32':
    tcc_library_name = 'tcc' # For libtcc.dll
    tcc_library_dirs = [] # E.g., [r'C:\path\to\tcc\lib']
    tcc_include_dirs = [] # E.g., [r'C:\path\to\tcc\include']
elif sys.platform == 'darwin': # macOS
    tcc_library_name = 'tcc' # For libtcc.dylib
    tcc_library_dirs = ['/usr/local/lib'] # Default install path
    tcc_include_dirs = ['/usr/local/include'] # Default install path for tcc.h
elif sys.platform.startswith('linux'):
    tcc_library_name = 'tcc' # For libtcc.so
    tcc_library_dirs = ['/usr/local/lib'] # Default install path
    tcc_include_dirs = ['/home/muser/Desktop/c4pythonReady/tcc-0.9.27'] # Default install path for tcc.h
else:
    raise OSError("Unsupported operating system")

# Define your extension module
# Define your extension module
extensions = [
    Extension(
        "my_tcc_module",                     # Name of the Python module
        ["my_tcc_module.pyx"],               # Source files (Cython and C)
        # libraries=[tcc_library_name],      # <--- THIS LINE SHOULD BE REMOVED
        library_dirs=tcc_library_dirs,       # Where to find libtcc.so/dll/dylib
        include_dirs=tcc_include_dirs,       # Where to find tcc.h
        # extra_compile_args=["-O3"],        # Optional: compiler optimizations
        extra_link_args=['/usr/local/lib/libtcc.a'], # <--- CHANGE THIS LIEN
        language="c"                         # Specify C language
    )
]

setup(
    name="my_tcc_module",
    version="0.1.0",
    description="A Python module to dynamically compile and run C code using libtcc.",
    ext_modules=cythonize(extensions, compiler_directives={'language_level': "3"}),
    zip_safe=False, # Important for C extensions, prevents issues
)
