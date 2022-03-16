# cython: language_level=3
from libc.stdint cimport uint8_t,int8_t, int16_t, int32_t

cdef extern from "SKP_Silk_control.h" nogil:
    ctypedef struct SKP_SILK_SDK_EncControlStruct:
        int32_t API_sampleRate
        int32_t maxInternalSampleRate
        int32_t packetSize
        int32_t bitRate
        int32_t packetLossPercentage
        int32_t complexity
        int32_t useInBandFEC
        int32_t useDTX

cdef extern  from "SKP_Silk_SDK_API.h" nogil:
    int32_t SKP_Silk_SDK_Get_Encoder_Size(int32_t *encSizeBytes)
    int32_t SKP_Silk_SDK_InitEncoder(void *encState, SKP_SILK_SDK_EncControlStruct *encStatus)
    int32_t SKP_Silk_SDK_Encode(void *encState,
                                const SKP_SILK_SDK_EncControlStruct *encControl,
                                const int16_t *samplesIn,
                                int32_t nSamplesIn,
                                uint8_t *outData,
                                int16_t *nBytesOut)


cdef extern  from * nogil:
    """
    void swap_i16(int16_t *data)
    {
        int8_t *p = (int8_t *)data;
        int8_t tmp = p[0];
        p[0] = p[1];
        p[1] = tmp;
    }

    uint8_t is_le()
    {
        int16_t data = 0x1234;
        int8_t *p = (int8_t *)&data;
        if (p[0]<p[1])
        {
            return 0;
        }
        else
        {
            return 1;
        }

    }
    """
    void swap_i16(int16_t *data)
    uint8_t is_le()