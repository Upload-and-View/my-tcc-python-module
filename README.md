# My TCC Python Module

A Python module that wraps the Tiny C Compiler (TCC) for dynamic C code compilation and execution.

## Features
- Compile C code strings dynamically.
- Run compiled C code with arguments.
- Add symbols (e.g., Python object addresses) for C code callbacks (if you implemented this).

## Prerequisites

Before building this module, you need to have the Tiny C Compiler (TCC) installed on your system.

### Installing Tiny C Compiler (TCC)

1.  **Download TCC:**
    You can get the source from the official TCC website or a mirror. For example, `tcc-0.9.27.tar.bz2`.

2.  **Extract and Build:**
    ```bash
    tar -xf tcc-0.9.27.tar.bz2
    cd tcc-0.9.27
    ./configure --prefix=/usr/local # or adjust to your preferred installation path
    make
    sudo make install
    sudo ldconfig # Update shared library cache
    ```
    **Important Note:** Even if `sudo make install` completes, sometimes `tcc.h` and `libtcc.a` might not end up in the standard `/usr/local/include` and `/usr/local/lib` directories. You might need to manually verify their location.

    * To find `tcc.h`:
        ```bash
        find /usr/local/include -name "tcc.h" # or search in your TCC source directory like ~/Downloads/tcc-0.9.27
        ```
    * To find `libtcc.a` (static library):
        ```bash
        find /usr/local/lib -name "libtcc.a" # or search in your TCC source directory
        ```

## Building the Python Module

1.  **Navigate to the project directory:**
    ```bash
    cd /path/to/your/c4python # or ~/Desktop/c4python
    ```

2.  **Create and activate a Python virtual environment (recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install Cython setuptools
    ```

3.  **Configure `setup.py` and `my_tcc_module.pxd`:**

    * **`setup.py`:**
        * Ensure `tcc_include_dirs` points to the *actual* directory containing `tcc.h`. For example:
            ```python
            tcc_include_dirs = ['/home/muser/Desktop/c4python/tcc-0.9.27'] # Adjust this path!
            ```
        * Ensure you are linking against the **static library** (`libtcc.a`) to avoid `undefined symbol` errors for `use_tcc_malloc`/`use_tcc_free`. The `extra_link_args` should directly point to the `.a` file:
            ```python
            extra_link_args=['/usr/local/lib/libtcc.a'], # Adjust this path if libtcc.a is elsewhere!
            ```
        * Make sure the `libraries` parameter is **commented out or removed**.

    * **`my_tcc_module.pyx`:**
        * **CRITICAL:** Ensure the line `# distutils: libraries=tcc` (if it ever existed) is **completely removed** from this file. It conflicts with `setup.py`.

    * **`my_tcc_module.pxd`:**
        * Add the following block to the **very end** of the file to prevent TCC's internal `malloc`/`free` macros from interfering with your module's use of standard C library functions:
            ```cython
            cdef extern from *:
                """
                #ifdef malloc
                #undef malloc
                #endif
                #ifdef free
                #undef free
                #endif
                """
            ```

4.  **Clean previous builds (if any):**
    ```bash
    rm -rf build/ my_tcc_module.c my_tcc_module*.so
    ```

5.  **Build the Cython extension:**
    ```bash
    python setup.py build_ext --inplace -v
    ```
    If successful, you should see a `my_tcc_module.cpython-X.Y-Z.so` file created in your project directory.

## Usage

Here's a quick example of how to use the `TCC` wrapper in Python:

```python
import my_tcc_module

try:
    tcc = my_tcc_module.TCC()

    # You can add include/library paths if your C code needs them
    # tcc.add_include_path("/path/to/your/custom/includes")
    # tcc.add_library_path("/path/to/your/custom/libs")

    c_code = """
    #include <stdio.h>

    int my_c_function(int a, int b) {
        printf("Hello from C! Sum is: %d\\n", a + b);
        return a + b;
    }

    int main(int argc, char** argv) {
        if (argc > 1) {
            printf("Args: %s\\n", argv[1]);
        }
        return my_c_function(10, 32);
    }
    """

    tcc.compile(c_code)
    
    # Run without arguments
    print(f"Result (no args): {tcc.run()}")

    # Run with arguments
    print(f"Result (with args): {tcc.run(['program_name', 'arg1', 'arg2'])}")

    # Example: getting a symbol address (for advanced use)
    func_ptr = tcc.get_symbol("my_c_function")
    if func_ptr:
        print(f"Address of my_c_function: {hex(func_ptr)}")
    else:
        print("my_c_function symbol not found.")

except Exception as e:
    print(f"An error occurred: {e}")
