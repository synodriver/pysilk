import struct
from typing import IO

from pysilk.backends.cffi._silk import ffi, lib



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


def i16_to_bytes(data: int) -> bytes:
    return struct.pack("=h", data)


def bytes_to_i16(data: bytes) -> int:
    return struct.unpack("=h", data)[0]


def write_i16_le(output: IO, data: int):
    if lib.SHOULD_SWAP():
        data = lib.swap_i16(data)
    output.write(i16_to_bytes(data))


def read_i16_le(input: IO) -> int:
    chunk = input.read(2)  # type: bytes
    data: int = bytes_to_i16(chunk)
    if lib.SHOULD_SWAP():
        data = lib.swap_i16(data)
    return data


def check_file(file) -> bool:
    if hasattr(file, "read") and hasattr(file, "write"):
        return True
    return False


def encode(
    input: IO,
    output: IO,
    sample_rate: int,
    bit_rate: int,
    max_internal_sample_rate: int = 24000,
    packet_loss_percentage: int = 0,
    complexity: int = 2,
    use_inband_fec: bool = False,
    use_dtx: bool = False,
    tencent: bool = True,
) -> None:
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
    if not check_file(input):
        raise TypeError(
            "input except a file-like object, got %s" % type(input).__name__
        )
    if not check_file(output):
        raise TypeError(
            "output except a file-like object, got %s" % type(output).__name__
        )

    enc_control = ffi.new("SKP_SILK_SDK_EncControlStruct *")
    enc_control.API_sampleRate = sample_rate
    enc_control.maxInternalSampleRate = max_internal_sample_rate
    enc_control.packetSize = (20 * sample_rate) // 1000
    enc_control.bitRate = bit_rate
    enc_control.packetLossPercentage = packet_loss_percentage
    enc_control.complexity = complexity
    enc_control.useInBandFEC = use_inband_fec
    enc_control.useDTX = use_dtx

    enc_status = ffi.new("SKP_SILK_SDK_EncControlStruct *")
    enc_status.API_sampleRate = 0
    enc_status.maxInternalSampleRate = 0
    enc_status.packetSize = 0
    enc_status.bitRate = 0
    enc_status.packetLossPercentage = 0
    enc_status.complexity = 0
    enc_status.useInBandFEC = 0
    enc_status.useDTX = 0

    enc_size_bytes = ffi.new("int32_t *", 0)
    code: int = lib.SKP_Silk_SDK_Get_Encoder_Size(enc_size_bytes)
    if code != 0:
        raise SilkError(code)
    enc = lib.PyMem_Malloc(enc_size_bytes[0])
    if enc == ffi.NULL:
        raise MemoryError
    code = lib.SKP_Silk_SDK_InitEncoder(enc, enc_status)
    if code != 0:
        lib.PyMem_Free(enc)
        raise SilkError(code)
    frame_size: int = sample_rate // 1000 * 40
    if tencent:
        output.write(b"\x02#!SILK_V3")
    else:
        output.write(b"#!SILK_V3")
    n_bytes = ffi.new("int16_t *", 1250)
    payload = ffi.new("uint8_t[1250]")
    try:
        while True:
            chunk = input.read(frame_size)  # type: bytes
            if not isinstance(chunk, bytes):
                raise TypeError(
                    f"input must be a file-like rb object, got {type(input).__name__}"
                )

            n_bytes[0] = 1250
            if len(chunk) < frame_size:
                break
            c_chunk = ffi.from_buffer("int16_t[]", chunk)
            code = lib.SKP_Silk_SDK_Encode(
                enc, enc_control, c_chunk, len(chunk) // 2, payload, n_bytes
            )
            if code != 0:
                raise SilkError(code)

            write_i16_le(output, n_bytes[0])
            output.write(ffi.unpack(ffi.cast("char *", payload), n_bytes[0]))
    finally:
        lib.PyMem_Free(enc)


def decode(
    input: IO,
    output: IO,
    sample_rate: int,
    frame_size: int = 0,
    frames_per_packet: int = 1,
    more_internal_decoder_frames: bool = False,
    in_band_fec_offset: int = 0,
    loss: bool = False,
) -> None:
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
    if not check_file(input):
        raise TypeError(
            "input except a file-like object, got %s" % type(input).__name__
        )
    if not check_file(output):
        raise TypeError(
            "output except a file-like object, got %s" % type(output).__name__
        )

    chunk = input.read(9)  # type: bytes
    if not isinstance(chunk, bytes):
        raise TypeError(
            f"input must be a file-like rb object, got {type(input).__name__}"
        )
    if chunk != b"#!SILK_V3" and chunk != b"\x02#!SILK_V":
        raise SilkError("INVALID")
    elif chunk == b"\x02#!SILK_V":
        chunk = input.read(1)
        if chunk != b"3":
            raise SilkError("INVALID")

    dec_control = ffi.new("SKP_SILK_SDK_DecControlStruct *")
    dec_control.API_sampleRate = sample_rate
    dec_control.frameSize = frame_size
    dec_control.framesPerPacket = frames_per_packet
    dec_control.moreInternalDecoderFrames = more_internal_decoder_frames
    dec_control.inBandFECOffset = in_band_fec_offset
    dec_size = ffi.new("int32_t *", 0)
    code: int = lib.SKP_Silk_SDK_Get_Decoder_Size(dec_size)
    if code != 0:
        raise SilkError(code)
    dec = lib.PyMem_Malloc(dec_size[0])
    if dec == ffi.NULL:
        raise MemoryError
    code = lib.SKP_Silk_SDK_InitDecoder(dec)
    if code != 0:
        lib.PyMem_Free(dec)
        raise SilkError(code)
    frame_size = sample_rate // 1000 * 40
    # cdef uint8_t buf[frame_size]  # otherwise need malloc
    buf = lib.PyMem_Malloc(frame_size)
    if buf == ffi.NULL:
        lib.PyMem_Free(dec)
        raise MemoryError
    n_bytes = ffi.new("int16_t *")
    try:
        while True:
            chunk = input.read(2)
            if len(chunk) < 2:
                break
            n_bytes[0] = bytes_to_i16(chunk)
            if lib.SHOULD_SWAP():
                n_bytes[0] = lib.swap_i16(n_bytes[0])
            if n_bytes[0] > frame_size:
                raise SilkError("INVALID")
            chunk = input.read(n_bytes[0])  # type: bytes
            if len(chunk) < n_bytes[0]:  # not enough data
                raise SilkError("INVALID")
            c_chunk = ffi.from_buffer("uint8_t[]", chunk)
            code = lib.SKP_Silk_SDK_Decode(
                dec,
                dec_control,
                loss,
                c_chunk,
                n_bytes[0],
                ffi.cast("int16_t *", buf),
                n_bytes,
            )
            if code != 0:
                raise SilkError(code)
            output.write(ffi.unpack(ffi.cast("char*", buf), n_bytes[0] * 2))
    finally:
        lib.PyMem_Free(buf)
        lib.PyMem_Free(dec)
