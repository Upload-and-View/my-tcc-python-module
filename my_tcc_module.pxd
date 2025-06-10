# my_tcc_module.pxd
# Declare the C functions from libtcc. These should match tcc.h
cdef extern from "tcc.h":
    ctypedef void TCCState "TCCState" # Alias TCCState to void* for Cython

    TCCState* tcc_new()
    void tcc_delete(TCCState* s)
    int tcc_set_output_type(TCCState* s, int output_type)
    void tcc_add_include_path(TCCState* s, const char* path)
    void tcc_add_library_path(TCCState* s, const char* path)
    int tcc_add_sysinclude_path(TCCState* s, const char* path)
    int tcc_compile_string(TCCState* s, const char* buf)
    int tcc_relocate(TCCState* s, void* ptr)
    int tcc_run(TCCState* s, int argc, char** argv)
    void* tcc_get_symbol(TCCState* s, const char* name)
    int tcc_add_symbol(TCCState* s, const char* name, const void* val)

    # Some important TCC constants. Check tcc.h for exact values/enums.
    int TCC_OUTPUT_MEMORY # Value for outputting to memory
    # int TCC_OUTPUT_EXE # For creating executables
    # int TCC_RELOCATE_AUTO # For automatic relocation in tcc_relocate
cdef extern from *:
    """
    #ifdef malloc
    #undef malloc
    #endif
    #ifdef free
    #undef free
    #endif
    """
