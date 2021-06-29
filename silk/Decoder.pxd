# cython: language_level=3
cdef extern from "Decoder.h" nogil:
    cdef unsigned long GetHighResolutionTime()