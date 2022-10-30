from typing import Any, BinaryIO

class SilkError(Exception):
    def __init__(self, code) -> Any: ...

def encode(
    input: BinaryIO,
    output: BinaryIO,
    sample_rate: int,
    bit_rate: int,
    max_internal_sample_rate: int = 24000,
    packet_loss_percentage: int = 0,
    complexity: int = 2,
    use_inband_fec: bool = False,
    use_dtx: bool = False,
    tencent: bool = True,
) -> bytes: ...
def decode(
    input: BinaryIO,
    output: BinaryIO,
    sample_rate: int,
    frame_size: int = 0,
    frames_per_packet: int = 1,
    more_internal_decoder_frames: bool = False,
    in_band_fec_offset: int = 0,
    loss: bool = False,
) -> bytes: ...
