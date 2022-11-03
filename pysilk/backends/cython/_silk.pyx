# cython: language_level=3
# cython: cdivision=True
from cpython.bytes cimport (PyBytes_AS_STRING, PyBytes_Check,
                            PyBytes_FromStringAndSize, PyBytes_Size)
from cpython.mem cimport PyMem_Free, PyMem_Malloc
from cpython.object cimport PyObject, PyObject_HasAttrString
from libc.stdint cimport int16_t, int32_t, uint8_t

from pysilk.backends.cython.silk cimport (SHOULD_SWAP,
                                          SKP_SILK_SDK_DecControlStruct,
                                          SKP_Silk_SDK_Decode,
                                          SKP_SILK_SDK_EncControlStruct,
                                          SKP_Silk_SDK_Encode,
                                          SKP_Silk_SDK_Get_Decoder_Size,
                                          SKP_Silk_SDK_Get_Encoder_Size,
                                          SKP_Silk_SDK_InitDecoder,
                                          SKP_Silk_SDK_InitEncoder, swap_i16)


class SilkError(Exception):
    def __init__(self, code):
        self.code = code

    def __str__(self):
        if isinstance(self.code, int):
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
        else:
            return str(self.code)


cdef inline bytes i16_to_bytes(int16_t data):
    cdef:
        uint8_t * p = <uint8_t *> &data
        bytes bt = PyBytes_FromStringAndSize(NULL, 2)
    if <PyObject*>bt == NULL:
        raise MemoryError
    cdef uint8_t* buf = <uint8_t*>PyBytes_AS_STRING(bt)
    buf[0] = p[0]
    buf[1] = p[1]
    return bt

cdef inline int16_t bytes_to_i16(bytes data):
    cdef int16_t buf = 0
    cdef uint8_t *p = <uint8_t *> &buf
    p[0] = <uint8_t> data[0]
    p[1] = <uint8_t> data[1]
    return buf

cdef inline void write_i16_le(object output, int16_t data):
    if SHOULD_SWAP:
        data = swap_i16(data)
    output.write(i16_to_bytes(data))

cdef inline int16_t read_i16_le(object input):
    chunk = input.read(2)  # type: bytes
    cdef int16_t data = bytes_to_i16(chunk)
    if SHOULD_SWAP:
        data = swap_i16(data)
    return data

cdef inline uint8_t PyFile_Check(object file):
    if PyObject_HasAttrString(file, "read") and PyObject_HasAttrString(file, "write"):  # should we check seek method?
        return 1
    return 0

def encode(object input,
            object output,
            int32_t sample_rate,
            int32_t bit_rate,
            int32_t max_internal_sample_rate = 24000,
            int32_t packet_loss_percentage = 0,
            int32_t complexity = 2,
            bint use_inband_fec = False,
            bint use_dtx = False,
            bint tencent = True):
    """encode(input: BinaryIO, output: BinaryIO, sample_rate: int, bit_rate: int, max_internal_sample_rate: int = 24000, packet_loss_percentage: int = 0, complexity: int = 2, use_inband_fec: bool = False, use_dtx: bool = False, tencent: bool = True) -> bytes
    
    encode pcm to silk
    :param input: BytesIO or an openfile with "rb" mode
    :param output: BytesIO or an openfile with "wb" mode
    :param sample_rate: 
    :param bit_rate: 
    :param max_internal_sample_rate:
    :param packet_loss_percentage: 
    :param complexity: 
    :param use_inband_fec: 
    :param use_dtx: 
    :param tencent: Tencent's special tag 
    :return: None
    """
    if not PyFile_Check(input):
        raise TypeError("input except a file-like object, got %s" % type(input).__name__)
    if not PyFile_Check(output):
        raise TypeError("output except a file-like object, got %s" % type(output).__name__)

    cdef SKP_SILK_SDK_EncControlStruct enc_control
    enc_control.API_sampleRate = sample_rate
    enc_control.maxInternalSampleRate = max_internal_sample_rate
    enc_control.packetSize = (20 * sample_rate) / 1000
    enc_control.bitRate = bit_rate
    enc_control.packetLossPercentage = packet_loss_percentage
    enc_control.complexity = complexity
    enc_control.useInBandFEC = use_inband_fec
    enc_control.useDTX = use_dtx

    cdef SKP_SILK_SDK_EncControlStruct enc_status
    enc_status.API_sampleRate = 0
    enc_status.maxInternalSampleRate = 0
    enc_status.packetSize = 0
    enc_status.bitRate = 0
    enc_status.packetLossPercentage = 0
    enc_status.complexity = 0
    enc_status.useInBandFEC = 0
    enc_status.useDTX = 0

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
    cdef int16_t* chunk_ptr
    cdef int32_t chunk_size
    try:
        while True:
            chunk = input.read(frame_size)  # type: bytes
            if not PyBytes_Check(chunk):
                raise TypeError(f"input must be a file-like rb object, got {type(input).__name__}")

            n_bytes = 1250
            if <int32_t> PyBytes_Size(chunk) < frame_size:
                break
            chunk_ptr = <int16_t *> PyBytes_AS_STRING(chunk)
            chunk_size = <int32_t> (PyBytes_Size(chunk) / 2)
            with nogil:
                code = SKP_Silk_SDK_Encode(enc,
                                        &enc_control,
                                        chunk_ptr,
                                        chunk_size,
                                        payload,
                                        &n_bytes)
            if code != 0:
                raise SilkError(code)

            write_i16_le(output, n_bytes)
            output.write(<bytes> payload[0:n_bytes])
    finally:
        PyMem_Free(enc)

