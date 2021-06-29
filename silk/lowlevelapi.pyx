# cython: language_level=3
from libc.string cimport memcpy

from cpython.mem cimport PyMem_Malloc

from .cimport api as api_
from .cimport control

cdef class SKP_Silk_TOC_struct:
    """src/SKP_Silk_SDK_API.h  struct SKP_Silk_TOC_struct"""
    cdef api_.SKP_Silk_TOC_struct _c_struct
    def __init__(self,
                 int framesInPacket,
                 int fs_kHz,
                 int inbandLBRR,
                 int corrupt,
                 list vadFlags,
                 list sigtypeFlags):
        """
        framesInPacket: Number of 20 ms frames in packet
        """
        # self._c_struct=api_.SKP_Silk_TOC_struct _c_struct
        self._c_struct.framesInPacket = framesInPacket
        self._c_struct.fs_kHz = fs_kHz
        self._c_struct.inbandLBRR = inbandLBRR
        self._c_struct.corrupt = corrupt
        for i, v in enumerate(vadFlags):
            self._c_struct.vadFlags[i] = v
        for i, v in enumerate(sigtypeFlags):
            self._c_struct.sigtypeFlags[i] = v
        # memcpy(self._c_struct.vadFlags, <int*>vadFlags, 5 * sizeof(int))
        # memcpy(self._c_struct.sigtypeFlags, <int*>sigtypeFlags, 5 * sizeof(int))

    @property
    def framesInPacket(self):
        return self._c_struct.framesInPacket

    @framesInPacket.setter
    def framesInPacket(self, value):
        self._c_struct.framesInPacket = value

    @property
    def fs_kHz(self):
        return self._c_struct.fs_kHz

    @fs_kHz.setter
    def fs_kHz(self, value):
        self._c_struct.fs_kHz = value

    @property
    def inbandLBRR(self):
        return self._c_struct.inbandLBRR

    @inbandLBRR.setter
    def inbandLBRR(self, value):
        self._c_struct.inbandLBRR = value

    @property
    def vadFlags(self):
        return self._c_struct.vadFlags

    @vadFlags.setter
    def vadFlags(self, value):
        self._c_struct.vadFlags = value

    @property
    def sigtypeFlags(self):
        return self._c_struct.sigtypeFlags

    @sigtypeFlags.setter
    def sigtypeFlags(self, value):
        self._c_struct.sigtypeFlags = value

def get_encoder_size():
    """Get size in bytes of the Silk encoder state"""
    cdef int decSizeBytes
    api_.SKP_Silk_SDK_Get_Encoder_Size(&decSizeBytes)
    return decSizeBytes

def init_encoder(
        bytes encState,
        int API_sampleRate,
        int maxInternalSampleRate,
        int packetSize,
        int bitRate,
        int packetLossPercentage,
        int complexity,
        bint useInBandFEC,
        bint useDTX):
    """Init or reset encoder"""
    cdef unsigned char*payload = <unsigned char*> PyMem_Malloc(len(encState))
    if not payload:
        raise MemoryError()
    memcpy(payload, <unsigned char*> encState, len(encState))
    cdef control.SKP_SILK_SDK_EncControlStruct  encStatus = {API_sampleRate, maxInternalSampleRate, packetSize, bitRate,
                                                             packetLossPercentage, complexity, useInBandFEC, useDTX}
    #
    return api_.SKP_Silk_SDK_InitEncoder(payload, &encStatus)
