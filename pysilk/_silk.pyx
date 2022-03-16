# cython: language_level=3
# cython: cdivision=True
from libc.stdint cimport uint8_t, int16_t, int32_t
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython.bytes cimport PyBytes_Check, PyBytes_AsString

from pysilk.silk cimport is_le, swap_i16
from pysilk.silk cimport SKP_SILK_SDK_EncControlStruct, SKP_Silk_SDK_Get_Encoder_Size
from pysilk.silk cimport SKP_Silk_SDK_InitEncoder, SKP_Silk_SDK_Encode


class SilkError(Exception):
    def __init__(self, code):
        self.code = code

    def __str__(self):
        if self.code == -1:
            return "ENC_INPUT_INVALID_NO_OF_SAMPLES"
        elif self.code == -2:
            return "ENC_FS_NOT_SUPPORTED"
        elif self.code == -3:
            return "ENC_PACKET_SIZE_NOT_SUPPORTED"
        elif self.code == -4:
            return "ENC_PAYLOAD_BUF_TOO_SHORT"
        elif self.code == -5:
            return "ENC_INVALID_LOSS_RATE"
        elif self.code == -6:
            return "ENC_INVALID_COMPLEXITY_SETTING"
        elif self.code == -7:
            return "ENC_INVALID_INBAND_FEC_SETTING"
        elif self.code == -8:
            return "ENC_INVALID_DTX_SETTING"
        elif self.code == -9:
            return "ENC_INTERNAL_ERROR"
        elif self.code == -10:
            return "DEC_INVALID_SAMPLING_FREQUENCY"
        elif self.code == -11:
            return "DEC_PAYLOAD_TOO_LARGE"
        elif self.code == -12:
            return "DEC_PAYLOAD_ERROR"
        else:
            return "Other error"


cdef bytes i16_to_bytes(int16_t data):
    cdef  uint8_t * p = <uint8_t *> &data
    cdef uint8_t buf[2]
    buf[0] = p[0]
    buf[1] = p[1]
    return <bytes> buf[:2]

cdef write_i16_le(object output, int16_t data, uint8_t le):
    if not le:
        swap_i16(&data)
    output.write(i16_to_bytes(data))

cpdef encode(object input,
             object output,
             int32_t sample_rate,
             int32_t bit_rate,
             int32_t max_internal_sample_rate = 24000,
             int32_t packet_loss_percentage = 0,
             int32_t complexity = 2,
             bint use_inband_fec = False,
             bint use_dtx = False,
             bint tencent = True) with gil:
    """encode(input: IO, output: IO, sample_rate: int, bit_rate: int, packet_loss_percentage: int = 0, complexity: int = 2, use_inband_fec: bool = False, use_dtx: bool = False, tencent: bool = True) -> bytes
    
    encode pcm to silk
    :param input: BytesIO or an openfile with "rb" mode
    :param output: BytesIO or an openfile with "wb" mode
    :param sample_rate: 
    :param bit_rate: 
    :param packet_loss_percentage: 
    :param complexity: 
    :param use_inband_fec: 
    :param use_dtx: 
    :param tencent: Tencent's special tag 
    :return: None
    """
    cdef SKP_SILK_SDK_EncControlStruct enc_control
    enc_control.API_sampleRate = sample_rate
    enc_control.maxInternalSampleRate = max_internal_sample_rate
    enc_control.packetSize = (20 * sample_rate) / 1000
    enc_control.bitRate = bit_rate
    enc_control.packetLossPercentage = packet_loss_percentage
    enc_control.complexity = complexity
    enc_control.useInBandFEC = use_inband_fec
    enc_control.useDTX = use_dtx

    cdef  SKP_SILK_SDK_EncControlStruct enc_status
    enc_status.API_sampleRate = 0
    enc_status.maxInternalSampleRate = 0
    enc_status.packetSize = 0
    enc_status.bitRate = 0
    enc_status.packetLossPercentage = 0
    enc_status.complexity = 0
    enc_status.useInBandFEC = 0
    enc_status.useDTX = 0
    cdef uint8_t le = is_le()  # is little endian

    cdef int32_t enc_size_bytes = 0
    cdef int32_t code = SKP_Silk_SDK_Get_Encoder_Size(&enc_size_bytes)
    if code != 0:
        raise SilkError(code)
    cdef void * enc = PyMem_Malloc(<size_t> enc_size_bytes)
    if enc == NULL:
        raise MemoryError
    code = SKP_Silk_SDK_InitEncoder(enc, &enc_status)
    if code != 0:
        PyMem_Free(enc)
        raise SilkError(code)
    cdef int32_t frame_size = sample_rate / 1000 * 40
    if tencent:
        output.write(b"\x02#!SILK_V3")
    else:
        output.write(b"#!SILK_V3")
    cdef int16_t n_bytes = 1250
    cdef uint8_t payload[1250]
    while True:
        chunk = input.read(frame_size)  # type: bytes
        if not PyBytes_Check(chunk):
            PyMem_Free(enc)
            raise TypeError(f"input must be a file-like rb object, got {type(input).__name__}")

        n_bytes = 1250
        if <int32_t> len(chunk) < frame_size:
            break
        code = SKP_Silk_SDK_Encode(enc,
                                   &enc_control,
                                   <int16_t *> PyBytes_AsString(chunk),
                                   <int32_t> (len(chunk) / 2),
                                   payload,
                                   &n_bytes)
        if code != 0:
            PyMem_Free(enc)
            raise SilkError(code)

        write_i16_le(output, n_bytes, le)
        output.write(<bytes> payload[0:n_bytes])
    PyMem_Free(enc)