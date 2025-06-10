# my_tcc_module.pyx
# distutils: language=c

from libc.stdlib cimport malloc, free
from libc.string cimport strcpy, strlen
import sys
import ctypes # Used for type hints and potentially getting addresses

# Import the C declarations from the .pxd file
from my_tcc_module cimport *

cdef class TCC:
    """
    A Python wrapper for the Tiny C Compiler (libtcc).
    Allows compiling and running C code strings.
    """
    cdef TCCState* tcc_state

    def __cinit__(self):
        """Constructor: Initializes a new TCC state."""
        self.tcc_state = tcc_new()
        if self.tcc_state is NULL:
            raise MemoryError("Failed to create TCC state. Out of memory?")
        
        # Set output type to memory, so we can run it directly
        tcc_set_output_type(self.tcc_state, TCC_OUTPUT_MEMORY)

    def __dealloc__(self):
        """Destructor: Frees the TCC state when the object is destroyed."""
        if self.tcc_state is not NULL:
            tcc_delete(self.tcc_state)
            self.tcc_state = NULL # Prevent double-free

    def add_include_path(self, path: str):
        """Adds an include path for the C compiler."""
        tcc_add_include_path(self.tcc_state, path.encode('utf-8'))

    def add_library_path(self, path: str):
        """Adds a library path for the C compiler."""
        tcc_add_library_path(self.tcc_state, path.encode('utf-8'))

    def compile(self, c_code: str):
        """
        Compiles a C code string.
        Raises an exception if compilation fails.
        """
        c_code_bytes = c_code.encode('utf-8')
        # TCC prints errors to stderr by default.
        # For capturing stderr output, you'd need more advanced techniques
        # or have TCC compile to an executable and capture its output.
        if tcc_compile_string(self.tcc_state, c_code_bytes) == -1:
            raise Exception("TCC compilation failed. Check your terminal's stderr for details.")

    def add_symbol(self, name: str, address: object):
        """
        Adds a Python object's memory address as a symbol callable from compiled C code.
        This is for advanced use where you want C code to call back into Python-managed memory.
        `address` should typically be a memoryview or ctypes pointer to the data.
        """
        cdef void* addr_ptr
        if isinstance(address, ctypes._Pointer): # If it's a ctypes pointer
            addr_ptr = <void*>address
        elif isinstance(address, int): # If it's a raw integer address
            addr_ptr = <void*>address
        else:
            raise TypeError("address must be a ctypes pointer or integer address")

        if tcc_add_symbol(self.tcc_state, name.encode('utf-8'), addr_ptr) == -1:
            raise Exception(f"Failed to add symbol '{name}'.")


    def get_symbol(self, name: str):
        """
        Retrieves the memory address of a symbol from the compiled C code.
        Returns an integer address (Python int).
        """
        cdef void* symbol_ptr = tcc_get_symbol(self.tcc_state, name.encode('utf-8'))
        if symbol_ptr is NULL:
            return None
        return <size_t>symbol_ptr # Return as Python integer

    def run(self, argv: list = None):
        """
        Relocates the compiled code and runs the main function.
        Returns the exit code of the C program.
        """
        if tcc_relocate(self.tcc_state, NULL) == -1: # NULL for automatic relocation
            raise Exception("TCC relocation failed. Check stderr for details.")

        cdef int c_argc = 0
        cdef char** c_argv = NULL

        if argv:
            c_argc = len(argv)
            # Allocate memory for char* array
            c_argv = <char**>malloc(c_argc * sizeof(char*))
            if c_argv is NULL:
                raise MemoryError("Failed to allocate memory for argv.")
            
            # Copy Python strings to C char*
            for i in range(c_argc):
                arg_bytes = argv[i].encode('utf-8')
                c_argv[i] = <char*>malloc(strlen(arg_bytes) + 1)
                if c_argv[i] is NULL:
                    # Clean up already allocated memory before raising error
                    for j in range(i):
                        free(c_argv[j])
                    free(c_argv)
                    raise MemoryError("Failed to allocate memory for argv string.")
                strcpy(c_argv[i], arg_bytes)
        
        try:
            exit_code = tcc_run(self.tcc_state, c_argc, c_argv)
        finally:
            # Free allocated memory for c_argv and its elements
            if c_argv is not NULL:
                for i in range(c_argc):
                    if c_argv[i] is not NULL:
                        free(c_argv[i])
                free(c_argv)

        return exit_code

    def compile_and_run(self, c_code: str, argv: list = None):
        """Convenience method to compile and then run."""
        self.compile(c_code)
        return self.run(argv)