def decode(object input,
            object output,
            int32_t sample_rate,
            int32_t frame_size=0,
            int32_t frames_per_packet=1,
            bint more_internal_decoder_frames=False,
            int32_t in_band_fec_offset=0,
            bint loss=False):
    """decode(input: BinaryIO, output: BinaryIO, sample_rate: int, frame_size: int = 0, frames_per_packet: int = 1, more_internal_decoder_frames: bool = False, in_band_fec_offset: int = 0, loss: bool = False) -> bytes
    
    decode silk to pcm
    :param input: 
    :param output: 
    :param sample_rate: 
    :param frame_size: 
    :param frames_per_packet: 
    :param more_internal_decoder_frames: 
    :param in_band_fec_offset: 
    :param loss: 
    :return: 
    """
    if not PyFile_Check(input):
        raise TypeError("input except a file-like object, got %s" % type(input).__name__)
    if not PyFile_Check(output):
        raise TypeError("output except a file-like object, got %s" % type(output).__name__)

    chunk = input.read(9)  # type: bytes
    if not PyBytes_Check(chunk):
        raise TypeError(f"input must be a file-like rb object, got {type(input).__name__}")
    if chunk != b"#!SILK_V3" and chunk != b"\x02#!SILK_V":
        raise SilkError("INVALID")
    elif chunk == b"\x02#!SILK_V":
        chunk = input.read(1)
        if chunk != b"3":
            raise SilkError("INVALID")

    cdef SKP_SILK_SDK_DecControlStruct dec_control
    dec_control.API_sampleRate = sample_rate
    dec_control.frameSize = frame_size
    dec_control.framesPerPacket = frames_per_packet
    dec_control.moreInternalDecoderFrames = more_internal_decoder_frames
    dec_control.inBandFECOffset = in_band_fec_offset
    cdef int32_t dec_size = 0
    cdef int32_t code = SKP_Silk_SDK_Get_Decoder_Size(&dec_size)
    if code != 0:
        raise SilkError(code)
    cdef void *dec = PyMem_Malloc(dec_size)
    if dec == NULL:
        raise MemoryError
    code = SKP_Silk_SDK_InitDecoder(dec)
    if code != 0:
        PyMem_Free(dec)
        raise SilkError(code)
    frame_size = sample_rate / 1000 * 40
    # cdef uint8_t buf[frame_size]  # otherwise need malloc
    cdef uint8_t *buf = <uint8_t *> PyMem_Malloc(frame_size)
    if buf == NULL:
        PyMem_Free(dec)
        raise MemoryError
    cdef int16_t n_bytes
    cdef const uint8_t *chunk_ptr
    try:
        while True:
            chunk = input.read(2)
            if PyBytes_Size(chunk) < 2:
                break
            n_bytes = bytes_to_i16(chunk)
            if SHOULD_SWAP:
                n_bytes = swap_i16(n_bytes)
            if n_bytes > <int16_t> frame_size:
                raise SilkError("INVALID")
            chunk = input.read(n_bytes)  # type: bytes
            if <int16_t> PyBytes_Size(chunk) < n_bytes:  # not enough data
                raise SilkError("INVALID")
            chunk_ptr = <const uint8_t *> PyBytes_AS_STRING(chunk)
            with nogil:
                code = SKP_Silk_SDK_Decode(dec,
                                        &dec_control,
                                        loss,
                                        chunk_ptr,
                                        <const int32_t> n_bytes,
                                        <int16_t *> buf,
                                        &n_bytes)
            if code != 0:
                raise SilkError(code)
            output.write(<bytes> buf[:n_bytes * 2])
    finally:
        PyMem_Free(buf)
        PyMem_Free(dec)
